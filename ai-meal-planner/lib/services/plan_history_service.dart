import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal_plan.dart';
import 'planner_generation_service.dart';

class PlanHistoryService implements AiPlanCacheStore {
  static const String _historyKey = 'ai_meal_planner_history_v1';
  static const String _aiCacheKey = 'ai_meal_planner_ai_cache_v1';
  static const int _maxSavedPlans = 15;
  static const int _maxCachedAiPlans = 30;

  Future<List<MealPlan>> getHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_historyKey) ?? <String>[];

    return raw
        .map(
          (String item) => _safeDecode(item),
        )
        .whereType<MealPlan>()
        .toList();
  }

  Future<void> savePlan(MealPlan plan) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_historyKey) ?? <String>[];
    raw.insert(0, plan.toJson());
    if (raw.length > _maxSavedPlans) {
      raw.removeRange(_maxSavedPlans, raw.length);
    }
    await prefs.setStringList(_historyKey, raw);
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  @override
  Future<MealPlan?> readCachedPlan(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> items = prefs.getStringList(_aiCacheKey) ?? <String>[];
    for (final String raw in items) {
      try {
        final Map<String, dynamic> map = Map<String, dynamic>.from(
          _decodeMap(raw),
        );
        if (map['key']?.toString() == key) {
          final String? payload = map['plan']?.toString();
          if (payload != null && payload.isNotEmpty) {
            return MealPlan.fromJson(payload);
          }
        }
      } catch (_) {
        // Ignore malformed cache entries.
      }
    }
    return null;
  }

  @override
  Future<void> saveCachedPlan({
    required String key,
    required MealPlan plan,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> items = prefs.getStringList(_aiCacheKey) ?? <String>[];
    final List<String> cleaned = <String>[
      for (final String item in items)
        if (!_hasCacheKey(item, key)) item,
    ];
    cleaned.insert(0, _encodeMap(<String, String>{'key': key, 'plan': plan.toJson()}));
    if (cleaned.length > _maxCachedAiPlans) {
      cleaned.removeRange(_maxCachedAiPlans, cleaned.length);
    }
    await prefs.setStringList(_aiCacheKey, cleaned);
  }

  MealPlan? _safeDecode(String value) {
    try {
      return MealPlan.fromJson(value);
    } catch (_) {
      return null;
    }
  }

  bool _hasCacheKey(String raw, String key) {
    try {
      final Map<String, dynamic> map = Map<String, dynamic>.from(_decodeMap(raw));
      return map['key']?.toString() == key;
    } catch (_) {
      return false;
    }
  }

  String _encodeMap(Map<String, String> map) {
    return map.entries
        .map((MapEntry<String, String> e) => '${_escape(e.key)}=${_escape(e.value)}')
        .join('&');
  }

  Map<String, String> _decodeMap(String source) {
    final Map<String, String> out = <String, String>{};
    final List<String> parts = source.split('&');
    for (final String part in parts) {
      final int idx = part.indexOf('=');
      if (idx <= 0) {
        continue;
      }
      final String key = _unescape(part.substring(0, idx));
      final String value = _unescape(part.substring(idx + 1));
      out[key] = value;
    }
    return out;
  }

  String _escape(String input) =>
      input.replaceAll('%', '%25').replaceAll('&', '%26').replaceAll('=', '%3D');

  String _unescape(String input) =>
      input.replaceAll('%3D', '=').replaceAll('%26', '&').replaceAll('%25', '%');
}
