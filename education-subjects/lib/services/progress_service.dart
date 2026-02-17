import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'education_service.dart';
import 'logger_service.dart';

class ProgressService {
  static const String _keyProgress = 'education_progress_v1';

  static Map<String, dynamic> _emptySubjectStats() {
    return <String, dynamic>{
      'correct': 0,
      'total': 0,
      'quizzes': 0,
    };
  }

  static Map<String, Map<String, int>> _normalize(Map<String, dynamic> source) {
    final normalized = <String, Map<String, int>>{};

    for (final subject in EducationService.getSubjects()) {
      final raw = source[subject];
      if (raw is Map) {
        normalized[subject] = <String, int>{
          'correct': (raw['correct'] as num?)?.toInt() ?? 0,
          'total': (raw['total'] as num?)?.toInt() ?? 0,
          'quizzes': (raw['quizzes'] as num?)?.toInt() ?? 0,
        };
      } else {
        normalized[subject] = <String, int>{
          'correct': 0,
          'total': 0,
          'quizzes': 0,
        };
      }
    }

    return normalized;
  }

  static Future<Map<String, Map<String, int>>> getProgressStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyProgress);

      if (raw == null || raw.isEmpty) {
        return _normalize(<String, dynamic>{});
      }

      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) {
        return _normalize(<String, dynamic>{});
      }

      return _normalize(decoded);
    } catch (e) {
      LoggerService.error('Error loading progress stats', e);
      return _normalize(<String, dynamic>{});
    }
  }

  static Future<void> recordQuizAttempt({
    required Map<String, int> correctBySubject,
    required Map<String, int> totalBySubject,
  }) async {
    try {
      final stats = await getProgressStats();

      for (final subject in EducationService.getSubjects()) {
        final total = totalBySubject[subject] ?? 0;
        if (total <= 0) continue;

        final correct = correctBySubject[subject] ?? 0;
        final current = stats[subject] ?? _emptySubjectStats().cast<String, int>();

        stats[subject] = <String, int>{
          'correct': (current['correct'] ?? 0) + correct,
          'total': (current['total'] ?? 0) + total,
          'quizzes': (current['quizzes'] ?? 0) + 1,
        };
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyProgress, json.encode(stats));
      LoggerService.info('Progress stats updated');
    } catch (e) {
      LoggerService.error('Error saving progress stats', e);
      rethrow;
    }
  }
}
