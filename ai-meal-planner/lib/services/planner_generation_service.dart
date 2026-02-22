import '../models/meal_plan.dart';
import '../models/generation_stage.dart';
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
    void Function(GenerationProgress progress)? onProgress,
  }) async {
    _emit(
      onProgress,
      const GenerationProgress(
        stage: GenerationStage.validatingInput,
        message: 'Checking input parameters...',
        percent: 0.08,
      ),
    );

    if (mode == PlannerMode.deterministic) {
      _emit(
        onProgress,
        const GenerationProgress(
          stage: GenerationStage.generatingLocal,
          message: 'Generating a local plan...',
          percent: 0.35,
        ),
      );
      final MealPlan plan = await _freeService.generatePlan(
        goal: goal,
        dailyCalories: dailyCalories,
        days: days,
        allergies: allergies,
        preferences: preferences,
      );
      _emit(
        onProgress,
        const GenerationProgress(
          stage: GenerationStage.completed,
          message: 'Plan generated successfully.',
          percent: 1,
        ),
      );
      return PlannerGenerateResult(plan: plan, fromCache: false, usedFallback: false);
    }

    _emit(
      onProgress,
      const GenerationProgress(
        stage: GenerationStage.checkingCache,
        message: 'Checking cached AI response...',
        percent: 0.2,
      ),
    );
    final String cacheKey = _buildCacheKey(
      goal: goal,
      dailyCalories: dailyCalories,
      days: days,
      allergies: allergies,
      preferences: preferences,
    );
    final MealPlan? cached = await _cacheStore.readCachedPlan(cacheKey);
    if (cached != null) {
      _emit(
        onProgress,
        const GenerationProgress(
          stage: GenerationStage.completed,
          message: 'Loaded plan from cache.',
          percent: 1,
        ),
      );
      return PlannerGenerateResult(plan: cached, fromCache: true, usedFallback: false);
    }

    try {
      _emit(
        onProgress,
        const GenerationProgress(
          stage: GenerationStage.requestingAi,
          message: 'Requesting AI plan...',
          percent: 0.45,
        ),
      );
      final MealPlan plan = await _aiService.generatePlan(
        goal: goal,
        dailyCalories: dailyCalories,
        days: days,
        allergies: allergies,
        preferences: preferences,
      );
      await _cacheStore.saveCachedPlan(key: cacheKey, plan: plan);
      _emit(
        onProgress,
        const GenerationProgress(
          stage: GenerationStage.completed,
          message: 'AI plan generated successfully.',
          percent: 1,
        ),
      );
      return PlannerGenerateResult(plan: plan, fromCache: false, usedFallback: false);
    } catch (_) {
      _emit(
        onProgress,
        const GenerationProgress(
          stage: GenerationStage.generatingLocal,
          message: 'AI unavailable. Switching to local fallback...',
          percent: 0.62,
        ),
      );
      final MealPlan fallback = await _freeService.generatePlan(
        goal: goal,
        dailyCalories: dailyCalories,
        days: days,
        allergies: allergies,
        preferences: preferences,
      );
      _emit(
        onProgress,
        const GenerationProgress(
          stage: GenerationStage.completed,
          message: 'Fallback plan generated successfully.',
          percent: 1,
        ),
      );
      return PlannerGenerateResult(plan: fallback, fromCache: false, usedFallback: true);
    }
  }

  void _emit(
    void Function(GenerationProgress progress)? onProgress,
    GenerationProgress progress,
  ) {
    if (onProgress != null) {
      onProgress(progress);
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
