import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/ui/app_colors.dart';
import '../../services/breathing_library_service.dart';
import '../../services/meditation_library_service.dart';

enum _BreathingMood { calm, neutral, stressed, anxious }

class BreathingSetupSheet {
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (context) => const _BreathingSetupSheetBody(),
    );
  }
}

class BreathingSetupScreen extends StatefulWidget {
  const BreathingSetupScreen({super.key});

  @override
  State<BreathingSetupScreen> createState() => _BreathingSetupScreenState();
}

class _BreathingSetupScreenState extends State<BreathingSetupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await BreathingSetupSheet.show(context);
      if (!mounted) return;
      context.goNamed('home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }
}

class _BreathingSetupSheetBody extends StatefulWidget {
  const _BreathingSetupSheetBody();

  @override
  State<_BreathingSetupSheetBody> createState() =>
      _BreathingSetupSheetBodyState();
}

class _BreathingSetupSheetBodyState extends State<_BreathingSetupSheetBody> {
  _BreathingMood? _mood;
  int? _durationMin;
  bool _isFavorite = false;
  BreathingPractice? _currentPractice;

  bool get _canStart => _mood != null && _durationMin != null;

  BreathingPractice _buildPractice() {
    final mood = _moodLabel(_mood) ?? 'Relax';
    final duration = _durationMin ?? 2;
    return BreathingPractice(
      title: mood.toUpperCase(),
      description: 'Calm your mind and body',
      durationMinutes: duration,
      inhaleSeconds: 4,
      exhaleSeconds: 6,
      iconAssetPath: 'assets/routine/yoga-mat.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final h = media.size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(44),
            topRight: Radius.circular(44),
          ),
          child: Container(
            height: h * 0.92,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF7F7FA),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _CircleActionButton(
                          icon: const Icon(Icons.close, color: Color(0xFFA5ACB9)),
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            'BREATHING EXERCISE',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111111),
                            ),
                          ),
                        ),
                        _CircleActionButton(
                          icon: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite
                                ? const Color(0xFFF04438)
                                : const Color(0xFFA5ACB9),
                          ),
                          onTap: () async {
                            final practice = _buildPractice();
                            final id = BreathingLibraryService.instance.buildId(practice);
                            final exists =
                                await BreathingLibraryService.instance.isSavedById(id);
                            if (exists) {
                              await BreathingLibraryService.instance.remove(id);
                            } else {
                              await BreathingLibraryService.instance.save(practice);
                            }
                            if (!mounted) return;
                            setState(() {
                              _currentPractice = practice;
                              _isFavorite = !exists;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 230,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: Center(
                              child: Opacity(
                                opacity: 0.16,
                                child: Icon(
                                  Icons.self_improvement_outlined,
                                  size: 210,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Transform.translate(
                                offset: const Offset(0, 8),
                                child: Container(
                                  width: 170,
                                  height: 170,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Color(0x447ACBFF),
                                        Color(0x007ACBFF),
                                      ],
                                      stops: [0.15, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -20,
                            left: 10,
                            right: 10,
                            child: Opacity(
                              opacity: 0.45,
                              child: Image.asset(
                                'assets/breathing/shadow.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                          Center(
                            child: Transform.translate(
                              offset: const Offset(0, -6),
                              child: Image.asset(
                                'assets/breathing/man.png',
                                width: 200,
                                height: 200,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fill in the details below to\ngenerate a breathing exercise',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 32 / 2,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SetupOptionTile(
                      title: 'Mood Check-in',
                      value: _moodLabel(_mood),
                      active: _mood != null,
                      icon: Icons.track_changes_rounded,
                      onTap: () async {
                        final picked = await _pickMood(context, _mood);
                        if (picked == null) return;
                        setState(() => _mood = picked);
                      },
                    ),
                    const SizedBox(height: 10),
                    _SetupOptionTile(
                      title: 'Duration',
                      value: _durationMin == null ? null : '${_durationMin!} min',
                      active: _durationMin != null,
                      icon: Icons.timer_outlined,
                      onTap: () async {
                        final picked = await _pickDuration(context, _durationMin);
                        if (picked == null) return;
                        setState(() => _durationMin = picked);
                      },
                    ),
                    const Spacer(),
                    _StartSessionButton(
                      enabled: _canStart,
                      onTap: () {
                        if (!_canStart) return;
                        final practice = _buildPractice();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _BreathingTrainerScreen(
                              durationMinutes: _durationMin!,
                              mood: _mood!,
                              practice: practice,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _moodLabel(_BreathingMood? mood) {
    switch (mood) {
      case _BreathingMood.calm:
        return 'Calm';
      case _BreathingMood.neutral:
        return 'Neutral';
      case _BreathingMood.stressed:
        return 'Stressed';
      case _BreathingMood.anxious:
        return 'Anxious';
      case null:
        return null;
    }
  }
}

class _SetupOptionTile extends StatelessWidget {
  const _SetupOptionTile({
    required this.title,
    required this.value,
    required this.active,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String? value;
  final bool active;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF).withOpacity(0.72),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? Colors.black : const Color(0xFFF2F4F8),
                  border: Border.all(color: const Color(0xFFE6E9EF)),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: active ? Colors.white : const Color(0xFFB0B7C3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFA6ADB9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (value != null)
                      Text(
                        value!,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF111111),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFB0B7C3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartSessionButton extends StatelessWidget {
  const _StartSessionButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = enabled ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
    final fg = enabled ? Colors.white : const Color(0xFFB9BCC4);
    final arrowBg =
        enabled ? const Color(0xFFF6F7FA).withOpacity(0.08) : const Color(0xFFF6F7FA);
    final arrowFg = enabled ? Colors.white : const Color(0xFFB9BCC4);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(100),
          border: enabled
              ? null
              : Border.all(color: const Color(0xFF111111).withOpacity(0.06)),
        ),
        padding: const EdgeInsets.only(left: 10, right: 4),
        child: Row(
          children: [
            const SizedBox(width: 56),
            Expanded(
              child: Text(
                'START SESSION',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  letterSpacing: -1,
                ),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: arrowBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_forward,
                  color: arrowFg,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
  });

  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.72),
          border: Border.all(color: const Color(0xFFE5E8EE)),
        ),
        child: Center(child: icon),
      ),
    );
  }
}

class _CircleImageActionButton extends StatelessWidget {
  const _CircleImageActionButton({
    required this.assetPath,
    this.fallbackAssetPath,
    required this.onTap,
  });

  final String assetPath;
  final String? fallbackAssetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.72),
          border: Border.all(color: const Color(0xFFE5E8EE)),
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: 18,
            height: 18,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              if (fallbackAssetPath != null) {
                return Image.asset(
                  fallbackAssetPath!,
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.timer_outlined, size: 18, color: Color(0xFFA5ACB9)),
                );
              }
              return const Icon(Icons.timer_outlined, size: 18, color: Color(0xFFA5ACB9));
            },
          ),
        ),
      ),
    );
  }
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

Future<_BreathingMood?> _pickMood(BuildContext context, _BreathingMood? current) async {
  final moods = <(_BreathingMood, String)>[
    (_BreathingMood.calm, 'Calm'),
    (_BreathingMood.neutral, 'Neutral'),
    (_BreathingMood.stressed, 'Stressed'),
    (_BreathingMood.anxious, 'Anxious'),
  ];
  return showModalBottomSheet<_BreathingMood>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return _ChoiceSheet<_BreathingMood>(
        title: 'MEDITATION GOAL',
        values: moods.map((e) => e.$1).toList(),
        labelOf: (v) => moods.firstWhere((e) => e.$1 == v).$2,
        selected: current,
      );
    },
  );
}

Future<int?> _pickDuration(BuildContext context, int? current) async {
  const values = <int>[1, 5, 10];
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return _ChoiceSheet<int>(
        title: 'DURATION',
        values: values,
        labelOf: (v) => '$v min',
        selected: current,
      );
    },
  );
}

class _ChoiceSheet<T> extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.values,
    required this.labelOf,
    required this.selected,
  });

  final String title;
  final List<T> values;
  final String Function(T value) labelOf;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF0F2F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    _CircleActionButton(
                      icon: const Icon(Icons.chevron_left, color: Color(0xFFA5ACB9)),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 22 / 1.3,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111111),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 90),
                for (final item in values) ...[
                  _SheetChoiceTile(
                    title: labelOf(item),
                    selected: selected == item,
                    onTap: () => Navigator.of(context).pop(item),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetChoiceTile extends StatelessWidget {
  const _SheetChoiceTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(28),
          border: selected ? Border.all(color: Colors.black, width: 1.2) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 24 / 1.4,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111111),
          ),
        ),
      ),
    );
  }
}

class _BreathingTrainerScreen extends StatefulWidget {
  const _BreathingTrainerScreen({
    required this.durationMinutes,
    required this.mood,
    required this.practice,
  });

  final int durationMinutes;
  final _BreathingMood mood;
  final BreathingPractice practice;

  @override
  State<_BreathingTrainerScreen> createState() => _BreathingTrainerScreenState();
}

class _BreathingTrainerScreenState extends State<_BreathingTrainerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final AudioPlayer _bgPlayer;
  bool _muted = false;
  int _remaining = 3;
  bool _started = false;
  bool _completed = false;
  late int _totalPhases;
  int _phaseIndex = 0;

  static const Duration _inhaleDuration = Duration(seconds: 4);
  static const Duration _exhaleDuration = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _bgPlayer = AudioPlayer();
    _pulse = AnimationController(
      vsync: this,
      duration: _inhaleDuration,
      reverseDuration: _exhaleDuration,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.36).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOutSine),
    );
    _totalPhases = math.max(1, ((widget.durationMinutes * 60) / 8).round());
    _startBackgroundMusic();
    _runCountdown();
  }

  Future<void> _startBackgroundMusic() async {
    try {
      await _bgPlayer.setAsset('assets/embientMusic/ambient.mp3');
      await _bgPlayer.setLoopMode(LoopMode.all);
      await _bgPlayer.setVolume(_muted ? 0.0 : 1.0);
      await _bgPlayer.play();
    } catch (e) {
      debugPrint('Breathing bg audio error: $e');
    }
  }

  Future<void> _runCountdown() async {
    for (var i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _remaining = i);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() => _started = true);
    _runBreathingLoop();
  }

  Future<void> _runBreathingLoop() async {
    while (mounted && _phaseIndex < _totalPhases) {
      await _pulse.forward();
      await _pulse.reverse();
      _phaseIndex++;
    }
    if (!mounted) return;
    setState(() => _completed = true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _bgPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      _bgPlayer.stop();
      return _BreathingDoneScreen(
        onClose: () {
          // Закрываем тренер и шторку, возвращаясь на главный экран.
          Navigator.of(context).pop(); // pop trainer route
          Navigator.of(context).pop(); // pop breathing bottom sheet
        },
        practice: widget.practice,
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE9F4FF), Color(0xFFF2F4F8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    _CircleActionButton(
                      icon: const Icon(Icons.close, color: Color(0xFFA5ACB9)),
                      onTap: () {
                        _bgPlayer.stop();
                        // Закрываем экран тренера и саму шторку дыхания.
                        Navigator.of(context).pop(); // pop trainer
                        Navigator.of(context).pop(); // pop breathing sheet -> home
                      },
                    ),
                  ],
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _scale,
                  builder: (context, _) {
                    final scale = _started ? _scale.value : 1.0;
                    final t = ((scale - 1.0) / 0.36).clamp(0.0, 1.0);
                    final ring1 = _lerpDouble(120, 208, t);
                    final ring2 = _lerpDouble(136, 286, t);
                    final ring3 = _lerpDouble(152, 380, t);
                    final phaseText = !_started
                        ? '$_remaining'
                        : (_pulse.status == AnimationStatus.forward ? 'Inhale' : 'Exhale');
                    return Center(
                      child: SizedBox(
                        width: 420,
                        height: 420,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: ring3,
                              height: ring3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF7ACBFF).withOpacity(0.12),
                              ),
                            ),
                            Container(
                              width: ring2,
                              height: ring2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF7ACBFF).withOpacity(0.18),
                              ),
                            ),
                            Container(
                              width: ring1,
                              height: ring1,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF7ACBFF).withOpacity(0.24),
                              ),
                            ),
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF7ACBFF),
                                border: Border.all(
                                  width: 3,
                                  color: Colors.white.withOpacity(0.65),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.40),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                phaseText,
                                style: GoogleFonts.funnelDisplay(
                                  fontSize: 24,
                                  height: 32 / 24,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -1.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                Row(
                  children: [
                    _CircleActionButton(
                      icon: Icon(
                        _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: const Color(0xFFA5ACB9),
                      ),
                      onTap: () {
                        setState(() => _muted = !_muted);
                        _bgPlayer.setVolume(_muted ? 0.0 : 1.0);
                      },
                    ),
                    const Spacer(),
                    _CircleImageActionButton(
                      assetPath: 'assets/breathing/icon/revind.png',
                      fallbackAssetPath: 'assets/breathing/icon/rewind.png',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingDoneScreen extends StatefulWidget {
  const _BreathingDoneScreen({
    required this.onClose,
    required this.practice,
  });

  final VoidCallback onClose;
  final BreathingPractice practice;

  @override
  State<_BreathingDoneScreen> createState() => _BreathingDoneScreenState();
}

class _BreathingDoneScreenState extends State<_BreathingDoneScreen> {
  late Future<List<SavedMeditationEntry>> _savedFuture;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _savedFuture = MeditationLibraryService.instance.getAll();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final id = BreathingLibraryService.instance.buildId(widget.practice);
    final saved = await BreathingLibraryService.instance.isSavedById(id);
    if (!mounted) return;
    setState(() => _isFavorite = saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE9F4FF), Color(0xFFF2F4F8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: FutureBuilder<List<SavedMeditationEntry>>(
              future: _savedFuture,
              builder: (context, snapshot) {
                final saved = snapshot.data ?? const <SavedMeditationEntry>[];
                return Column(
                  children: [
                    Row(
                      children: [
                        _CircleActionButton(
                          icon: const Icon(Icons.close, color: Color(0xFFA5ACB9)),
                          onTap: widget.onClose,
                        ),
                        Expanded(
                          child: Text(
                            'BREATHING EXERCISE',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111111),
                            ),
                          ),
                        ),
                        _CircleActionButton(
                          icon: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite
                                ? const Color(0xFFF04438)
                                : const Color(0xFFA5ACB9),
                          ),
                          onTap: () async {
                            final id =
                                BreathingLibraryService.instance.buildId(widget.practice);
                            final exists = await BreathingLibraryService.instance
                                .isSavedById(id);
                            if (exists) {
                              await BreathingLibraryService.instance.remove(id);
                            } else {
                              await BreathingLibraryService.instance.save(widget.practice);
                            }
                            if (!mounted) return;
                            setState(() => _isFavorite = !exists);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 180,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            bottom: -20,
                            left: 10,
                            right: 10,
                            child: Opacity(
                              opacity: 0.45,
                              child: Image.asset(
                                'assets/breathing/shadow.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Transform.translate(
                                offset: const Offset(0, 8),
                                child: Container(
                                  width: 170,
                                  height: 170,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Color(0x447ACBFF),
                                        Color(0x007ACBFF),
                                      ],
                                      stops: [0.15, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Transform.translate(
                              offset: const Offset(0, -6),
                              child: Image.asset(
                                'assets/breathing/man.png',
                                width: 190,
                                height: 190,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Congrats!',
                      style: GoogleFonts.funnelDisplay(
                        fontSize: 32,
                        height: 40 / 32,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1.5,
                        color: const Color(0xFF1B4369),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recommended Sessions',
                        style: GoogleFonts.funnelDisplay(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.5,
                          color: const Color(0xFF111111),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 243,
                      child: saved.isEmpty
                          ? const Center(
                              child: Text(
                                'No saved meditations yet',
                                style: TextStyle(color: Color(0xFF7D8796)),
                              ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: saved.length.clamp(0, 10),
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, i) {
                                final meditation = saved[i].meditation;
                                return _BreathingRecommendedCard(
                                  meditation: meditation,
                                  onTap: () => context.push('/player', extra: meditation),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingRecommendedCard extends StatelessWidget {
  const _BreathingRecommendedCard({
    required this.meditation,
    required this.onTap,
  });

  final dynamic meditation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 157,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _SessionCoverImage(meditation: meditation),
              Positioned(
                top: 8,
                left: 8,
                child: SizedBox(
                  width: 133,
                  height: 24,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0x29111111),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.self_improvement_rounded,
                                size: 18,
                                color: Color(0xFF7ACBFF),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'BREATHING',
                                style: GoogleFonts.funnelDisplay(
                                  fontSize: 12,
                                  height: 15 / 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 34,
                child: Text(
                  '${meditation.durationMinutes} MIN',
                  style: GoogleFonts.funnelDisplay(
                    fontSize: 12,
                    height: 20 / 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: Colors.white.withOpacity(0.64),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Text(
                  _shortSessionLabel((meditation.title as String?) ?? ''),
                  style: GoogleFonts.funnelDisplay(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCoverImage extends StatelessWidget {
  const _SessionCoverImage({required this.meditation});

  final dynamic meditation;

  @override
  Widget build(BuildContext context) {
    final coverUrl = (meditation.coverImageUrl ?? '').toString();
    if (coverUrl.isNotEmpty) {
      if (coverUrl.startsWith('data:image')) {
        final bytes = _decodeDataUri(coverUrl);
        if (bytes != null) {
          return Image.memory(bytes, fit: BoxFit.cover);
        }
      }
      return Image.network(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    final coverAsset = (meditation.coverAssetPath ?? '').toString();
    if (coverAsset.isNotEmpty) {
      return Image.asset(
        coverAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.backgroundGradientStart, AppColors.backgroundGradientEnd],
        ),
      ),
    );
  }

  Uint8List? _decodeDataUri(String value) {
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

String _shortSessionLabel(String title) {
  final cleaned = title.trim();
  if (cleaned.isEmpty) return 'SESSION';
  final first = cleaned.split(RegExp(r'\s+')).first;
  final upper = first.toUpperCase();
  return upper.length > 12 ? upper.substring(0, 12) : upper;
}

