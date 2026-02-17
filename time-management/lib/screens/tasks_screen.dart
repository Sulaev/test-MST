import 'package:flutter/material.dart';

import '../services/logger_service.dart';
import '../services/tasks_service.dart';
import 'create_task_screen.dart';

enum TaskFilter { all, active, done, highPriority }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> _tasks = <Map<String, dynamic>>[];
  bool _isLoading = true;
  TaskFilter _filter = TaskFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    try {
      final tasks = await TasksService.getTasks();
      tasks.sort((a, b) {
        final aCompleted = a['completed'] == true ? 1 : 0;
        final bCompleted = b['completed'] == true ? 1 : 0;
        if (aCompleted != bCompleted) return aCompleted.compareTo(bCompleted);

        final priorities = {'high': 0, 'medium': 1, 'low': 2};
        final ap = priorities[(a['priority'] ?? 'medium').toString()] ?? 1;
        final bp = priorities[(b['priority'] ?? 'medium').toString()] ?? 1;
        if (ap != bp) return ap.compareTo(bp);

        final ad = DateTime.tryParse((a['createdAt'] ?? '').toString()) ?? DateTime(1970);
        final bd = DateTime.tryParse((b['createdAt'] ?? '').toString()) ?? DateTime(1970);
        return bd.compareTo(ad);
      });

      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      LoggerService.error('Error loading tasks', e);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load tasks')),
        );
      }
    }
  }

  Future<void> _toggleTask(int index) async {
    try {
      final task = _filteredTasks[index];
      final isCompleted = !(task['completed'] == true);
      await TasksService.updateTask(task['id'].toString(), {
        'completed': isCompleted,
        'completedAt': isCompleted ? DateTime.now().toIso8601String() : null,
      });
      await _loadTasks();
    } catch (e) {
      LoggerService.error('Error toggling task', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update task')),
        );
      }
    }
  }

  Future<void> _deleteTaskById(String id) async {
    try {
      final allTasks = await TasksService.getTasks();
      final removed = allTasks.firstWhere((t) => t['id'].toString() == id);
      await TasksService.deleteTask(id);
      await _loadTasks();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${removed['title']}" deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              final restored = Map<String, dynamic>.from(removed);
              restored.remove('id');
              await TasksService.addTask(restored);
              await _loadTasks();
            },
          ),
        ),
      );
    } catch (e) {
      LoggerService.error('Error deleting task', e);
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'High';
      case 'low':
        return 'Low';
      default:
        return 'Medium';
    }
  }

  bool _isOverdue(Map<String, dynamic> task) {
    if (task['completed'] == true) return false;
    final raw = task['dueDate'];
    if (raw == null || raw.toString().isEmpty) return false;
    final due = DateTime.tryParse(raw.toString());
    if (due == null) return false;
    final now = DateTime.now();
    final endOfDue = DateTime(due.year, due.month, due.day, 23, 59, 59);
    return now.isAfter(endOfDue);
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd.$mm.${date.year}';
  }

  Widget _buildFilterChip(TaskFilter value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredTasks {
    var result = _tasks;

    switch (_filter) {
      case TaskFilter.active:
        result = result.where((t) => t['completed'] != true).toList();
        break;
      case TaskFilter.done:
        result = result.where((t) => t['completed'] == true).toList();
        break;
      case TaskFilter.highPriority:
        result = result.where((t) => (t['priority'] ?? 'medium') == 'high').toList();
        break;
      case TaskFilter.all:
        break;
    }

    final query = _search.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((t) {
        final title = (t['title'] ?? '').toString().toLowerCase();
        final desc = (t['description'] ?? '').toString().toLowerCase();
        return title.contains(query) || desc.contains(query);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final completed = _tasks.where((e) => e['completed'] == true).length;
    final ratio = _tasks.isEmpty ? 0.0 : completed / _tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insights, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text('Completed: $completed of ${_tasks.length}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: ratio),
                      duration: const Duration(milliseconds: 450),
                      builder: (context, value, _) {
                        return LinearProgressIndicator(value: value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      ),
                hintText: 'Search tasks',
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(TaskFilter.all, 'All'),
                  _buildFilterChip(TaskFilter.active, 'Active'),
                  _buildFilterChip(TaskFilter.done, 'Done'),
                  _buildFilterChip(TaskFilter.highPriority, 'High'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                    ? const Center(
                        child: Text(
                          'No tasks for selected filters',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        child: ListView.builder(
                          itemCount: _filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = _filteredTasks[index];
                            final taskId = task['id'].toString();
                            final isCompleted = task['completed'] == true;
                            final priority = (task['priority'] ?? 'medium').toString();
                            final due = DateTime.tryParse((task['dueDate'] ?? '').toString());
                            final overdue = _isOverdue(task);

                            return Dismissible(
                              key: ValueKey(taskId),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red,
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (_) => _deleteTaskById(taskId),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCompleted ? Colors.grey.shade100 : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: overdue
                                        ? Colors.redAccent
                                        : _priorityColor(priority).withValues(alpha: 0.35),
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: isCompleted,
                                  onChanged: (_) => _toggleTask(index),
                                  secondary: Icon(
                                    isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: isCompleted ? Colors.green : Colors.grey,
                                  ),
                                  title: Text(
                                    (task['title'] ?? 'Untitled').toString(),
                                    style: TextStyle(
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: isCompleted ? Colors.grey : null,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if ((task['description'] ?? '').toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            task['description'].toString(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              decoration: isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          Chip(
                                            label: Text(_priorityLabel(priority)),
                                            backgroundColor:
                                                _priorityColor(priority).withValues(alpha: 0.12),
                                            labelStyle: TextStyle(
                                              color: _priorityColor(priority),
                                              fontSize: 12,
                                            ),
                                            visualDensity: VisualDensity.compact,
                                            side: BorderSide.none,
                                          ),
                                          if (due != null)
                                            Chip(
                                              label: Text(
                                                overdue
                                                    ? 'Overdue: ${_formatDate(due)}'
                                                    : 'Deadline: ${_formatDate(due)}',
                                              ),
                                              backgroundColor: overdue
                                                  ? Colors.red.withValues(alpha: 0.12)
                                                  : Colors.blue.withValues(alpha: 0.10),
                                              labelStyle: TextStyle(
                                                color: overdue ? Colors.red : Colors.blue,
                                                fontSize: 12,
                                              ),
                                              visualDensity: VisualDensity.compact,
                                              side: BorderSide.none,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
          );
          if (result == true) {
            await _loadTasks();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}
