import 'dart:convert';

import 'package:ai_meal_planner/services/ai_remote_meal_planner_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('retries once and succeeds on second attempt', () async {
    int calls = 0;
    final MockClient client = MockClient((http.Request request) async {
      calls += 1;
      if (calls == 1) {
        return http.Response('temporary failure', 500);
      }
      final String planJson = jsonEncode(<String, dynamic>{
        'goal': 'health',
        'dailyCalories': 2000,
        'days': <Map<String, dynamic>>[
          <String, dynamic>{
            'day': 'Day 1',
            'meals': <Map<String, dynamic>>[
              <String, dynamic>{
                'type': 'Breakfast',
                'name': 'Oats',
                'calories': 500,
                'notes': 'ok',
              },
            ],
          },
        ],
        'shoppingList': <String>['Oats'],
        'tips': <String>['Hydrate'],
      });
      return http.Response(
        jsonEncode(<String, dynamic>{
          'choices': <Map<String, dynamic>>[
            <String, dynamic>{
              'message': <String, dynamic>{'content': planJson},
            },
          ],
        }),
        200,
      );
    });

    final AiRemoteMealPlannerService service = AiRemoteMealPlannerService(client: client);
    final result = await service.generatePlan(
      goal: 'health',
      dailyCalories: 2000,
      days: 1,
      allergies: '',
      preferences: '',
    );

    expect(calls, 2);
    expect(result.goal, 'health');
    expect(result.days, isNotEmpty);
  });

  test('throws on invalid ai json', () async {
    final MockClient client = MockClient((http.Request request) async {
      return http.Response(
        jsonEncode(<String, dynamic>{
          'choices': <Map<String, dynamic>>[
            <String, dynamic>{
              'message': <String, dynamic>{'content': 'not-json'},
            },
          ],
        }),
        200,
      );
    });

    final AiRemoteMealPlannerService service = AiRemoteMealPlannerService(client: client);
    expect(
      () => service.generatePlan(
        goal: 'health',
        dailyCalories: 2000,
        days: 1,
        allergies: '',
        preferences: '',
      ),
      throwsA(isA<AiPlannerException>()),
    );
  });
}
