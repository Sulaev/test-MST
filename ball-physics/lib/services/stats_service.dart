import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

class StatsService {
  static const String _keyHighScore = 'stats_highScore';
  static const String _keyGamesPlayed = 'stats_gamesPlayed';
  static const String _keyTotalScore = 'stats_totalScore';

  static Future<Map<String, int>> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'highScore': prefs.getInt(_keyHighScore) ?? 0,
        'gamesPlayed': prefs.getInt(_keyGamesPlayed) ?? 0,
        'totalScore': prefs.getInt(_keyTotalScore) ?? 0,
      };
    } catch (e) {
      LoggerService.error('Error loading stats', e);
      return {
        'highScore': 0,
        'gamesPlayed': 0,
        'totalScore': 0,
      };
    }
  }

  static Future<void> saveScore(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentHighScore = prefs.getInt(_keyHighScore) ?? 0;
      final gamesPlayed = prefs.getInt(_keyGamesPlayed) ?? 0;
      final totalScore = prefs.getInt(_keyTotalScore) ?? 0;

      if (score > currentHighScore) {
        await prefs.setInt(_keyHighScore, score);
        LoggerService.info('New high score: $score');
      }

      await prefs.setInt(_keyGamesPlayed, gamesPlayed + 1);
      await prefs.setInt(_keyTotalScore, totalScore + score);
    } catch (e) {
      LoggerService.error('Error saving score', e);
      rethrow;
    }
  }
}
