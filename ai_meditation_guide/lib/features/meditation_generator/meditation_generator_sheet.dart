import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/ai_service.dart';

class MeditationGeneratorSheet {
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (context) => const _MeditationGeneratorSheetBody(),
    );
  }
}

class _MeditationGeneratorSheetBody extends StatefulWidget {
  const _MeditationGeneratorSheetBody();

  @override
  State<_MeditationGeneratorSheetBody> createState() =>
      _MeditationGeneratorSheetBodyState();
}

class _MeditationGeneratorSheetBodyState
    extends State<_MeditationGeneratorSheetBody> {
  MeditationGoal? _goal;
  int? _durationMinutes;
  VoiceStyle? _voiceStyle;
  BackgroundSound? _backgroundSound;
  bool _isLoading = false;
  String? _errorText;

  GeneratedMeditation? _generated;

  bool get _canGenerate =>
      !_isLoading &&
      _goal != null &&
      _durationMinutes != null &&
      _voiceStyle != null &&
      _backgroundSound != null;

  Future<void> _generate() async {
    if (!_canGenerate) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final meditation = await AIService.instance
          .generateMeditation(
            goal: _goal!,
            durationMinutes: _durationMinutes!,
            voiceStyle: _voiceStyle!,
            backgroundSound: _backgroundSound!,
          );
      if (!mounted) return;
      setState(() => _generated = meditation);
    } catch (e) {
      if (!mounted) return;
      final message = 'Generation failed. $e';
      setState(() => _errorText = message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              child: _generated == null ? _buildForm() : _buildResult(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        const SizedBox(height: 10),
        _TopBar(
          title: 'GENERATE MEDITATION',
          onClose: () => Navigator.of(context).pop(),
        ),
        // Бабочка без боковых паддингов — градиент от края до края.
        const _ButterflyHero(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  'Fill in the details below to\ngenerate a meditation',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    height: 26 / 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 16),
                _OptionRow(
                  iconAsset: 'assets/meditation/icon/target.png',
                  title: 'Meditation Goal',
                  value: _goal == null ? null : _goal!.name,
                  onTap: () async {
                    final picked = await _pickGoal(context, _goal);
                    if (picked == null) return;
                    setState(() => _goal = picked);
                  },
                ),
                const SizedBox(height: 10),
                _OptionRow(
                  iconAsset: 'assets/meditation/icon/timer.png',
                  title: 'Duration',
                  value: _durationMinutes == null
                      ? null
                      : '${_durationMinutes!} min',
                  onTap: () async {
                    final picked =
                        await _pickDuration(context, _durationMinutes);
                    if (picked == null) return;
                    setState(() => _durationMinutes = picked);
                  },
                ),
                const SizedBox(height: 10),
                _OptionRow(
                  iconAsset: 'assets/meditation/icon/voice.png',
                  title: 'Voice Style',
                  value: _voiceStyle == null ? null : _voiceStyle!.name,
                  onTap: () async {
                    final picked = await _pickVoiceStyle(context, _voiceStyle);
                    if (picked == null) return;
                    setState(() => _voiceStyle = picked);
                  },
                ),
                const SizedBox(height: 10),
                _OptionRow(
                  iconAsset: 'assets/meditation/icon/sound.png',
                  title: 'Background Sound',
                  value: _backgroundSound == null ? null : _backgroundSound!.name,
                  onTap: () async {
                    final picked =
                        await _pickBackgroundSound(context, _backgroundSound);
                    if (picked == null) return;
                    setState(() => _backgroundSound = picked);
                  },
                ),
                const SizedBox(height: 18),
                _GenerateButton(
                  enabled: _canGenerate,
                  isLoading: _isLoading,
                  onTap: _generate,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorText!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 16 / 12,
                      color: const Color(0xFFB42318),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final meditation = _generated!;
    return Column(
      children: [
        const SizedBox(height: 10),
        _TopBar(
          title: 'MEDITATION',
          onClose: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: _CoverImage(meditation: meditation),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  meditation.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  meditation.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111111),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: _StartButton(
            onTap: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              // Push after the sheet is closed to avoid using a deactivated context.
              Future.microtask(() => router.push('/player', extra: meditation));
            },
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _CircleIconButton(
                icon: Icons.close,
                onTap: onClose,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.funnelDisplay(
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: const Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: const Color(0xFF90939F)),
          ),
        ),
      ),
    );
  }
}

class _ButterflyHero extends StatelessWidget {
  const _ButterflyHero();

  @override
  Widget build(BuildContext context) {
    // Цвет фона шторки — от него начинается и к нему заканчивается градиент.
    const sheetBg = Color(0xFFF7F7FA);

    return SizedBox(
      width: double.infinity,
      height: 290,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ─────────────────────────────────────────────────────────────────
          // Плавный вертикальный градиент: белый → фиолетовый → белый.
          // ─────────────────────────────────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.15, 0.50, 0.85, 1.0],
                  colors: [
                    sheetBg,                   // 0%   — белый (как фон шторки)
                    Color(0xFFF0EBF8),         // 15%  — чуть сиреневый
                    Color(0xFFE4D9F7),         // 50%  — насыщенный сиреневый
                    Color(0xFFF0EBF8),         // 85%  — снова светлее
                    sheetBg,                   // 100% — белый
                  ],
                ),
              ),
            ),
          ),

          // ─────────────────────────────────────────────────────────────────
          // Тень под бабочкой — почти на всю ширину экрана.
          // ─────────────────────────────────────────────────────────────────
          Positioned(
            bottom: -20,
            left: 10,
            right: 10,
            child: Opacity(
              opacity: 0.45,
              child: Image.asset(
                'assets/meditation/shadow.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // ─────────────────────────────────────────────────────────────────
          // Бабочка.
          // ─────────────────────────────────────────────────────────────────
          Center(
            child: Image.asset(
              'assets/meditation/buterfly.png',
              width: 240,
              height: 240,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.iconAsset,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 10, 24, 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : const Color(0xFFF6F7FA),
                borderRadius: BorderRadius.circular(100),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                iconAsset,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                color: isSelected ? Colors.white : const Color(0xFF90939F),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: value == null
                  ? Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        height: 24 / 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF90939F),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 14 / 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF90939F),
                          ),
                        ),
                        const SizedBox(height: 0),
                        Text(
                          value!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            height: 18 / 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111111),
                          ),
                        ),
                      ],
                    ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF90939F)),
          ],
        ),
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  final bool enabled;
  final bool isLoading;
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
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(fg),
                        ),
                      )
                    : Text(
                      'GENERATE',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: fg,
                      ),
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

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.only(left: 10, right: 4),
        child: Row(
          children: [
            const SizedBox(width: 56),
            Expanded(
              child: Text(
                'START',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7FA).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
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

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.meditation});

  final GeneratedMeditation meditation;

  @override
  Widget build(BuildContext context) {
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
    if (meditation.coverAssetPath != null &&
        meditation.coverAssetPath!.isNotEmpty) {
      return Image.asset(
        meditation.coverAssetPath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return const ColoredBox(color: Colors.transparent);
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

Future<MeditationGoal?> _pickGoal(
  BuildContext context,
  MeditationGoal? current,
) {
  return _pickFromSheet<MeditationGoal>(
    context: context,
    title: 'MEDITATION GOAL',
    values: MeditationGoal.values,
    current: current,
    label: (v) => _beautifyEnum(v.name),
  );
}

Future<int?> _pickDuration(BuildContext context, int? current) {
  const values = [5, 10, 15];
  return _pickFromSheet<int>(
    context: context,
    title: 'DURATION',
    values: values,
    current: current,
    label: (v) => '$v min',
  );
}

Future<VoiceStyle?> _pickVoiceStyle(BuildContext context, VoiceStyle? current) {
  return _pickFromSheet<VoiceStyle>(
    context: context,
    title: 'VOICE STYLE',
    values: VoiceStyle.values,
    current: current,
    label: (v) => _beautifyEnum(v.name),
  );
}

Future<BackgroundSound?> _pickBackgroundSound(
  BuildContext context,
  BackgroundSound? current,
) {
  return _pickFromSheet<BackgroundSound>(
    context: context,
    title: 'BACKGROUND SOUND',
    values: BackgroundSound.values,
    current: current,
    label: (v) => _beautifyEnum(v.name),
  );
}

Future<T?> _pickFromSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> values,
  required T? current,
  required String Function(T) label,
}) async {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.25),
    builder: (context) => _PickerSheet<T>(
      title: title,
      values: values,
      current: current,
      label: label,
    ),
  );
}

class _PickerSheet<T> extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.values,
    required this.current,
    required this.label,
  });

  final String title;
  final List<T> values;
  final T? current;
  final String Function(T) label;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(44),
          topRight: Radius.circular(44),
        ),
        child: Container(
          height: media.size.height * 0.62,
          width: double.infinity,
          color: const Color(0xFFF7F7FA),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _CircleIconButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: const Color(0xFF111111),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: values.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final v = values[i];
                      final isCurrent = current != null && v == current;
                      return GestureDetector(
                        onTap: () => Navigator.of(context).pop(v),
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(100),
                            border: isCurrent
                                ? Border.all(
                                    color: const Color(0xFF111111)
                                        .withOpacity(0.12),
                                  )
                                : null,
                          ),
                          child: Text(
                            label(v),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              height: 24 / 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111111),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _beautifyEnum(String s) {
  if (s.isEmpty) return s;
  final withSpaces = s.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) {
    return '${m.group(1)} ${m.group(2)}';
  });
  return withSpaces[0].toUpperCase() + withSpaces.substring(1);
}

