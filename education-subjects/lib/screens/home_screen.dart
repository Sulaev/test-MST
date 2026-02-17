import 'package:flutter/material.dart';

import 'practice_screen.dart';
import 'progress_screen.dart';
import 'quiz_screen.dart';
import 'subject_selection_screen.dart';
import 'theory_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(
        title: 'Subjects',
        subtitle: 'Choose math, physics or chemistry.',
        icon: Icons.auto_stories_rounded,
        color: const Color(0xFF6C63FF),
        screen: const SubjectSelectionScreen(),
      ),
      _MenuItem(
        title: 'Theory',
        subtitle: 'Read short lessons with examples.',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF2D9CDB),
        screen: const TheoryScreen(),
      ),
      _MenuItem(
        title: 'Practice',
        subtitle: 'Train on practical tasks by topic.',
        icon: Icons.draw_rounded,
        color: const Color(0xFF27AE60),
        screen: const PracticeScreen(),
      ),
      _MenuItem(
        title: 'Quiz',
        subtitle: 'Test yourself and get instant feedback.',
        icon: Icons.quiz_rounded,
        color: const Color(0xFFF2994A),
        screen: const QuizScreen(),
      ),
      _MenuItem(
        title: 'Progress',
        subtitle: 'Track your learning achievements.',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFFEB5757),
        screen: const ProgressScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Learning Lab')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF928CFF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, learner!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Study a little every day. Small steps create big results.',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < items.length; i++)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (i * 120)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 20),
                    child: child,
                  ),
                );
              },
              child: _MenuCard(item: items[i]),
            ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => item.screen),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(item.subtitle, style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
