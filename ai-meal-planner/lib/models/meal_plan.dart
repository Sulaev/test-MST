import 'dart:convert';

class MealPlan {
  MealPlan({
    required this.createdAtIso,
    required this.goal,
    required this.dailyCalories,
    required this.days,
    required this.shoppingList,
    required this.tips,
  });

  final String createdAtIso;
  final String goal;
  final int dailyCalories;
  final List<MealDay> days;
  final List<String> shoppingList;
  final List<String> tips;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'createdAtIso': createdAtIso,
      'goal': goal,
      'dailyCalories': dailyCalories,
      'days': days.map((MealDay d) => d.toMap()).toList(),
      'shoppingList': shoppingList,
      'tips': tips,
    };
  }

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      createdAtIso: (map['createdAtIso'] ?? DateTime.now().toIso8601String()).toString(),
      goal: (map['goal'] ?? 'health').toString(),
      dailyCalories: (map['dailyCalories'] as num?)?.toInt() ?? 2000,
      days: ((map['days'] as List<dynamic>?) ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(MealDay.fromMap)
          .toList(),
      shoppingList: ((map['shoppingList'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(),
      tips: ((map['tips'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory MealPlan.fromJson(String source) =>
      MealPlan.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class MealDay {
  MealDay({
    required this.day,
    required this.meals,
  });

  final String day;
  final List<MealEntry> meals;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'day': day,
      'meals': meals.map((MealEntry m) => m.toMap()).toList(),
    };
  }

  factory MealDay.fromMap(Map<String, dynamic> map) {
    return MealDay(
      day: (map['day'] ?? 'Day').toString(),
      meals: ((map['meals'] as List<dynamic>?) ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(MealEntry.fromMap)
          .toList(),
    );
  }
}

class MealEntry {
  MealEntry({
    required this.type,
    required this.name,
    required this.calories,
    required this.notes,
    this.recipeUrl,
    this.recipeImageUrl,
  });

  final String type;
  final String name;
  final int calories;
  final String notes;
  final String? recipeUrl;
  final String? recipeImageUrl;

  MealEntry copyWith({
    String? type,
    String? name,
    int? calories,
    String? notes,
    String? recipeUrl,
    String? recipeImageUrl,
  }) {
    return MealEntry(
      type: type ?? this.type,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      notes: notes ?? this.notes,
      recipeUrl: recipeUrl ?? this.recipeUrl,
      recipeImageUrl: recipeImageUrl ?? this.recipeImageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type,
      'name': name,
      'calories': calories,
      'notes': notes,
      'recipeUrl': recipeUrl,
      'recipeImageUrl': recipeImageUrl,
    };
  }

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      type: (map['type'] ?? 'Meal').toString(),
      name: (map['name'] ?? 'Unnamed').toString(),
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      notes: (map['notes'] ?? '').toString(),
      recipeUrl: map['recipeUrl']?.toString(),
      recipeImageUrl: map['recipeImageUrl']?.toString(),
    );
  }
}
