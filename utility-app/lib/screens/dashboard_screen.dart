import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _HeaderCard(),
        SizedBox(height: 12),
        _TipCard(
          icon: Icons.checklist,
          title: 'Tasks',
          description: 'Track priority items and close daily work quickly.',
        ),
        SizedBox(height: 12),
        _TipCard(
          icon: Icons.timer_outlined,
          title: 'Focus Sessions',
          description: 'Use Pomodoro timer to avoid context switching.',
        ),
        SizedBox(height: 12),
        _TipCard(
          icon: Icons.note_alt_outlined,
          title: 'Notes',
          description: 'Save meeting outcomes and follow-up actions.',
        ),
        SizedBox(height: 12),
        _TipCard(
          icon: Icons.calculate_outlined,
          title: 'Calculator',
          description: 'Estimate work cost and net value instantly.',
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Work Utility Hub',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'One compact app for planning, focus, and quick calculations.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
}
