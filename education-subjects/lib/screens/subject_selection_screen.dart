import 'package:flutter/material.dart';

import '../services/education_service.dart';
import 'quiz_screen.dart';
import 'theory_screen.dart';

class SubjectSelectionScreen extends StatelessWidget {
  const SubjectSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjects = <_SubjectCardData>[
      _SubjectCardData(
        name: EducationService.math,
        icon: Icons.calculate_rounded,
        color: const Color(0xFF2D9CDB),
        badge: 'MATH',
      ),
      _SubjectCardData(
        name: EducationService.physics,
        icon: Icons.science_rounded,
        color: const Color(0xFFEB5757),
        badge: 'PHYS',
      ),
      _SubjectCardData(
        name: EducationService.chemistry,
        icon: Icons.biotech_rounded,
        color: const Color(0xFF27AE60),
        badge: 'CHEM',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Subject')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final item = subjects[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 260 + (index * 120)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(scale: 0.9 + (value * 0.1), child: child),
              );
            },
            child: _SubjectCard(item: item),
          );
        },
      ),
    );
  }
}

class _SubjectCardData {
  final String name;
  final IconData icon;
  final Color color;
  final String badge;

  _SubjectCardData({
    required this.name,
    required this.icon,
    required this.color,
    required this.badge,
  });
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.item});

  final _SubjectCardData item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('What would you like to do?'),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => QuizScreen(subject: item.name)),
                            );
                          },
                          icon: const Icon(Icons.quiz_rounded),
                          label: const Text('Start Quiz'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TheoryScreen(initialSubject: item.name)),
                            );
                          },
                          icon: const Icon(Icons.menu_book_rounded),
                          label: const Text('Open Theory'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                item.color.withValues(alpha: 0.10),
                item.color.withValues(alpha: 0.22),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.badge,
                  style: TextStyle(
                    color: item.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Icon(item.icon, size: 44, color: item.color),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, color: item.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
