import 'package:flutter/material.dart';

import '../services/focus_stats_service.dart';
import '../services/tasks_service.dart';
import 'calendar_screen.dart';
import 'create_task_screen.dart';
import 'stats_screen.dart';
import 'tasks_screen.dart';
import 'timer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _totalTasks = 0;
  int _doneTasks = 0;
  int _focusSessions = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    final tasks = await TasksService.getTasks();
    final sessions = await FocusStatsService.getCompletedSessions();

    if (!mounted) return;
    setState(() {
      _totalTasks = tasks.length;
      _doneTasks = tasks.where((e) => e['completed'] == true).length;
      _focusSessions = sessions;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final completionRate = _totalTasks == 0 ? 0.0 : _doneTasks / _totalTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Management'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _loadOverview, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today Progress',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text('Tasks: $_doneTasks / $_totalTasks'),
                          const SizedBox(height: 8),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: completionRate),
                            duration: const Duration(milliseconds: 650),
                            builder: (context, progress, _) {
                              return LinearProgressIndicator(value: progress);
                            },
                          ),
                          const SizedBox(height: 12),
                          Text('Focus sessions done: $_focusSessions'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuButton(context, 'Tasks', Icons.task, const TasksScreen()),
                const SizedBox(height: 12),
                _buildMenuButton(context, 'Create Task', Icons.add_circle, const CreateTaskScreen()),
                const SizedBox(height: 12),
                _buildMenuButton(context, 'Timer', Icons.timer, const TimerScreen()),
                const SizedBox(height: 12),
                _buildMenuButton(context, 'Calendar', Icons.calendar_today, const CalendarScreen()),
                const SizedBox(height: 12),
                _buildMenuButton(context, 'Statistics', Icons.bar_chart, const StatsScreen()),
              ],
            ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, IconData icon, Widget screen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          _loadOverview();
        },
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
      ),
    );
  }
}
