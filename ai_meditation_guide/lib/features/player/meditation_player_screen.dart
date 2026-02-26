import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import '../../config/app_config.dart';
import '../../core/ui/app_colors.dart';
import '../../services/ai_service.dart';
import '../../services/meditation_library_service.dart';

class MeditationPlayerScreen extends StatefulWidget {
  const MeditationPlayerScreen({
    super.key,
    required this.meditation,
  });

  final GeneratedMeditation meditation;

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen> {
  late final AudioPlayer _voicePlayer;
  late final AudioPlayer _bgPlayer;
  late final FlutterTts _tts;
  StreamSubscription<Duration>? _voicePosSub;
  StreamSubscription<Duration?>? _voiceDurationSub;
  StreamSubscription<PlayerState>? _voiceStateSub;
  StreamSubscription<PlaybackEvent>? _voiceEventSub;
  Timer? _ttsProgressTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _useTtsVoice = false;
  bool _ttsAvailable = false;
  String? _voiceError;
  String? _backgroundError;
  double _voiceVolume = 1.0;
  double _bgVolume = 0.45;
  bool _isBgChanging = false;
  bool _isFavorite = false;
  String? _favoriteId;
  String? _currentBgUrl;

  @override
  void initState() {
    super.initState();
    _voicePlayer = AudioPlayer();
    _bgPlayer = AudioPlayer();
    _tts = FlutterTts();
    _init();
  }

  Future<void> _init() async {
    _favoriteId = MeditationLibraryService.instance.buildId(widget.meditation);
    _isFavorite = await MeditationLibraryService.instance.isSavedById(_favoriteId!);

    final url = widget.meditation.audioUrl;
    var voiceReady = false;
    if (url != null && url.isNotEmpty) {
      try {
        if (url.startsWith('file://')) {
          await _voicePlayer.setFilePath(Uri.parse(url).toFilePath());
        } else {
          await _voicePlayer.setUrl(url, headers: _authHeadersForUrl(url));
        }
        voiceReady = true;
      } catch (_) {
        voiceReady = false;
      }
    }

    final bgUrl = widget.meditation.backgroundAudioUrl;
    _currentBgUrl = (bgUrl != null && bgUrl.isNotEmpty) ? bgUrl : null;
    if (_currentBgUrl != null) {
      try {
        await _setBackgroundSource(_currentBgUrl!);
        await _bgPlayer.setLoopMode(LoopMode.one);
        await _bgPlayer.setVolume(_bgVolume);
      } catch (_) {
        _backgroundError =
            'Background sound unavailable. Could not load selected source.';
      }
    }

    if (voiceReady) {
      await _voicePlayer.setVolume(_voiceVolume);
    } else {
      _ttsAvailable = await _setupTts();
      if (!_ttsAvailable) {
        _voiceError =
            'Voice unavailable on this device/emulator. Install or enable a Text-to-Speech engine.';
      }
    }

    _duration = voiceReady
        ? (_voicePlayer.duration ?? Duration(minutes: widget.meditation.durationMinutes))
        : Duration(minutes: widget.meditation.durationMinutes);
    _useTtsVoice = !voiceReady;

    _voicePosSub = _voicePlayer.positionStream.listen((pos) {
      setState(() {
        _position = pos;
      });
    });

    _voiceDurationSub = _voicePlayer.durationStream.listen((d) {
      if (d == null) return;
      setState(() => _duration = d);
    });

    _voiceStateSub = _voicePlayer.playerStateStream.listen((state) async {
      if (!mounted) return;
      if (_useTtsVoice) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() => _isPlaying = false);
      }
    });

    _voiceEventSub = _voicePlayer.playbackEventStream.listen(
      (_) {},
      onError: (Object _) async {
        if (!mounted || _useTtsVoice) return;
        _ttsAvailable = await _setupTts();
        if (!mounted) return;
        if (!_ttsAvailable) {
          setState(() {
            _voiceError =
                'Voice stream failed and no device TTS found. Install/enable TTS engine.';
          });
          return;
        }
        setState(() {
          _useTtsVoice = true;
          _voiceError = 'Voice stream failed. Switched to device TTS.';
        });
        if (_isPlaying) {
          await _tts.speak(widget.meditation.script);
        }
      },
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _ttsProgressTimer?.cancel();
    _tts.stop();
    _voicePosSub?.cancel();
    _voiceDurationSub?.cancel();
    _voiceStateSub?.cancel();
    _voiceEventSub?.cancel();
    _voicePlayer.dispose();
    _bgPlayer.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startTtsProgress() {
    _ttsProgressTimer?.cancel();
    _ttsProgressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isPlaying || !_useTtsVoice) return;
      setState(() {
        final next = _position + const Duration(seconds: 1);
        if (next >= _duration) {
          _position = _duration;
          _isPlaying = false;
          _ttsProgressTimer?.cancel();
        } else {
          _position = next;
        }
      });
    });
  }

  Future<void> _shareMeditation() async {
    final text = '${widget.meditation.title}\n\n${widget.meditation.script}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meditation text copied. You can share it now.')),
    );
  }

  Future<void> _toggleFavorite() async {
    final id = _favoriteId ?? MeditationLibraryService.instance.buildId(widget.meditation);
    if (_isFavorite) {
      final removed = await MeditationLibraryService.instance.remove(id);
      if (!mounted) return;
      if (removed) {
        setState(() => _isFavorite = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meditation removed from saved list.')),
      );
      return;
    }

    final added = await MeditationLibraryService.instance.save(widget.meditation);
    if (!mounted) return;
    if (added) {
      setState(() => _isFavorite = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meditation saved for later listening.')),
      );
    } else {
      setState(() => _isFavorite = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _duration - _position;
    final hasBackground = _currentBgUrl != null && _currentBgUrl!.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _PlayerBackground(meditation: widget.meditation)),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.36),
            ],
          ),
        ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned.fill(
                    top: MediaQuery.of(context).size.height * 0.50,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(color: Colors.black.withOpacity(0.015)),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    top: MediaQuery.of(context).size.height * 0.65,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(color: Colors.black.withOpacity(0.03)),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.5, 0.75, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.18),
                            Colors.black.withOpacity(0.42),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _GlassCircleIconButton(
                        size: 44,
                        iconSize: 18,
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _closePlayer,
                      ),
                      _GlassCircleIconButton(
                        size: 44,
                        iconSize: 18,
                        icon: Image.asset(
                          'assets/meditation/icon/heart.png',
                          width: 18,
                          height: 18,
                          color: Colors.white.withOpacity(_isFavorite ? 1.0 : 0.88),
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ],
                  ),
                  const Spacer(flex: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SeekCircleButton(
                        iconAssetPath: 'assets/meditation/icon/rewindBack.png',
                        onTap: () => _seekBy(const Duration(seconds: -15), hasBackground),
                      ),
                      const SizedBox(width: 22),
                      _PlayPauseGlassButton(
                        isPlaying: _isPlaying,
                        onTap: () => _togglePlayback(hasBackground),
                      ),
                      const SizedBox(width: 22),
                      _SeekCircleButton(
                        iconAssetPath: 'assets/meditation/icon/rewindForward.png',
                        onTap: () => _seekBy(const Duration(seconds: 15), hasBackground),
                      ),
                    ],
                  ),
                  const Spacer(flex: 4),
                  Slider(
                    min: 0,
                    max: _duration.inSeconds.toDouble().clamp(1, double.infinity),
                    value: _position.inSeconds.clamp(0, _duration.inSeconds).toDouble(),
                    onChanged: (value) {
                      if (_useTtsVoice) return;
                      final d = Duration(seconds: value.toInt());
                      _voicePlayer.seek(d);
                      if (hasBackground) _bgPlayer.seek(d);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_format(_position), style: const TextStyle(color: Colors.white70)),
                      Text(_format(remaining), style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const Spacer(flex: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _AmbientBadge(
                        title: _selectedBackgroundTitle(),
                        onTap: _isBgChanging ? null : _changeBackground,
                      ),
                      _GlassCircleIconButton(
                        size: 44,
                        iconSize: 20,
                        icon: Image.asset(
                          'assets/meditation/icon/share.png',
                          width: 20,
                          height: 20,
                          color: Colors.white,
                        ),
                        onPressed: _shareMeditation,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_voiceError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _voiceError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFE4E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_backgroundError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _backgroundError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFE4E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePlayback(bool hasBackground) async {
    if (_isLoading) return;
    if (_useTtsVoice && !_ttsAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No TTS engine available on emulator. Install Google Speech Services or test on a real device.',
          ),
        ),
      );
      return;
    }
    if (_isPlaying) {
      if (_useTtsVoice) {
        await _tts.stop();
        _ttsProgressTimer?.cancel();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        await _voicePlayer.pause();
        if (mounted) setState(() => _isPlaying = false);
      }
      if (hasBackground) _bgPlayer.pause();
      return;
    }
    try {
      if (_useTtsVoice) {
        await _tts.stop();
        final res = await _tts.speak(widget.meditation.script);
        if (res == 1 && mounted) {
          setState(() {
            _isPlaying = true;
            _position = Duration.zero;
          });
          _startTtsProgress();
        } else if (mounted) {
          setState(() {
            _voiceError = 'Device TTS did not start playback (engine response: $res).';
          });
        }
      } else {
        await _voicePlayer.play();
        if (mounted) setState(() => _isPlaying = true);
      }
    } catch (_) {
      _ttsAvailable = await _setupTts();
      if (_ttsAvailable) {
        setState(() {
          _useTtsVoice = true;
          _voiceError = 'Voice stream unavailable (auth/network). Using device TTS.';
        });
        final res = await _tts.speak(widget.meditation.script);
        if (res == 1 && mounted) {
          setState(() {
            _isPlaying = true;
            _position = Duration.zero;
          });
          _startTtsProgress();
        }
      } else {
        rethrow;
      }
    }
    if (hasBackground) _bgPlayer.play();
  }

  Future<void> _closePlayer() async {
    if (_useTtsVoice) {
      await _tts.stop();
    } else {
      await _voicePlayer.stop();
    }
    await _bgPlayer.stop();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _seekBy(Duration delta, bool hasBackground) async {
    if (_useTtsVoice) return;
    final current = _voicePlayer.position;
    final next = (current + delta);
    final clamped = next < Duration.zero
        ? Duration.zero
        : (next > _duration ? _duration : next);
    await _voicePlayer.seek(clamped);
    if (hasBackground) await _bgPlayer.seek(clamped);
  }

  Future<void> _confirmFinishEarly() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish early?'),
        content: const Text('Do you want to end this session now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (_useTtsVoice) {
      await _tts.stop();
    } else {
      await _voicePlayer.stop();
    }
    await _bgPlayer.stop();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _changeBackground() async {
    final selected = await showModalBottomSheet<BackgroundSound>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BackgroundSoundPickerSheet(
        initialVolume: _bgVolume,
        selected: _soundFromCurrentBgUrl(),
        onVolumeChanged: (v) async {
          setState(() => _bgVolume = v);
          await _bgPlayer.setVolume(v);
        },
      ),
    );

    if (selected == null) return;

    setState(() => _isBgChanging = true);
    try {
      if (selected == BackgroundSound.none) {
        await _bgPlayer.stop();
        setState(() => _currentBgUrl = null);
        return;
      }

      final newUrl = _readyBackgroundUrl(selected);
      if (newUrl == null || newUrl.isEmpty) {
        throw Exception('No background URL');
      }

      await _setBackgroundSource(newUrl);
      await _bgPlayer.setLoopMode(LoopMode.one);
      await _bgPlayer.setVolume(_bgVolume);
      setState(() => _currentBgUrl = newUrl);

      if (_isPlaying) {
        await _bgPlayer.play();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Background generation failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBgChanging = false);
    }
  }

  String? _readyBackgroundUrl(BackgroundSound sound) {
    switch (sound) {
      case BackgroundSound.nature:
        return 'assets/embientMusic/nature.mp3';
      case BackgroundSound.ambient:
        return 'assets/embientMusic/ambient.mp3';
      case BackgroundSound.rain:
        return 'assets/embientMusic/rain.wav';
      case BackgroundSound.none:
        return null;
    }
  }

  Future<void> _setBackgroundSource(String source) async {
    if (source.startsWith('file://')) {
      await _bgPlayer.setFilePath(Uri.parse(source).toFilePath());
      return;
    }
    final uri = Uri.tryParse(source);
    final isHttp = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    if (isHttp) {
      await _bgPlayer.setUrl(source);
      return;
    }
    await _bgPlayer.setAsset(source);
  }

  BackgroundSound _soundFromCurrentBgUrl() {
    final current = _currentBgUrl;
    if (current == null || current.isEmpty) return BackgroundSound.none;
    final nature = _readyBackgroundUrl(BackgroundSound.nature);
    final ambient = _readyBackgroundUrl(BackgroundSound.ambient);
    final rain = _readyBackgroundUrl(BackgroundSound.rain);
    if (current == nature) return BackgroundSound.nature;
    if (current == ambient) return BackgroundSound.ambient;
    if (current == rain) return BackgroundSound.rain;
    return BackgroundSound.none;
  }

  String _selectedBackgroundTitle() {
    switch (_soundFromCurrentBgUrl()) {
      case BackgroundSound.nature:
        return 'Nature';
      case BackgroundSound.ambient:
        return 'Ambient music';
      case BackgroundSound.rain:
        return 'Rain';
      case BackgroundSound.none:
        return 'None';
    }
  }

  Future<bool> _setupTts() async {
    final engines = await _tts.getEngines;
    if (engines is! List || engines.isEmpty) {
      return false;
    }

    await _tts.setLanguage('en-US');
    try {
      await _tts.setAudioAttributesForNavigation();
    } catch (_) {}
    try {
      await _tts.setQueueMode(0);
    } catch (_) {}
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    await _tts.setVolume(_voiceVolume);
    await _tts.awaitSpeakCompletion(false);
    _tts.setStartHandler(() {
      if (!mounted) return;
      setState(() => _isPlaying = true);
    });
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      _ttsProgressTimer?.cancel();
      setState(() => _isPlaying = false);
    });
    _tts.setCancelHandler(() {
      if (!mounted) return;
      _ttsProgressTimer?.cancel();
      setState(() => _isPlaying = false);
    });
    _tts.setPauseHandler(() {
      if (!mounted) return;
      _ttsProgressTimer?.cancel();
      setState(() => _isPlaying = false);
    });
    _tts.setErrorHandler((message) {
      if (!mounted) return;
      _ttsProgressTimer?.cancel();
      setState(() {
        _isPlaying = false;
        _voiceError = 'Device TTS error: $message';
      });
    });
    return true;
  }

  Map<String, String>? _authHeadersForUrl(String url) {
    final token = AppConfig.genApiAuthToken;
    if (token.isEmpty) return null;
    final uri = Uri.tryParse(url);
    final host = uri?.host.toLowerCase() ?? '';
    if (host.contains('gen-api.ru')) {
      return <String, String>{'Authorization': 'Bearer $token'};
    }
    return null;
  }

  String _voiceSourceLabel() {
    if (_useTtsVoice) {
      return _ttsAvailable ? 'Voice source: Device TTS' : 'Voice source: Unavailable';
    }
    final url = widget.meditation.audioUrl ?? '';
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.contains('gen-api.ru')) return 'Voice source: GenAPI stream';
    if (host.contains('streamelements.com')) return 'Voice source: Fallback stream';
    return 'Voice source: Remote stream';
  }

  Color _voiceSourceColor() {
    if (_voiceError != null) return const Color(0xFFFFC8A2);
    if (_useTtsVoice) return const Color(0xFFAEE3FF);
    final url = widget.meditation.audioUrl ?? '';
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.contains('gen-api.ru')) return const Color(0xFFA8E6A3);
    return const Color(0xFFE5E7EB);
  }
}

class _VoiceStatusBadge extends StatelessWidget {
  const _VoiceStatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.85)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GlassCircleIconButton extends StatelessWidget {
  const _GlassCircleIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 40,
    this.iconSize = 18,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: IconButton(
          onPressed: onPressed,
          iconSize: iconSize,
          splashRadius: size / 2,
          color: Colors.white,
          icon: icon,
        ),
      ),
    );
  }
}

class _BackgroundSoundPickerSheet extends StatefulWidget {
  const _BackgroundSoundPickerSheet({
    required this.initialVolume,
    required this.selected,
    required this.onVolumeChanged,
  });

  final double initialVolume;
  final BackgroundSound selected;
  final ValueChanged<double> onVolumeChanged;

  @override
  State<_BackgroundSoundPickerSheet> createState() =>
      _BackgroundSoundPickerSheetState();
}

class _BackgroundSoundPickerSheetState extends State<_BackgroundSoundPickerSheet> {
  late double _volume;

  @override
  void initState() {
    super.initState();
    _volume = widget.initialVolume;
  }

  @override
  Widget build(BuildContext context) {
    final cards = <({BackgroundSound sound, String title, String asset})>[
      (
        sound: BackgroundSound.none,
        title: 'None',
        asset: 'assets/meditation/bg_sound/none.png',
      ),
      (
        sound: BackgroundSound.nature,
        title: 'Nature',
        asset: 'assets/meditation/bg_sound/nature.png',
      ),
      (
        sound: BackgroundSound.ambient,
        title: 'Ambient music',
        asset: 'assets/meditation/bg_sound/ambient.png',
      ),
      (
        sound: BackgroundSound.rain,
        title: 'Rain',
        asset: 'assets/meditation/bg_sound/rain.png',
      ),
    ];

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.92,
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE8EBEF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _GlassCircleIconButton(
                    size: 34,
                    iconSize: 16,
                    icon: const Icon(Icons.close, color: Color(0xFF8F96A3)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'BACKGROUND SOUNDS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF151515),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.86,
                ),
                itemBuilder: (context, i) {
                  final item = cards[i];
                  final selected = item.sound == widget.selected;
                  return _BackgroundSoundCard(
                    title: item.title,
                    assetPath: item.asset,
                    selected: selected,
                    onTap: () => Navigator.of(context).pop(item.sound),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Background Volume',
                  style: TextStyle(
                    color: Color(0xFF1B1B1B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Slider(
                min: 0,
                max: 1,
                value: _volume,
                activeColor: const Color(0xFF1B1B1B),
                inactiveColor: Colors.black12,
                onChanged: (v) {
                  setState(() => _volume = v);
                  widget.onVolumeChanged(v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundSoundCard extends StatefulWidget {
  const _BackgroundSoundCard({
    required this.title,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_BackgroundSoundCard> createState() => _BackgroundSoundCardState();
}

class _BackgroundSoundCardState extends State<_BackgroundSoundCard> {
  Future<Uint8List?> _loadBytes(String path) async {
    try {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } catch (_) {
      // Fallback for case-variant folder naming in different environments.
      final alt = path.contains('/bgSoundImage/')
          ? path.replaceFirst('/bgSoundImage/', '/bgsoundImage/')
          : path.replaceFirst('/bgsoundImage/', '/bgSoundImage/');
      try {
        final data = await rootBundle.load(alt);
        return data.buffer.asUint8List();
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 4),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder<Uint8List?>(
                  future: _loadBytes(widget.assetPath),
                  builder: (context, snap) {
                    if (snap.hasData && snap.data != null) {
                      return Image.memory(
                        snap.data!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    }
                    return const DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFFE9ECEF)),
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFF9AA2AE),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.title,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeekCircleButton extends StatelessWidget {
  const _SeekCircleButton({
    required this.iconAssetPath,
    required this.onTap,
  });

  final String iconAssetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.65)),
        ),
        child: Center(
          child: Image.asset(
            iconAssetPath,
            width: 20,
            height: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _PlayPauseGlassButton extends StatelessWidget {
  const _PlayPauseGlassButton({
    required this.isPlaying,
    required this.onTap,
  });

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(48),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.20),
          borderRadius: BorderRadius.circular(48),
          border: Border.all(color: Colors.white.withOpacity(0.65)),
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 42,
        ),
      ),
    );
  }
}

class _AmbientBadge extends StatelessWidget {
  const _AmbientBadge({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 191,
        height: 48,
        padding: const EdgeInsets.fromLTRB(4, 6, 16, 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.26),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/meditation/icon/sound.png',
                  width: 18,
                  height: 18,
                  color: Colors.white.withOpacity(0.92),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Background sounds',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.52),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerBackground extends StatelessWidget {
  const _PlayerBackground({required this.meditation});

  final GeneratedMeditation meditation;

  @override
  Widget build(BuildContext context) {
    return _buildImage();
  }

  Widget _buildImage() {
    if (meditation.coverImageUrl != null && meditation.coverImageUrl!.isNotEmpty) {
      final url = meditation.coverImageUrl!;
      if (url.startsWith('data:image')) {
        final bytes = _tryDecodeDataUri(url);
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallback(),
          );
        }
      }
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    if (meditation.coverAssetPath != null && meditation.coverAssetPath!.isNotEmpty) {
      return Image.asset(
        meditation.coverAssetPath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundGradientStart,
            AppColors.backgroundGradientEnd,
          ],
        ),
      ),
    );
  }

  Uint8List? _tryDecodeDataUri(String value) {
    final comma = value.indexOf(',');
    if (comma < 0) return null;
    final payload = value.substring(comma + 1).trim();
    if (payload.isEmpty) return null;
    try {
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }
}
