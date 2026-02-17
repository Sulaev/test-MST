import 'package:flutter/material.dart';

import '../services/education_service.dart';
import 'lesson_detail_screen.dart';

class TheoryScreen extends StatefulWidget {
  const TheoryScreen({super.key, this.initialSubject});

  final String? initialSubject;

  @override
  State<TheoryScreen> createState() => _TheoryScreenState();
}

class _TheoryScreenState extends State<TheoryScreen> {
  late String _selectedSubject;

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.initialSubject ?? 'All';
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ['All', ...EducationService.getSubjects()];
    final lessons = _selectedSubject == 'All'
        ? EducationService.getSubjects()
            .expand((s) => EducationService.getLessonsBySubject(s))
            .toList()
        : EducationService.getLessonsBySubject(_selectedSubject);

    return Scaffold(
      appBar: AppBar(title: const Text('Theory Library')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (final subject in subjects)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: ChoiceChip(
                      label: Text(subject),
                      selected: _selectedSubject == subject,
                      onSelected: (_) => setState(() => _selectedSubject = subject),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: lessons.isEmpty
                ? const Center(child: Text('No lessons found yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      final style = _subjectStyle(lesson.subject);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: style.color.withValues(alpha: 0.14),
                            child: Icon(style.icon, color: style.color),
                          ),
                          title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              lesson.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lesson)),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
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
