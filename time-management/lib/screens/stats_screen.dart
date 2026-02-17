import 'package:flutter/material.dart';

import '../services/focus_stats_service.dart';
import '../services/tasks_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _loading = true;
  int _totalTasks = 0;
  int _doneTasks = 0;
  int _overdueTasks = 0;
  int _focusSessions = 0;
  int _focusMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final tasks = await TasksService.getTasks();
    final now = DateTime.now();

    int overdue = 0;
    for (final task in tasks) {
      if (task['completed'] == true) continue;
      final raw = task['dueDate'];
      if (raw == null || raw.toString().isEmpty) continue;
      final due = DateTime.tryParse(raw.toString());
      if (due == null) continue;
      final endOfDay = DateTime(due.year, due.month, due.day, 23, 59, 59);
      if (now.isAfter(endOfDay)) overdue++;
    }

    final sessions = await FocusStatsService.getCompletedSessions();
    final minutes = await FocusStatsService.getTotalMinutes();

    if (!mounted) return;
    setState(() {
      _totalTasks = tasks.length;
      _doneTasks = tasks.where((t) => t['completed'] == true).length;
      _overdueTasks = overdue;
      _focusSessions = sessions;
      _focusMinutes = minutes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final completionRate = _totalTasks == 0 ? 0.0 : _doneTasks / _totalTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(onPressed: _loadStats, icon: const Icon(Icons.refresh)),
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
                        const Text(
                          'Task completion',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text('Done: $_doneTasks of $_totalTasks'),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: completionRate),
                          duration: const Duration(milliseconds: 600),
                          builder: (context, value, _) => LinearProgressIndicator(value: value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatCard('Overdue tasks', _overdueTasks.toString(), Icons.warning_amber_rounded, Colors.red),
                const SizedBox(height: 12),
                _buildStatCard('Focus sessions', _focusSessions.toString(), Icons.timer, Colors.orange),
                const SizedBox(height: 12),
                _buildStatCard('Minutes in focus', _focusMinutes.toString(), Icons.bolt, Colors.blue),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
