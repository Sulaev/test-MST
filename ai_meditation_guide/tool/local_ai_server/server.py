import os
import shutil
import subprocess
import uuid
from pathlib import Path

import requests
from fastapi import FastAPI
from fastapi import HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel

app = FastAPI()

ROOT = Path(__file__).resolve().parent
FILES = ROOT / "files"
FILES.mkdir(exist_ok=True)


class GenerateRequest(BaseModel):
    goal: str
    durationMinutes: int
    voiceStyle: str
    backgroundSound: str


class BackgroundRequest(BaseModel):
    goal: str
    backgroundSound: str


def _ollama_generate_text(prompt: str) -> str:
    """
    Free/open-source LLM via local Ollama.
    Install Ollama and pull a model, e.g.:
      ollama pull llama3.2:3b
    """
    ollama_url = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434/api/generate")
    model = os.environ.get("OLLAMA_MODEL", "llama3.2:3b")
    r = requests.post(
        ollama_url,
        json={"model": model, "prompt": prompt, "stream": False},
        timeout=120,
    )
    r.raise_for_status()
    data = r.json()
    return (data.get("response") or "").strip()

def _musicgen_available() -> bool:
    try:
        import audiocraft  # noqa: F401
        import torch  # noqa: F401
        return True
    except Exception:
        return False


def _musicgen_prompt(background_sound: str, goal: str) -> str:
    bg = (background_sound or "").lower()
    base = "calm ambient background music, seamless loop, no vocals"
    if bg == "rain":
        base = "calm ambient background with gentle rain, seamless loop, no vocals"
    elif bg == "nature":
        base = "calm ambient background with soft forest nature sounds, seamless loop, no vocals"
    elif bg == "ambient":
        base = "soft ambient pads, warm reverb, seamless loop, no vocals"

    # Nudge style by goal
    g = (goal or "").lower()
    if "sleep" in g:
        base += ", sleepy, slow tempo"
    elif "focus" in g:
        base += ", minimal, steady"
    elif "stress" in g or "anxiety" in g:
        base += ", soothing, very gentle"
    return base


def _musicgen_generate_wav(background_sound: str, goal: str, seconds: int) -> str:
    """
    Neural music via Meta AudioCraft MusicGen.

    Enable by installing optional deps and setting env:
      ENABLE_MUSICGEN=true

    Optional env:
      MUSICGEN_MODEL=facebook/musicgen-small
      MUSICGEN_DURATION_SECONDS=30
    """
    if not _musicgen_available():
        raise RuntimeError("MusicGen deps are not installed (audiocraft/torch).")

    from audiocraft.models import MusicGen
    from audiocraft.data.audio import audio_write

    model_name = os.environ.get("MUSICGEN_MODEL", "facebook/musicgen-small")
    model = MusicGen.get_pretrained(model_name)
    model.set_generation_params(duration=float(seconds))
    prompt = _musicgen_prompt(background_sound, goal)

    wav = model.generate([prompt])[0]  # shape: [channels, samples]
    name = f"bg_{uuid.uuid4().hex}.wav"
    out_path = FILES / name

    # audiocraft audio_write expects a path *without* extension
    prefix = str(out_path).removesuffix(".wav")
    audio_write(
        prefix,
        wav.cpu(),
        model.sample_rate,
        strategy="loudness",
        loudness_compressor=True,
    )
    return name


def _piper_available() -> bool:
    return shutil.which("piper") is not None


def _piper_model_for_style(voice_style: str) -> str | None:
    """
    Configure via env:
      PIPER_MODEL_SOFT=/path/to/model.onnx
      PIPER_MODEL_NEUTRAL=...
      PIPER_MODEL_DEEP=...
    Or a default:
      PIPER_MODEL=/path/to/model.onnx
    """
    style = (voice_style or "").lower()
    if style == "soft":
        return os.environ.get("PIPER_MODEL_SOFT") or os.environ.get("PIPER_MODEL")
    if style == "neutral":
        return os.environ.get("PIPER_MODEL_NEUTRAL") or os.environ.get("PIPER_MODEL")
    if style == "deep":
        return os.environ.get("PIPER_MODEL_DEEP") or os.environ.get("PIPER_MODEL")
    return os.environ.get("PIPER_MODEL")


def _piper_tts_wav(text: str, voice_style: str) -> str:
    """
    Neural TTS via Piper CLI.
    Returns file name (served by /files/{name}).
    """
    if not _piper_available():
        raise RuntimeError("piper not found in PATH")
    model = _piper_model_for_style(voice_style)
    if not model:
        raise RuntimeError("PIPER_MODEL is not configured")
    if not Path(model).exists():
        raise RuntimeError(f"PIPER model not found: {model}")

    name = f"voice_{uuid.uuid4().hex}.wav"
    out_path = FILES / name
    subprocess.run(
        ["piper", "--model", model, "--output_file", str(out_path)],
        input=text,
        text=True,
        check=True,
    )
    return name


@app.get("/health")
def health():
    return {
        "ollama_url": os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434/api/generate"),
        "ollama_model": os.environ.get("OLLAMA_MODEL", "llama3.2:3b"),
        "piper_available": _piper_available(),
        "piper_model_configured": bool(os.environ.get("PIPER_MODEL")),
        "musicgen_available": _musicgen_available(),
        "musicgen_enabled": (os.environ.get("ENABLE_MUSICGEN", "false").lower() == "true"),
        "musicgen_model": os.environ.get("MUSICGEN_MODEL", "facebook/musicgen-small"),
    }

@app.post("/background")
def background(req: BackgroundRequest):
    """
    Generate background-only (so the app can swap backgrounds without regenerating voice/text).
    """
    bg = (req.backgroundSound or "").lower()
    if bg == "none":
        return {"backgroundAudioUrl": None}

    enable_musicgen = (os.environ.get("ENABLE_MUSICGEN", "false").lower() == "true")
    if not enable_musicgen:
        raise HTTPException(
            status_code=503,
            detail="Background generation disabled. Set ENABLE_MUSICGEN=true on the local AI server.",
        )
    try:
        seconds = int(os.environ.get("MUSICGEN_DURATION_SECONDS", "30"))
        seconds = max(10, min(60, seconds))
        background_file = _musicgen_generate_wav(req.backgroundSound, req.goal, seconds)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Background generation unavailable: {e}")

    return {"backgroundAudioUrl": f"/files/{background_file}"}


@app.get("/files/{name}")
def get_file(name: str):
    fp = FILES / name
    if not fp.exists():
        return {"error": "not_found"}
    return FileResponse(fp)


@app.post("/generate")
def generate(req: GenerateRequest):
    # TEXT (neural): Ollama LLM
    prompt = (
        "You are a meditation coach. Create a short guided meditation.\n"
        f"Goal: {req.goal}\n"
        f"Duration minutes: {req.durationMinutes}\n"
        f"Voice style: {req.voiceStyle}\n"
        f"Background sound: {req.backgroundSound}\n"
        "Return:\n"
        "Title: ...\n"
        "Description: ...\n"
        "Script:\n"
        "- ...\n"
    )
    text = _ollama_generate_text(prompt)

    # Minimal parsing (robust enough for now)
    title = "Meditation"
    description = "Generated meditation session."
    script = text
    for line in text.splitlines():
        if line.lower().startswith("title:"):
            title = line.split(":", 1)[1].strip() or title
        if line.lower().startswith("description:"):
            description = line.split(":", 1)[1].strip() or description

    # TTS (neural): Piper
    # We try to speak the script; if not configured, we raise (so you notice).
    tts_text = script
    voice_file = None
    try:
        voice_file = _piper_tts_wav(tts_text, req.voiceStyle)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"TTS unavailable: {e}")

    # Background (neural): MusicGen (optional)
    background_file = None
    enable_musicgen = (os.environ.get("ENABLE_MUSICGEN", "false").lower() == "true")
    bg = (req.backgroundSound or "").lower()
    if bg != "none":
        if not enable_musicgen:
            raise HTTPException(
                status_code=503,
                detail="Background generation disabled. Set ENABLE_MUSICGEN=true on the local AI server.",
            )
        try:
            seconds = int(os.environ.get("MUSICGEN_DURATION_SECONDS", "30"))
            seconds = max(10, min(60, seconds))
            background_file = _musicgen_generate_wav(req.backgroundSound, req.goal, seconds)
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"Background generation unavailable: {e}")

    return {
        "title": title,
        "description": description,
        "script": script,
        "durationMinutes": req.durationMinutes,
        "audioUrl": f"/files/{voice_file}",
        "backgroundAudioUrl": (f"/files/{background_file}" if background_file else None),
        "coverImageUrl": None,
    }

