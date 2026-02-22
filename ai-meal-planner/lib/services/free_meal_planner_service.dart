import '../models/meal_plan.dart';

class FreeMealPlannerService {
  Future<MealPlan> generatePlan({
    required String goal,
    required int dailyCalories,
    required int days,
    required String allergies,
    required String preferences,
  }) async {
    final List<String> allergyTokens = _tokenize(allergies);
    final List<String> preferenceTokens = _tokenize(preferences);
    final List<_MealTemplate> templates = _buildTemplates(goal);

    final List<_MealTemplate> filtered = templates.where((_MealTemplate template) {
      // Keep deterministic behavior and simple safety: skip meals containing allergy tokens.
      final String haystack = '${template.name} ${template.notes}'.toLowerCase();
      return !allergyTokens.any((String token) => haystack.contains(token));
    }).toList();

    final List<_MealTemplate> source = filtered.isEmpty ? templates : filtered;
    final int seed = _stableSeed('$goal|$dailyCalories|$days|$allergies|$preferences');
    final int dayCalories = dailyCalories.clamp(900, 5000);
    final List<MealDay> planDays = <MealDay>[];

    for (int dayIndex = 0; dayIndex < days; dayIndex++) {
      final int offset = (seed + dayIndex * 3) % source.length;
      final _MealTemplate breakfast = source[offset % source.length];
      final _MealTemplate lunch = source[(offset + 1) % source.length];
      final _MealTemplate dinner = source[(offset + 2) % source.length];
      final _MealTemplate snack = source[(offset + 3) % source.length];
      final int breakfastCalories = (dayCalories * 0.28).round();
      final int lunchCalories = (dayCalories * 0.34).round();
      final int dinnerCalories = (dayCalories * 0.28).round();
      final int snackCalories = dayCalories - breakfastCalories - lunchCalories - dinnerCalories;

      final List<MealEntry> entries = <MealEntry>[
        _toEntry('Breakfast', breakfast, breakfastCalories, preferenceTokens),
        _toEntry('Lunch', lunch, lunchCalories, preferenceTokens),
        _toEntry('Dinner', dinner, dinnerCalories, preferenceTokens),
        _toEntry('Snack', snack, snackCalories, preferenceTokens),
      ];

      planDays.add(
        MealDay(
          day: 'Day ${dayIndex + 1}',
          meals: entries,
        ),
      );
    }

    final Set<String> shopping = <String>{};
    for (final MealDay day in planDays) {
      for (final MealEntry meal in day.meals) {
        shopping.add(meal.name);
      }
    }

    return MealPlan(
      createdAtIso: DateTime.now().toIso8601String(),
      goal: goal,
      dailyCalories: dayCalories,
      days: planDays,
      shoppingList: shopping.toList()..sort(),
      tips: _tipsFor(goal, preferenceTokens),
    );
  }

  List<_MealTemplate> _buildTemplates(String goal) {
    if (goal == 'muscle_gain') {
      return const <_MealTemplate>[
        _MealTemplate('Oatmeal with banana and peanut butter', 'Complex carbs and protein.'),
        _MealTemplate('Chicken rice bowl', 'Add vegetables and olive oil.'),
        _MealTemplate('Salmon with quinoa', 'High-quality protein and omega-3.'),
        _MealTemplate('Greek yogurt with berries', 'Fast snack with protein.'),
        _MealTemplate('Turkey whole-grain sandwich', 'Portable balanced meal.'),
        _MealTemplate('Egg scramble with toast', 'Protein-focused breakfast.'),
      ];
    }
    if (goal == 'weight_loss') {
      return const <_MealTemplate>[
        _MealTemplate('Egg white omelet with spinach', 'Low-calorie and filling.'),
        _MealTemplate('Grilled chicken salad', 'Lean protein and fiber.'),
        _MealTemplate('Baked fish with steamed vegetables', 'Light dinner option.'),
        _MealTemplate('Apple with cottage cheese', 'Simple controlled snack.'),
        _MealTemplate('Vegetable soup with beans', 'Volume eating strategy.'),
        _MealTemplate('Turkey lettuce wraps', 'Low-carb high-protein meal.'),
      ];
    }
    return const <_MealTemplate>[
      _MealTemplate('Yogurt bowl with fruit and oats', 'Balanced breakfast.'),
      _MealTemplate('Chicken pasta with vegetables', 'Steady energy meal.'),
      _MealTemplate('Beef stir-fry with rice', 'Balanced macros for maintenance.'),
      _MealTemplate('Hummus with carrots', 'Snack with fiber.'),
      _MealTemplate('Lentil curry with rice', 'Plant-based protein option.'),
      _MealTemplate('Tuna salad wrap', 'Quick practical meal.'),
    ];
  }

  MealEntry _toEntry(String type, _MealTemplate template, int calories, List<String> preferences) {
    String notes = template.notes;
    if (preferences.isNotEmpty) {
      notes = '$notes Pref: ${preferences.join(", ")}.';
    }
    return MealEntry(
      type: type,
      name: template.name,
      calories: calories,
      notes: notes,
    );
  }

  List<String> _tipsFor(String goal, List<String> preferences) {
    final List<String> tips = <String>[
      'Drink water consistently during the day.',
      'Prepare meals in batches to reduce missed meals.',
    ];
    if (goal == 'weight_loss') {
      tips.add('Prioritize high-volume foods (vegetables, soups, salads).');
    } else if (goal == 'muscle_gain') {
      tips.add('Keep protein in every meal and snack.');
    } else {
      tips.add('Aim for a consistent meal schedule for energy stability.');
    }
    if (preferences.isNotEmpty) {
      tips.add('Preference filters used: ${preferences.join(", ")}.');
    }
    return tips;
  }

  List<String> _tokenize(String raw) {
    return raw
        .toLowerCase()
        .split(RegExp(r'[,;\s]+'))
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
  }

  int _stableSeed(String text) {
    int hash = 17;
    for (final int unit in text.codeUnits) {
      hash = 37 * hash + unit;
    }
    return hash.abs();
  }
}

class _MealTemplate {
  const _MealTemplate(this.name, this.notes);

  final String name;
  final String notes;
}
