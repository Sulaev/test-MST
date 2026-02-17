import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../services/logger_service.dart';
import '../services/storage_service.dart';

enum TaskFilter { all, open, done }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _controller = TextEditingController();
  List<TaskItem> _tasks = <TaskItem>[];
  TaskFilter _filter = TaskFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final tasks = await StorageService.loadTasks();
    setState(() => _tasks = tasks);
  }

  Future<void> _persist() async {
    await StorageService.saveTasks(_tasks);
  }

  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _tasks = [
        TaskItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: text,
          isDone: false,
          createdAt: DateTime.now(),
        ),
        ..._tasks,
      ];
      _controller.clear();
    });
    LoggerService.info('Task added');
    _persist();
  }

  void _toggle(TaskItem task) {
    setState(() {
      _tasks = _tasks
          .map((t) => t.id == task.id ? t.copyWith(isDone: !t.isDone) : t)
          .toList();
    });
    _persist();
  }

  void _delete(TaskItem task) {
    setState(() => _tasks.removeWhere((t) => t.id == task.id));
    LoggerService.warning('Task removed');
    _persist();
  }

  List<TaskItem> get _filtered {
    switch (_filter) {
      case TaskFilter.open:
        return _tasks.where((e) => !e.isDone).toList();
      case TaskFilter.done:
        return _tasks.where((e) => e.isDone).toList();
      case TaskFilter.all:
        return _tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Add a work task',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addTask(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _addTask, child: const Text('Add')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SegmentedButton<TaskFilter>(
            segments: const [
              ButtonSegment(value: TaskFilter.all, label: Text('All')),
              ButtonSegment(value: TaskFilter.open, label: Text('Open')),
              ButtonSegment(value: TaskFilter.done, label: Text('Done')),
            ],
            selected: <TaskFilter>{_filter},
            onSelectionChanged: (set) => setState(() => _filter = set.first),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(child: Text('No tasks yet'))
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final task = _filtered[index];
                    return Dismissible(
                      key: ValueKey(task.id),
                      onDismissed: (_) => _delete(task),
                      child: CheckboxListTile(
                        value: task.isDone,
                        onChanged: (_) => _toggle(task),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
