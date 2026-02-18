import '../models/meal_plan.dart';
import 'ai_remote_meal_planner_service.dart';
import 'free_meal_planner_service.dart';

enum PlannerMode {
  ai,
  deterministic,
}

abstract class AiPlanCacheStore {
  Future<MealPlan?> readCachedPlan(String key);
  Future<void> saveCachedPlan({
    required String key,
    required MealPlan plan,
  });
}

class PlannerGenerateResult {
  PlannerGenerateResult({
    required this.plan,
    required this.fromCache,
    required this.usedFallback,
  });

  final MealPlan plan;
  final bool fromCache;
  final bool usedFallback;
}

class PlannerGenerationService {
  PlannerGenerationService({
    required AiRemoteMealPlannerService aiService,
    required FreeMealPlannerService freeService,
    required AiPlanCacheStore cacheStore,
  })  : _aiService = aiService,
        _freeService = freeService,
        _cacheStore = cacheStore;

  final AiRemoteMealPlannerService _aiService;
  final FreeMealPlannerService _freeService;
  final AiPlanCacheStore _cacheStore;

  Future<PlannerGenerateResult> generate({
    required PlannerMode mode,
    required String goal,
    required int dailyCalories,
    required int days,
    required String allergies,
    required String preferences,
  }) async {
    if (mode == PlannerMode.deterministic) {
      final MealPlan plan = await _freeService.generatePlan(
        goal: goal,
        dailyCalories: dailyCalories,
        days: days,
        allergies: allergies,
        preferences: preferences,
      );
      return PlannerGenerateResult(plan: plan, fromCache: false, usedFallback: false);
    }

    final String cacheKey = _buildCacheKey(
      goal: goal,
      dailyCalories: dailyCalories,
      days: days,
      allergies: allergies,
      preferences: preferences,
    );
    final MealPlan? cached = await _cacheStore.readCachedPlan(cacheKey);
    if (cached != null) {
      return PlannerGenerateResult(plan: cached, fromCache: true, usedFallback: false);
    }

    try {
      final MealPlan plan = await _aiService.generatePlan(
        goal: goal,
        dailyCalories: dailyCalories,
        days: days,
        allergies: allergies,
        preferences: preferences,
      );
      await _cacheStore.saveCachedPlan(key: cacheKey, plan: plan);
      return PlannerGenerateResult(plan: plan, fromCache: false, usedFallback: false);
    } catch (_) {
      final MealPlan fallback = await _freeService.generatePlan(
        goal: goal,
        dailyCalories: dailyCalories,
        days: days,
        allergies: allergies,
        preferences: preferences,
      );
      return PlannerGenerateResult(plan: fallback, fromCache: false, usedFallback: true);
    }
  }

  String _buildCacheKey({
    required String goal,
    required int dailyCalories,
    required int days,
    required String allergies,
    required String preferences,
  }) {
    final String normalized = <String>[
      'v1',
      goal.trim().toLowerCase(),
      dailyCalories.toString(),
      days.toString(),
      allergies.trim().toLowerCase(),
      preferences.trim().toLowerCase(),
    ].join('|');

    int hash = 17;
    for (final int unit in normalized.codeUnits) {
      hash = 37 * hash + unit;
    }
    return 'ai_${hash.abs()}';
  }
}
