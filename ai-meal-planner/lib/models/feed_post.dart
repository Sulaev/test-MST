import 'dart:convert';

class FeedPost {
  FeedPost({
    required this.id,
    required this.createdAtIso,
    required this.goal,
    required this.title,
    required this.note,
    required this.recipeName,
    this.recipeUrl,
    this.recipeImageUrl,
    this.planJson,
    this.isFavorite = false,
  });

  final String id;
  final String createdAtIso;
  final String goal;
  final String title;
  final String note;
  final String recipeName;
  final String? recipeUrl;
  final String? recipeImageUrl;
  final String? planJson;
  final bool isFavorite;

  FeedPost copyWith({
    String? id,
    String? createdAtIso,
    String? goal,
    String? title,
    String? note,
    String? recipeName,
    String? recipeUrl,
    String? recipeImageUrl,
    String? planJson,
    bool? isFavorite,
  }) {
    return FeedPost(
      id: id ?? this.id,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      goal: goal ?? this.goal,
      title: title ?? this.title,
      note: note ?? this.note,
      recipeName: recipeName ?? this.recipeName,
      recipeUrl: recipeUrl ?? this.recipeUrl,
      recipeImageUrl: recipeImageUrl ?? this.recipeImageUrl,
      planJson: planJson ?? this.planJson,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'createdAtIso': createdAtIso,
      'goal': goal,
      'title': title,
      'note': note,
      'recipeName': recipeName,
      'recipeUrl': recipeUrl,
      'recipeImageUrl': recipeImageUrl,
      'planJson': planJson,
      'isFavorite': isFavorite,
    };
  }

  factory FeedPost.fromMap(Map<String, dynamic> map) {
    return FeedPost(
      id: (map['id'] ?? '').toString(),
      createdAtIso: (map['createdAtIso'] ?? DateTime.now().toIso8601String()).toString(),
      goal: (map['goal'] ?? 'health').toString(),
      title: (map['title'] ?? 'Meal idea').toString(),
      note: (map['note'] ?? '').toString(),
      recipeName: (map['recipeName'] ?? 'Recipe').toString(),
      recipeUrl: map['recipeUrl']?.toString(),
      recipeImageUrl: map['recipeImageUrl']?.toString(),
      planJson: map['planJson']?.toString(),
      isFavorite: map['isFavorite'] == true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory FeedPost.fromJson(String source) =>
      FeedPost.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
