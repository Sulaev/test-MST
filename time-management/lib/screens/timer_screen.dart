import 'dart:async';

import 'package:flutter/material.dart';

import '../services/focus_stats_service.dart';
import '../services/tasks_service.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  int _sessionMinutes = 25;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  int _completedSessions = 0;

  Timer? _timer;
  late final AnimationController _pulseController;

  List<Map<String, dynamic>> _tasks = <Map<String, dynamic>>[];
  bool _tasksLoading = true;
  String _priorityFilter = 'all';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.96,
      upperBound: 1.04,
    );
    _loadStats();
    _loadTasks();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final sessions = await FocusStatsService.getCompletedSessions();
    if (mounted) {
      setState(() => _completedSessions = sessions);
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _tasksLoading = true);
    final tasks = await TasksService.getTasks();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _tasksLoading = false;
    });
  }

  Future<void> _toggleTask(Map<String, dynamic> task) async {
    final isDone = !(task['completed'] == true);
    await TasksService.updateTask(task['id'].toString(), {
      'completed': isDone,
      'completedAt': isDone ? DateTime.now().toIso8601String() : null,
    });
    await _loadTasks();
  }

  double get _progress {
    final total = _sessionMinutes * 60;
    if (total <= 0) return 0;
    return (_remainingSeconds / total).clamp(0, 1);
  }

  String get _timeText {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  List<Map<String, dynamic>> get _filteredTasks {
    final filtered = _priorityFilter == 'all'
        ? List<Map<String, dynamic>>.from(_tasks)
        : _tasks
            .where((t) => (t['priority'] ?? 'medium').toString() == _priorityFilter)
            .toList();

    // Keep completed tasks visible, but move them to the bottom.
    filtered.sort((a, b) {
      final aDone = a['completed'] == true;
      final bDone = b['completed'] == true;
      if (aDone == bDone) return 0;
      return aDone ? 1 : -1;
    });
    return filtered;
  }

  void _startOrPauseTimer() {
    if (_isRunning) {
      _pauseTimer();
      return;
    }

    setState(() => _isRunning = true);
    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;

      if (_remainingSeconds <= 1) {
        timer.cancel();
        _pulseController.stop();
        _pulseController.reset();

        setState(() {
          _isRunning = false;
          _remainingSeconds = _sessionMinutes * 60;
          _completedSessions += 1;
        });

        await FocusStatsService.addCompletedSession(_sessionMinutes);

        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Session completed!'),
            content: Text('Great job! Completed sessions: $_completedSessions'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      setState(() => _remainingSeconds -= 1);
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() => _remainingSeconds = _sessionMinutes * 60);
  }

  void _changeSessionMinutes(int minutes) {
    if (_isRunning) return;
    setState(() {
      _sessionMinutes = minutes;
      _remainingSeconds = minutes * 60;
    });
  }

  Color _priorityColor(String value) {
    switch (value) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Widget _buildPriorityChip(String value, String label) {
    final selected = _priorityFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _priorityFilter = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final centerBg = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        actions: [
          IconButton(onPressed: _resetTimer, icon: const Icon(Icons.restart_alt)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Session length'),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 15, label: Text('15')),
                        ButtonSegment(value: 25, label: Text('25')),
                        ButtonSegment(value: 50, label: Text('50')),
                      ],
                      selected: <int>{_sessionMinutes},
                      onSelectionChanged: (set) => _changeSessionMinutes(set.first),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 3,
              child: Center(
                child: GestureDetector(
                  onTap: _startOrPauseTimer,
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale = _isRunning ? _pulseController.value : 1.0;
                            return Transform.scale(scale: scale, child: child);
                          },
                          child: SizedBox(
                            width: 260,
                            height: 260,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: _progress),
                              duration: const Duration(milliseconds: 350),
                              builder: (context, value, _) {
                                return CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 16,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: Colors.orange.withValues(alpha: 0.15),
                                );
                              },
                            ),
                          ),
                        ),
                        Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            color: centerBg,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _timeText,
                              style: const TextStyle(
                                fontSize: 68,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isRunning ? 'Tap to pause' : 'Tap to start',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Completed sessions'),
                    Text(
                      _completedSessions.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.task_alt),
                          const SizedBox(width: 8),
                          const Text('Quick tasks from timer'),
                          const Spacer(),
                          IconButton(
                            onPressed: _loadTasks,
                            icon: const Icon(Icons.refresh, size: 20),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPriorityChip('all', 'All'),
                            _buildPriorityChip('high', 'High'),
                            _buildPriorityChip('medium', 'Medium'),
                            _buildPriorityChip('low', 'Low'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _tasksLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _filteredTasks.isEmpty
                                ? const Center(child: Text('No tasks for filter'))
                                : ListView.builder(
                                    itemCount: _filteredTasks.length,
                                    itemBuilder: (context, index) {
                                      final task = _filteredTasks[index];
                                      final isDone = task['completed'] == true;
                                      final priority = (task['priority'] ?? 'medium').toString();
                                      return AnimatedContainer(
                                        key: ValueKey(task['id']),
                                        duration: const Duration(milliseconds: 280),
                                        curve: Curves.easeOut,
                                        margin: const EdgeInsets.only(bottom: 2),
                                        decoration: BoxDecoration(
                                          color: isDone
                                              ? Colors.grey.withValues(alpha: 0.08)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: AnimatedSlide(
                                          duration: const Duration(milliseconds: 280),
                                          curve: Curves.easeOut,
                                          offset: isDone ? const Offset(0, 0.18) : Offset.zero,
                                          child: ListTile(
                                            dense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                            leading: IconButton(
                                              icon: Icon(
                                                isDone
                                                    ? Icons.check_box_rounded
                                                    : Icons.check_box_outline_blank_rounded,
                                              ),
                                              color: isDone
                                                  ? Colors.grey[600]
                                                  : Colors.grey[700],
                                              onPressed: () => _toggleTask(task),
                                              tooltip: isDone ? 'Mark active' : 'Mark done',
                                            ),
                                            title: Text(
                                              task['title']?.toString() ?? 'Untitled',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isDone ? Colors.grey[600] : null,
                                                decoration: isDone
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                              ),
                                            ),
                                            trailing: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isDone
                                                    ? Colors.grey.withValues(alpha: 0.18)
                                                    : _priorityColor(priority).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                priority,
                                                style: TextStyle(
                                                  color: isDone ? Colors.grey[700] : _priorityColor(priority),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
