import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../services/tasks_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Map<String, dynamic>> _tasks = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await TasksService.getTasks();
    if (mounted) {
      setState(() => _tasks = tasks);
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Map<String, dynamic>> _tasksForDay(DateTime day) {
    return _tasks.where((task) {
      final raw = task['dueDate'];
      if (raw == null || raw.toString().isEmpty) return false;
      final due = DateTime.tryParse(raw.toString());
      if (due == null) return false;
      return _isSameDate(due, day);
    }).toList();
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd.$mm.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tasksOfSelectedDay = _tasksForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(onPressed: _loadTasks, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Map<String, dynamic>>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => _isSameDate(day, _selectedDay),
            eventLoader: _tasksForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tasks for ${_formatDate(_selectedDay)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tasksOfSelectedDay.isEmpty
                ? const Center(child: Text('No tasks for selected date'))
                : ListView.builder(
                    itemCount: tasksOfSelectedDay.length,
                    itemBuilder: (context, index) {
                      final task = tasksOfSelectedDay[index];
                      final completed = task['completed'] == true;
                      return ListTile(
                        leading: Icon(
                          completed ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: completed ? Colors.green : Colors.grey,
                        ),
                        title: Text(task['title']?.toString() ?? 'Untitled'),
                        subtitle: Text(task['description']?.toString() ?? ''),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
