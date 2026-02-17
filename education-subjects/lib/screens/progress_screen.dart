import 'package:flutter/material.dart';

import '../services/education_service.dart';
import '../services/progress_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _loading = true;
  Map<String, Map<String, int>> _stats = <String, Map<String, int>>{};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _loading = true);
    final stats = await ProgressService.getProgressStats();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  Color _subjectColor(String subject) {
    if (subject == EducationService.math) return Colors.blue;
    if (subject == EducationService.physics) return Colors.red;
    return Colors.green;
  }

  String _motivationText(int average) {
    if (average >= 90) return 'Outstanding! Keep this streak going.';
    if (average >= 75) return 'Great progress! You are on the right track.';
    if (average >= 50) return 'Good work. Practice a bit more every day.';
    return 'Start with short sessions and build momentum.';
  }

  @override
  Widget build(BuildContext context) {
    final subjects = EducationService.getSubjects();

    final percentages = subjects.map((subject) {
      final raw = _stats[subject] ?? const <String, int>{};
      final total = raw['total'] ?? 0;
      final correct = raw['correct'] ?? 0;
      if (total <= 0) return 0;
      return ((correct / total) * 100).round();
    }).toList();

    final average = percentages.isEmpty
        ? 0
        : (percentages.reduce((a, b) => a + b) / percentages.length).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        actions: [
          IconButton(
            onPressed: _loadProgress,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Learning summary', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          'Average mastery: $average%',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(_motivationText(average)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < subjects.length; i++) ...[
                  _ProgressCard(
                    subject: subjects[i],
                    stats: _stats[subjects[i]] ?? const <String, int>{},
                    color: _subjectColor(subjects[i]),
                    delayMs: i * 120,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.subject,
    required this.stats,
    required this.color,
    required this.delayMs,
  });

  final String subject;
  final Map<String, int> stats;
  final Color color;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final correct = stats['correct'] ?? 0;
    final total = stats['total'] ?? 0;
    final quizzes = stats['quizzes'] ?? 0;
    final value = total > 0 ? (correct / total).clamp(0.0, 1.0).toDouble() : 0.0;
    final percent = (value * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                Text('$percent%'),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: Duration(milliseconds: 500 + delayMs),
              curve: Curves.easeOut,
              builder: (context, animated, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: animated,
                    backgroundColor: color.withValues(alpha: 0.16),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text('Correct answers: $correct of $total   |   Quizzes: $quizzes'),
            if (total == 0) ...[
              const SizedBox(height: 4),
              Text(
                'No attempts yet. Start a quiz to build progress.',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
