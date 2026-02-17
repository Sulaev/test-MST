import 'dart:async';

import 'package:flutter/material.dart';

import '../services/logger_service.dart';
import '../services/storage_service.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  Timer? _timer;
  int _sessionMinutes = 25;
  int _remainingSeconds = 25 * 60;
  int _completedSessions = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final minutes = await StorageService.loadFocusMinutes();
    final sessions = await StorageService.loadCompletedSessions();
    setState(() {
      _sessionMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _completedSessions = sessions;
    });
  }

  Future<void> _saveConfig() async {
    await StorageService.saveFocusMinutes(_sessionMinutes);
    await StorageService.saveCompletedSessions(_completedSessions);
  }

  void _startPause() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }

    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isRunning = false;
          _completedSessions += 1;
          _remainingSeconds = _sessionMinutes * 60;
        });
        _saveConfig();
        LoggerService.info('Focus session completed');
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
    setState(() {});
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _sessionMinutes * 60;
    });
  }

  String get _formatted {
    final min = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final sec = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pomodoro Focus',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 15, label: Text('15m')),
              ButtonSegment(value: 25, label: Text('25m')),
              ButtonSegment(value: 50, label: Text('50m')),
            ],
            selected: <int>{_sessionMinutes},
            onSelectionChanged: _isRunning
                ? null
                : (set) {
                    setState(() {
                      _sessionMinutes = set.first;
                      _remainingSeconds = _sessionMinutes * 60;
                    });
                    _saveConfig();
                  },
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              _formatted,
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Completed sessions: $_completedSessions',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _startPause,
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_isRunning ? 'Pause' : 'Start'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
