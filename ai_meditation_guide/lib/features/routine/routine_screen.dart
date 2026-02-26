import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/ai_service.dart';
import '../../services/breathing_library_service.dart';
import '../../services/meditation_library_service.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

enum _RoutineType { meditation, breathing }

class _RoutineItem {
  _RoutineItem({
    required this.id,
    required this.slotTitle,
    required this.title,
    required this.description,
    required this.durationLabel,
    required this.type,
    this.meditation,
    this.breathing,
  });

  final String id;
  final String slotTitle;
  final String title;
  final String description;
  final String durationLabel;
  final _RoutineType type;
  final GeneratedMeditation? meditation;
  final BreathingPractice? breathing;
}

class _RoutineScreenState extends State<RoutineScreen> {
  final Random _random = Random();
  List<_RoutineItem> _items = const <_RoutineItem>[];
  bool _saved = false;
  bool _showResult = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _generateRoutine();
  }

  void _generateRoutine() {
    final medSaved = MeditationLibraryService.instance;
    final breathDefaults = BreathingLibraryService.defaults;
    final medFuture = medSaved.getAll();
    medFuture.then((saved) {
      if (!mounted) return;
      final meditations = saved.map((e) => e.meditation).toList();
      final items = <_RoutineItem>[
        _buildMorning(meditations),
        _buildAfternoon(breathDefaults),
        _buildEvening(meditations, breathDefaults),
      ];
      setState(() {
        _items = items;
        _saved = false;
        _currentStep = 0;
      });
    });
  }

  _RoutineItem _buildMorning(List<GeneratedMeditation> meditations) {
    if (meditations.isNotEmpty) {
      final m = meditations[_random.nextInt(meditations.length)];
      return _RoutineItem(
        id: 'morning_${MeditationLibraryService.instance.buildId(m)}',
        slotTitle: 'Morning meditation',
        title: '${m.durationMinutes} MINUTES',
        description: m.description.isNotEmpty ? m.description : 'Take a quick meditation break',
        durationLabel: '${m.durationMinutes} MIN',
        type: _RoutineType.meditation,
        meditation: m,
      );
    }
    return _RoutineItem(
      id: 'morning_default',
      slotTitle: 'Morning meditation',
      title: '2 MINUTES',
      description: 'Take a quick meditation break',
      durationLabel: '2 MIN',
      type: _RoutineType.meditation,
      meditation: GeneratedMeditation(
        goal: MeditationGoal.reduceStress,
        title: 'Morning Meditation',
        description: 'Take a quick meditation break',
        durationMinutes: 2,
        script: '',
        coverAssetPath: 'assets/meditation/buterfly.png',
      ),
    );
  }

  _RoutineItem _buildAfternoon(List<BreathingPractice> practices) {
    final b = practices[_random.nextInt(practices.length)];
    return _RoutineItem(
      id: 'afternoon_${BreathingLibraryService.instance.buildId(b)}',
      slotTitle: 'Afternoon breathing',
      title: b.title,
      description: '${b.description}\nInhale ${b.inhaleSeconds} sec. Exhale ${b.exhaleSeconds} sec.',
      durationLabel: '${b.durationMinutes} MIN',
      type: _RoutineType.breathing,
      breathing: b,
    );
  }

  _RoutineItem _buildEvening(
    List<GeneratedMeditation> meditations,
    List<BreathingPractice> practices,
  ) {
    final useMeditation = meditations.isNotEmpty && _random.nextBool();
    if (useMeditation) {
      final m = meditations[_random.nextInt(meditations.length)];
      return _RoutineItem(
        id: 'evening_${MeditationLibraryService.instance.buildId(m)}',
        slotTitle: 'Evening relaxation',
        title: '${m.durationMinutes} MINUTES',
        description: m.description.isNotEmpty ? m.description : 'Take a quick meditation break',
        durationLabel: '${m.durationMinutes} MIN',
        type: _RoutineType.meditation,
        meditation: m,
      );
    }
    final b = practices[_random.nextInt(practices.length)];
    return _RoutineItem(
      id: 'evening_${BreathingLibraryService.instance.buildId(b)}',
      slotTitle: 'Evening relaxation',
      title: b.title,
      description: '${b.description}\nInhale ${b.inhaleSeconds} sec. Exhale ${b.exhaleSeconds} sec.',
      durationLabel: '${b.durationMinutes} MIN',
      type: _RoutineType.breathing,
      breathing: b,
    );
  }

  Future<void> _saveRoutine() async {
    for (final item in _items) {
      if (item.type == _RoutineType.breathing && item.breathing != null) {
        await BreathingLibraryService.instance.save(item.breathing!);
      }
      if (item.type == _RoutineType.meditation && item.meditation != null) {
        await MeditationLibraryService.instance.save(item.meditation!);
      }
    }
    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Routine saved')),
    );
  }

  Future<void> _markDone() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Great job! Routine marked as done')),
    );
  }

  void _startNextStep(BuildContext context) {
    if (_items.isEmpty) return;
    if (_currentStep >= _items.length) {
      _currentStep = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine completed')),
      );
      return;
    }
    final item = _items[_currentStep];
    _currentStep++;
    if (item.meditation != null) {
      context.push('/player', extra: item.meditation);
      return;
    }
    if (item.breathing != null) {
      context.goNamed('breathing');
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
            color: const Color(0xFFF7F7FA),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _showResult ? _buildResultBody(context) : _buildIntroBody(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroBody(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _CircleActionButton(
              icon: const Icon(Icons.close, color: Color(0xFFA5ACB9)),
              onTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Text(
                'DAILY ROUTINE',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111111),
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 260,
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
                      width: 220,
                      height: 220,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0x8877C97E), Color(0x0077C97E)],
                          stops: [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Image.asset(
                  'assets/routine/mat.png',
                  width: 190,
                  height: 190,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Daily Routine helps you maintain balance throughout the day. Here you can generate a personalised practice — from morning meditation to evening relaxation.',
          textAlign: TextAlign.center,
          style: GoogleFonts.funnelDisplay(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
            color: const Color(0xFF111111),
          ),
        ),
        const Spacer(),
        _StartSessionButton(
          text: 'START SESSION',
          onTap: () => setState(() => _showResult = true),
        ),
      ],
    );
  }

  Widget _buildResultBody(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _CircleActionButton(
              icon: const Icon(Icons.close, color: Color(0xFFA5ACB9)),
              onTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Text(
                'ROUTINE',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111111),
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final item = _items[i];
              return _RoutineCard(item: item);
            },
          ),
        ),
        const SizedBox(height: 10),
        _StartSessionButton(
          text: 'START',
          onTap: () => _startNextStep(context),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _markDone,
          child: Text(
            'MARK AS DONE',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
          ),
        ),
      ],
    );
  }

}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.item,
  });

  final _RoutineItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9ECF2)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                item.slotTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.funnelDisplay(
                  fontSize: 16,
                  height: 1.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: const Color(0xFF111111),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 126,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: 98,
                    height: 98,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _RoutineCover(item: item),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              item.durationLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 18 / 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFA1A9B6),
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
    );
  }
}

class _RoutineCover extends StatelessWidget {
  const _RoutineCover({required this.item});

  final _RoutineItem item;

  @override
  Widget build(BuildContext context) {
    if (item.type == _RoutineType.breathing) {
      return Container(
        color: const Color(0xFFD4E4D9),
        child: Center(
          child: Image.asset(
            item.breathing?.iconAssetPath ?? 'assets/routine/yoga-mat.png',
            width: 52,
            height: 52,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.self_improvement_outlined,
              color: Color(0xFF67BE78),
              size: 44,
            ),
          ),
        ),
      );
    }

    final meditation = item.meditation;
    final imageUrl = (meditation?.coverImageUrl ?? '').trim();
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('data:image')) {
        final bytes = _decodeDataUri(imageUrl);
        if (bytes != null) {
          return Image.memory(bytes, fit: BoxFit.cover);
        }
      }
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    final asset = (meditation?.coverAssetPath ?? '').trim();
    if (asset.isNotEmpty) {
      return Image.asset(
        asset,
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

class _StartSessionButton extends StatelessWidget {
  const _StartSessionButton({
    required this.text,
    required this.onTap,
  });

  final String text;
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
                text,
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

