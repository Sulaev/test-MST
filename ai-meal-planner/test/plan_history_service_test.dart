import 'package:ai_meal_planner/models/meal_plan.dart';
import 'package:ai_meal_planner/services/plan_history_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stores and reads ai cached plan by key', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final PlanHistoryService service = PlanHistoryService();
    final MealPlan plan = MealPlan(
      createdAtIso: '2026-01-01T00:00:00.000Z',
      goal: 'health',
      dailyCalories: 2000,
      days: <MealDay>[
        MealDay(
          day: 'Day 1',
          meals: <MealEntry>[
            MealEntry(type: 'Breakfast', name: 'Oats', calories: 500, notes: 'n'),
          ],
        ),
      ],
      shoppingList: <String>['Oats'],
      tips: <String>['Hydrate'],
    );

    await service.saveCachedPlan(key: 'sample-key', plan: plan);
    final MealPlan? loaded = await service.readCachedPlan('sample-key');

    expect(loaded, isNotNull);
    expect(loaded!.goal, 'health');
    expect(loaded.days.first.meals.first.name, 'Oats');
  });
}
