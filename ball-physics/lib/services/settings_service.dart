import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

class SettingsService {
  static const String _keyPrefix = 'settings_';

  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'gravity': prefs.getDouble('${_keyPrefix}gravity') ?? 9.8,
        'ballSpeed': prefs.getDouble('${_keyPrefix}ballSpeed') ?? 1.0,
        'soundEnabled': prefs.getBool('${_keyPrefix}soundEnabled') ?? true,
      };
    } catch (e) {
      LoggerService.error('Error loading settings', e);
      return {
        'gravity': 9.8,
        'ballSpeed': 1.0,
        'soundEnabled': true,
      };
    }
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (settings.containsKey('gravity')) {
        await prefs.setDouble('${_keyPrefix}gravity', settings['gravity']);
      }
      if (settings.containsKey('ballSpeed')) {
        await prefs.setDouble('${_keyPrefix}ballSpeed', settings['ballSpeed']);
      }
      if (settings.containsKey('soundEnabled')) {
        await prefs.setBool('${_keyPrefix}soundEnabled', settings['soundEnabled']);
      }
    } catch (e) {
      LoggerService.error('Error saving settings', e);
      rethrow;
    }
  }
}
