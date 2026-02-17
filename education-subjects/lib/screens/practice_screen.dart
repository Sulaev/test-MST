import 'package:flutter/material.dart';

import '../services/education_service.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  String _subject = EducationService.math;

  static const Map<String, List<_PracticeTask>> _tasks = {
    EducationService.math: [
      _PracticeTask('Solve: 4x - 8 = 16', 'x = 6'),
      _PracticeTask('Find area of triangle base=8 height=5', 'A = 20'),
      _PracticeTask('Perimeter of rectangle 3 by 9', 'P = 24'),
    ],
    EducationService.physics: [
      _PracticeTask('Find force for m=5 and a=3', 'F = 15 N'),
      _PracticeTask('Find voltage when I=2 and R=7', 'V = 14 V'),
      _PracticeTask('Find acceleration when F=18 and m=6', 'a = 3 m/s^2'),
    ],
    EducationService.chemistry: [
      _PracticeTask('Name formula H2O', 'Water'),
      _PracticeTask('Is pH 11 acidic or basic?', 'Basic'),
      _PracticeTask('Write oxygen molecule formula', 'O2'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final current = _tasks[_subject] ?? const <_PracticeTask>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Practice Zone')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              scrollDirection: Axis.horizontal,
              children: [
                for (final subject in EducationService.getSubjects())
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: ChoiceChip(
                      label: Text(subject),
                      selected: _subject == subject,
                      onSelected: (_) => setState(() => _subject = subject),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: current.length,
              itemBuilder: (context, index) {
                final task = current[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 280 + (index * 110)),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(offset: Offset(0, (1 - value) * 16), child: child),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      title: Text(task.question, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Try it yourself, then reveal solution'),
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple.withValues(alpha: 0.12),
                        child: const Icon(Icons.lightbulb_outline_rounded, color: Colors.deepPurple),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Answer: ${task.answer}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeTask {
  final String question;
  final String answer;

  const _PracticeTask(this.question, this.answer);
}
