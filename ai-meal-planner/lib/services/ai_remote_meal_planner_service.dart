import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/meal_plan.dart';

class AiRemoteMealPlannerService {
  AiRemoteMealPlannerService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<MealPlan> generatePlan({
    required String goal,
    required int dailyCalories,
    required int days,
    required String allergies,
    required String preferences,
  }) async {
    final String prompt = '''
You are a nutrition planner. Return ONLY JSON object.
Goal: $goal
Daily calories: $dailyCalories
Days: $days
Allergies: ${allergies.isEmpty ? "none" : allergies}
Preferences: ${preferences.isEmpty ? "none" : preferences}

Rules:
- 3 main meals and 1 snack per day
- Calories per day close to target (+/- 120)
- Practical meals

Schema:
{
  "goal": "string",
  "dailyCalories": number,
  "days": [
    {
      "day": "Day 1",
      "meals": [
        {"type":"Breakfast","name":"string","calories":number,"notes":"string"}
      ]
    }
  ],
  "shoppingList": ["string"],
  "tips": ["string"]
}
''';

    final Map<String, dynamic> body = <String, dynamic>{
      'model': 'openai-fast',
      'temperature': 0,
      'messages': <Map<String, String>>[
        <String, String>{
          'role': 'system',
          'content': 'Always output valid JSON object only without markdown.',
        },
        <String, String>{'role': 'user', 'content': prompt},
      ],
      'response_format': <String, dynamic>{'type': 'json_object'},
    };

    Map<String, dynamic> payload;
    try {
      payload = await _postWithRetry(body);
    } on TimeoutException {
      throw const AiPlannerException(
        'AI timeout. Network is slow or service is overloaded.',
      );
    } on AiPlannerException {
      rethrow;
    } catch (_) {
      throw const AiPlannerException('AI service is temporarily unavailable.');
    }

    final String? content = (((payload['choices'] as List<dynamic>?)?.firstOrNull
                as Map<String, dynamic>?)?['message']
            as Map<String, dynamic>?)?['content']
        ?.toString();
    if (content == null || content.isEmpty) {
      throw const AiPlannerException('AI returned empty content.');
    }

    final String jsonText = _extractJson(content);
    try {
      final Map<String, dynamic> raw = jsonDecode(jsonText) as Map<String, dynamic>;
      raw['createdAtIso'] = DateTime.now().toIso8601String();
      return MealPlan.fromMap(raw);
    } catch (_) {
      throw const AiPlannerException('AI returned invalid JSON format.');
    }
  }

  Future<Map<String, dynamic>> _postWithRetry(Map<String, dynamic> body) async {
    const int maxAttempts = 2;
    Object? lastError;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final http.Response response = await _client
            .post(
              Uri.parse('https://text.pollinations.ai/openai'),
              headers: const <String, String>{'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 35));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }

        if (response.statusCode == 429 || response.statusCode >= 500) {
          lastError = AiPlannerException(
            'AI overloaded (HTTP ${response.statusCode}).',
          );
          if (attempt < maxAttempts) {
            await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
            continue;
          }
        }

        throw AiPlannerException('AI request failed (HTTP ${response.statusCode}).');
      } on TimeoutException catch (e) {
        lastError = e;
        if (attempt < maxAttempts) {
          await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
          continue;
        }
      } on AiPlannerException catch (e) {
        lastError = e;
        if (attempt < maxAttempts &&
            (e.message.contains('overloaded') || e.message.contains('HTTP 5'))) {
          await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
          continue;
        }
      } catch (e) {
        lastError = e;
      }
      break;
    }

    if (lastError is AiPlannerException) {
      throw lastError;
    }
    if (lastError is TimeoutException) {
      throw lastError;
    }
    throw const AiPlannerException('Unknown AI request error.');
  }

  String _extractJson(String source) {
    final String trimmed = source.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }
    final int start = trimmed.indexOf('{');
    final int end = trimmed.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return trimmed.substring(start, end + 1);
    }
    throw const AiPlannerException('Could not locate JSON object in AI response.');
  }
}

class AiPlannerException implements Exception {
  const AiPlannerException(this.message);

  final String message;

  @override
  String toString() => message;
}

extension<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
