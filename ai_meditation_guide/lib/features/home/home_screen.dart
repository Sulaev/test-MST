import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/ui/app_colors.dart';
import '../../services/ai_service.dart';
import '../../services/meditation_library_service.dart';
import '../breathing/breathing_setup_screen.dart';
import '../meditation_generator/meditation_generator_sheet.dart';
import '../routine/routine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<SavedMeditationEntry>> _savedFuture;

  @override
  void initState() {
    super.initState();
    _savedFuture = MeditationLibraryService.instance.getAll();
  }

  void _refreshSaved() {
    setState(() {
      _savedFuture = MeditationLibraryService.instance.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SavedMeditationEntry>>(
      future: _savedFuture,
      builder: (context, snapshot) {
        final saved = snapshot.data ?? const <SavedMeditationEntry>[];
        final latest = saved.isNotEmpty ? saved.first.meditation : null;
        return _HomeView(saved: saved, latest: latest);
      },
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({required this.saved, required this.latest});

  final List<SavedMeditationEntry> saved;
  final GeneratedMeditation? latest;

  static const Color _textColor = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateText = DateFormat('EEEE, d MMM', 'en').format(now);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6E9EA), Color(0xFFE8EEFF), Color(0xFFE2F0E8)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _GreetingHeader(name: 'Vitalii'),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _BigMoodTitle(),
              ),
              const SizedBox(height: 24),
              // Стекло на всю ширину: от начала кнопок и до низа экрана.
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(child: _FullWidthGlassSection()),
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                      child: Column(
                        children: [
                          _ActionGroup(
                            onGenerate: () =>
                                MeditationGeneratorSheet.show(context),
                            onBreathing: () =>
                                BreathingSetupSheet.show(context),
                            onRoutine: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              barrierColor: Colors.black.withOpacity(0.25),
                              builder: (context) => const RoutineScreen(),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _SectionHeader(
                            title: "Today's Meditation",
                            trailing: dateText,
                          ),
                          const SizedBox(height: 12),
                          _TodayMeditationCard(
                            meditation: latest,
                            onTap: latest == null
                                ? () => context.goNamed('routine')
                                : () => context.push('/player', extra: latest),
                          ),
                          const SizedBox(height: 18),
                          const _SectionHeader(title: 'Recommended Sessions'),
                          const SizedBox(height: 10),
                          const _RecommendedChips(),
                          const SizedBox(height: 12),
                          _RecommendedList(saved: saved),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 20,
                      child: _GlassFooterTabs(
                        active: _FooterTab.home,
                        onHome: () {},
                        onHistory: () => context.goNamed('history'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Hello, ',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              height: 32 / 24,
              letterSpacing: -1.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF111111),
            ),
          ),
          TextSpan(
            text: name,
            style: GoogleFonts.inter(
              fontSize: 24,
              height: 32 / 24,
              letterSpacing: -1.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111111),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _BigMoodTitle extends StatelessWidget {
  const _BigMoodTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'How are you\n',
            style: GoogleFonts.playfairDisplay(
              fontSize: 48,
              height: 52 / 48,
              letterSpacing: -1.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF111111),
            ),
          ),
          TextSpan(
            text: 'feeling ',
            style: GoogleFonts.inter(
              fontSize: 48,
              height: 52 / 48,
              letterSpacing: -1.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111111),
            ),
          ),
          TextSpan(
            text: 'today?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 48,
              height: 52 / 48,
              letterSpacing: -1.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF111111),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({
    required this.onGenerate,
    required this.onBreathing,
    required this.onRoutine,
  });

  final VoidCallback onGenerate;
  final VoidCallback onBreathing;
  final VoidCallback onRoutine;

  @override
  Widget build(BuildContext context) {
    // Figma: Frame (buttons block)
    // - padding: 16
    // - gap: 4
    // - bottom border: 1px, #111111 @ 4%
    // - glass start effect on top (fade)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF111111).withOpacity(0.04),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _ActionButton(
            iconAsset: 'assets/icon/yoga-1.png',
            label: 'GENERATE MEDITATION',
            onTap: onGenerate,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          const SizedBox(height: 4),
          _ActionButton(
            iconAsset: 'assets/icon/yoga-2.png',
            label: 'BREATHING EXERCISE',
            onTap: onBreathing,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 4),
          _ActionButton(
            iconAsset: 'assets/icon/yoga-mat.png',
            label: 'DAILY ROUTINE',
            onTap: onRoutine,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.iconAsset,
    required this.label,
    required this.onTap,
    required this.borderRadius,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    // Figma button:
    // - height: 56
    // - padding: vertical 10, horizontal 24
    // - icon: 24x24
    // - label: 18 / 24, -0.5, semibold, uppercase
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              Image.asset(
                iconAsset,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => const SizedBox(
                  width: 24,
                  height: 24,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0x11111111),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      height: 24 / 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      color: const Color(0xFF111111),
                    ),
                  ),
                ),
              ),
              // Балансируем центрирование текста (симметрия относительно иконки 24 + gap 10)
              const SizedBox(width: 34),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassStartPanel extends StatelessWidget {
  const _GlassStartPanel({
    required this.child,
    required this.radius,
    required this.padding,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Stack(
          children: [
            // Base tint
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(radius),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFF111111).withOpacity(0.04),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            // "Glass start" highlight fade on top
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.00),
                      Colors.white.withOpacity(0.60),
                    ],
                    stops: const [0.0, 0.32],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111111),
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF111111).withOpacity(0.55),
            ),
          ),
      ],
    );
  }
}

class _TodayMeditationCard extends StatelessWidget {
  const _TodayMeditationCard({required this.onTap, required this.meditation});

  final VoidCallback onTap;
  final GeneratedMeditation? meditation;

  @override
  Widget build(BuildContext context) {
    final minutes = meditation?.durationMinutes ?? 2;
    final description = (meditation?.description ?? '').trim().isNotEmpty
        ? (meditation?.description ?? '')
        : 'Take a quick meditation break';

    return _GlassSurface(
      radius: 24,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _MeditationCoverImage(meditation: meditation),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$minutes MIN',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                        '$minutes MINUTES',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF111111).withOpacity(0.65),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBCE7C8).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/icon/yoga-mat.png',
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'DAILY ROUTINE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: const Color(0xFF1F7A4C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _RecommendedChips extends StatefulWidget {
  const _RecommendedChips();

  @override
  State<_RecommendedChips> createState() => _RecommendedChipsState();
}

class _RecommendedChipsState extends State<_RecommendedChips> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final chips = ['SLEEP', 'STRESS & ANXIETY', 'DAILY MEDITATION'];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isActive = _selected == index;
          return GestureDetector(
            onTap: () => setState(() => _selected = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF111111) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  if (!isActive)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: Text(
                chips[index],
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: isActive
                      ? Colors.white
                      : const Color(0xFF111111).withOpacity(0.55),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecommendedList extends StatelessWidget {
  const _RecommendedList({required this.saved});

  final List<SavedMeditationEntry> saved;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 243,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 16),
        itemCount: saved.isEmpty ? 3 : saved.length.clamp(0, 10),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (saved.isEmpty) {
            return const _RecommendedCard(
              title: 'SLEEP',
              minutes: 2,
              iconAsset: 'assets/icon/yoga-1.png',
            );
          }
          final item = saved[index].meditation;
          return _RecommendedCard(
            title: item.title.toUpperCase(),
            minutes: item.durationMinutes,
            iconAsset: 'assets/icon/yoga-1.png',
            meditation: item,
          );
        },
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.title,
    required this.minutes,
    required this.iconAsset,
    this.meditation,
  });

  final String title;
  final int minutes;
  final String iconAsset;
  final GeneratedMeditation? meditation;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: meditation == null
          ? null
          : () => context.push('/player', extra: meditation),
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
              _MeditationCoverImage(meditation: meditation),
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
                                'MEDITATION',
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
                  '$minutes MIN',
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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _MeditationCoverImage extends StatelessWidget {
  const _MeditationCoverImage({required this.meditation});

  final GeneratedMeditation? meditation;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (meditation?.coverImageUrl ?? '').trim();
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('data:image')) {
        final bytes = _decodeDataUri(imageUrl);
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          );
        }
      }
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    final assetPath = (meditation?.coverAssetPath ?? '').trim();
    if (assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
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
          colors: [Color(0xFF6AA5FF), Color(0xFF84D0B5)],
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

enum _FooterTab { home, history }

class _GlassFooterTabs extends StatelessWidget {
  const _GlassFooterTabs({
    required this.active,
    required this.onHome,
    required this.onHistory,
  });

  final _FooterTab active;
  final VoidCallback onHome;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      radius: 999,
      blurSigma: 22,
      tintOpacity: 0.6,
      borderOpacity: 0.35,
      child: Container(
        height: 62,
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            Expanded(
              child: _FooterTabButton(
                active: active == _FooterTab.home,
                label: 'Home',
                icon: Image.asset(
                  'assets/icon/home.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                ),
                onTap: onHome,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FooterTabButton(
                active: active == _FooterTab.history,
                label: 'History',
                icon: Icon(
                  Icons.history_rounded,
                  size: 22,
                  color: active == _FooterTab.history
                      ? const Color(0xFF111111)
                      : const Color(0xFF111111).withOpacity(0.35),
                ),
                onTap: onHistory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterTabButton extends StatelessWidget {
  const _FooterTabButton({
    required this.active,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool active;
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.85) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(
                  color: active
                      ? const Color(0xFF111111)
                      : const Color(0xFF111111).withOpacity(0.35),
                ),
                child: icon,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? const Color(0xFF111111)
                      : const Color(0xFF111111).withOpacity(0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.child,
    required this.radius,
    this.blurSigma = 18,
    this.tintOpacity = 0.75,
    this.borderOpacity = 0.22,
  });

  final Widget child;
  final double radius;
  final double blurSigma;
  final double tintOpacity;
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(tintOpacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Full-width glass background for the bottom part of the Home screen.
/// Starts where the action buttons begin and stretches to the bottom.
class _FullWidthGlassSection extends StatelessWidget {
  const _FullWidthGlassSection();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(44),
        topRight: Radius.circular(44),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.white.withOpacity(0.42)),
            ),
            // Highlight where the glass "starts" at the top.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.82),
                      Colors.white.withOpacity(0.00),
                    ],
                    stops: const [0.0, 0.38],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
