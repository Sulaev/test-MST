## Local AI Server (free/open-source stack)

This is a **local** sidecar service to generate:
- meditation text (LLM)
- voice audio (neural TTS)
- background music / ambience (neural audio model)
- cover image url (optional)

It runs on your dev machine, so the app can work on emulators **without a hosted backend**.

### Quick start (WSL)

```bash
cd tool/local_ai_server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python3 -m uvicorn server:app --host 0.0.0.0 --port 8787
```

### Enable neural background (MusicGen)

MusicGen is optional and heavy. Install separately:

```bash
pip install torch==2.5.1 --index-url https://download.pytorch.org/whl/cpu
pip install audiocraft==1.3.0
```

Then run the server with:

- `ENABLE_MUSICGEN=true`
- (optional) `MUSICGEN_MODEL=facebook/musicgen-small`
- (optional) `MUSICGEN_DURATION_SECONDS=30` (10..60)

### Configure the app

For Android Emulator:
- `LOCAL_AI_BASE_URL=http://10.0.2.2:8787`

Enable local AI:
- `ENABLE_LOCAL_AI=true`

If you use `run_simple.sh`, add these to `.env` near it.

### Notes

This server is intentionally **pluggable**:
- if you have `Ollama` running, it can call it for LLM
- if you install `piper-tts`, it can call it for TTS
- if you install `audiocraft` MusicGen, it can generate background audio

The Flutter app expects the endpoint:
- `POST /generate`

You can check server readiness:
- `GET /health`

You can regenerate background only:
- `POST /background`

Response shape:

```json
{
  "title": "...",
  "description": "...",
  "script": "...",
  "durationMinutes": 5,
  "audioUrl": "http://.../files/voice.mp3",
  "backgroundAudioUrl": "http://.../files/bg.wav",
  "coverImageUrl": "http://.../files/cover.png"
}
```

