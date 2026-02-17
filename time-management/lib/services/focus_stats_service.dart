import 'package:shared_preferences/shared_preferences.dart';

import 'logger_service.dart';

class FocusStatsService {
  static const String _keyCompletedSessions = 'focus_completed_sessions';
  static const String _keyTotalMinutes = 'focus_total_minutes';

  static Future<int> getCompletedSessions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCompletedSessions) ?? 0;
  }

  static Future<int> getTotalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTotalMinutes) ?? 0;
  }

  static Future<void> addCompletedSession(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = prefs.getInt(_keyCompletedSessions) ?? 0;
      final totalMinutes = prefs.getInt(_keyTotalMinutes) ?? 0;

      await prefs.setInt(_keyCompletedSessions, sessions + 1);
      await prefs.setInt(_keyTotalMinutes, totalMinutes + minutes);
      LoggerService.info('Focus session added: m');
    } catch (e) {
      LoggerService.error('Error saving focus stats', e);
    }
  }
}
