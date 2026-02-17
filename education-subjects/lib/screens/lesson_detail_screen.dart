import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/education_service.dart';

class LessonDetailScreen extends StatelessWidget {
  const LessonDetailScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final style = _subjectStyle(lesson.subject);

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: style.color.withValues(alpha: 0.18),
                    child: Icon(style.icon, color: style.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.subject,
                          style: TextStyle(color: style.color, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(lesson.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              lesson.description,
              style: TextStyle(fontSize: 15, color: Colors.grey[800]),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                lesson.content,
                style: const TextStyle(fontSize: 16, height: 1.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _SubjectStyle _subjectStyle(String subject) {
    if (subject == EducationService.math) {
      return const _SubjectStyle(Colors.blue, Icons.calculate_rounded);
    }
    if (subject == EducationService.physics) {
      return const _SubjectStyle(Colors.red, Icons.science_rounded);
    }
    return const _SubjectStyle(Colors.green, Icons.biotech_rounded);
  }
}

class _SubjectStyle {
  final Color color;
  final IconData icon;

  const _SubjectStyle(this.color, this.icon);
}
