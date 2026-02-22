import 'package:ai_meal_planner/models/meal_plan.dart';
import 'package:ai_meal_planner/services/feed_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('publishes post from plan and toggles favorite', () async {
    final FeedService service = FeedService();
    final MealPlan plan = MealPlan(
      createdAtIso: '2026-01-01T00:00:00.000Z',
      goal: 'health',
      dailyCalories: 2000,
      days: <MealDay>[
        MealDay(
          day: 'Day 1',
          meals: <MealEntry>[
            MealEntry(
              type: 'Breakfast',
              name: 'Greek yogurt bowl',
              calories: 480,
              notes: 'High protein',
              recipeUrl: 'https://example.com',
            ),
          ],
        ),
      ],
      shoppingList: <String>['Yogurt'],
      tips: <String>['Hydrate'],
    );

    await service.publishFromPlan(plan: plan, note: 'Great idea');
    final posts = await service.getPosts();
    expect(posts, hasLength(1));
    expect(posts.first.goal, 'health');
    expect(posts.first.isFavorite, isFalse);

    await service.toggleFavorite(posts.first.id);
    final updated = await service.getPosts();
    expect(updated.first.isFavorite, isTrue);
  });
}
