import 'package:ai_meal_planner/models/meal_plan.dart';
import 'package:ai_meal_planner/services/ai_remote_meal_planner_service.dart';
import 'package:ai_meal_planner/services/free_meal_planner_service.dart';
import 'package:ai_meal_planner/services/planner_generation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ai mode uses cache on second identical request', () async {
    final _FakeAiService ai = _FakeAiService();
    final _FakeFreeService free = _FakeFreeService();
    final _InMemoryCache cache = _InMemoryCache();
    final PlannerGenerationService service = PlannerGenerationService(
      aiService: ai,
      freeService: free,
      cacheStore: cache,
    );

    final PlannerGenerateResult first = await service.generate(
      mode: PlannerMode.ai,
      goal: 'health',
      dailyCalories: 2000,
      days: 2,
      allergies: 'none',
      preferences: 'quick',
    );
    final PlannerGenerateResult second = await service.generate(
      mode: PlannerMode.ai,
      goal: 'health',
      dailyCalories: 2000,
      days: 2,
      allergies: 'none',
      preferences: 'quick',
    );

    expect(first.fromCache, isFalse);
    expect(second.fromCache, isTrue);
    expect(second.usedFallback, isFalse);
    expect(ai.calls, 1);
  });

  test('ai failure falls back to deterministic planner', () async {
    final _FakeAiService ai = _FakeAiService(throwOnCall: true);
    final _FakeFreeService free = _FakeFreeService();
    final _InMemoryCache cache = _InMemoryCache();
    final PlannerGenerationService service = PlannerGenerationService(
      aiService: ai,
      freeService: free,
      cacheStore: cache,
    );

    final PlannerGenerateResult result = await service.generate(
      mode: PlannerMode.ai,
      goal: 'weight_loss',
      dailyCalories: 1900,
      days: 1,
      allergies: '',
      preferences: '',
    );

    expect(result.usedFallback, isTrue);
    expect(result.plan.goal, 'weight_loss');
    expect(free.calls, 1);
  });
}

class _InMemoryCache implements AiPlanCacheStore {
  final Map<String, MealPlan> _store = <String, MealPlan>{};

  @override
  Future<MealPlan?> readCachedPlan(String key) async => _store[key];

  @override
  Future<void> saveCachedPlan({required String key, required MealPlan plan}) async {
    _store[key] = plan;
  }
}

class _FakeAiService extends AiRemoteMealPlannerService {
  _FakeAiService({this.throwOnCall = false});

  final bool throwOnCall;
  int calls = 0;

  @override
  Future<MealPlan> generatePlan({
    required String goal,
    required int dailyCalories,
    required int days,
    required String allergies,
    required String preferences,
  }) async {
    calls += 1;
    if (throwOnCall) {
      throw const AiPlannerException('forced failure');
    }
    return _samplePlan(goal: goal, dailyCalories: dailyCalories);
  }
}

class _FakeFreeService extends FreeMealPlannerService {
  int calls = 0;

  @override
  Future<MealPlan> generatePlan({
    required String goal,
    required int dailyCalories,
    required int days,
    required String allergies,
    required String preferences,
  }) async {
    calls += 1;
    return _samplePlan(goal: goal, dailyCalories: dailyCalories);
  }
}

MealPlan _samplePlan({required String goal, required int dailyCalories}) {
  return MealPlan(
    createdAtIso: '2026-01-01T00:00:00.000Z',
    goal: goal,
    dailyCalories: dailyCalories,
    days: <MealDay>[
      MealDay(
        day: 'Day 1',
        meals: <MealEntry>[
          MealEntry(type: 'Breakfast', name: 'Oats', calories: 500, notes: 'notes'),
        ],
      ),
    ],
    shoppingList: <String>['Oats'],
    tips: <String>['Tip'],
  );
}
