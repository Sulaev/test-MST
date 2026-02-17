import 'package:flutter/material.dart';
import '../services/logger_service.dart';
import '../services/stats_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _highScore = 0;
  int _gamesPlayed = 0;
  int _totalScore = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await StatsService.getStats();
      setState(() {
        _highScore = stats['highScore'] ?? 0;
        _gamesPlayed = stats['gamesPlayed'] ?? 0;
        _totalScore = stats['totalScore'] ?? 0;
      });
      LoggerService.info('Stats loaded');
    } catch (e) {
      LoggerService.error('Error loading stats', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatCard('Рекорд', _highScore.toString(), Icons.emoji_events),
            const SizedBox(height: 16),
            _buildStatCard('Игр сыграно', _gamesPlayed.toString(), Icons.games),
            const SizedBox(height: 16),
            _buildStatCard('Всего очков', _totalScore.toString(), Icons.star),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
