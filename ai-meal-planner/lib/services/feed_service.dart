import 'package:shared_preferences/shared_preferences.dart';

import '../models/feed_post.dart';
import '../models/meal_plan.dart';

class FeedService {
  static const String _feedKey = 'ai_meal_planner_local_feed_v1';
  static const int _maxPosts = 50;

  Future<List<FeedPost>> getPosts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_feedKey) ?? <String>[];
    return raw
        .map(
          (String item) {
            try {
              return FeedPost.fromJson(item);
            } catch (_) {
              return null;
            }
          },
        )
        .whereType<FeedPost>()
        .toList();
  }

  Future<void> publishFromPlan({
    required MealPlan plan,
    String note = '',
  }) async {
    final MealEntry? firstMeal = plan.days.firstOrNull?.meals.firstOrNull;
    if (firstMeal == null) {
      return;
    }
    final FeedPost post = FeedPost(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAtIso: DateTime.now().toIso8601String(),
      goal: plan.goal,
      title: '${_titleForGoal(plan.goal)}: ${firstMeal.name}',
      note: note.trim(),
      recipeName: firstMeal.name,
      recipeUrl: firstMeal.recipeUrl,
      recipeImageUrl: firstMeal.recipeImageUrl,
      planJson: plan.toJson(),
    );

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_feedKey) ?? <String>[];
    raw.insert(0, post.toJson());
    if (raw.length > _maxPosts) {
      raw.removeRange(_maxPosts, raw.length);
    }
    await prefs.setStringList(_feedKey, raw);
  }

  Future<void> toggleFavorite(String id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_feedKey) ?? <String>[];
    final List<String> updated = raw.map((String item) {
      try {
        final FeedPost post = FeedPost.fromJson(item);
        if (post.id == id) {
          return post.copyWith(isFavorite: !post.isFavorite).toJson();
        }
      } catch (_) {
        // Keep malformed entries untouched.
      }
      return item;
    }).toList();
    await prefs.setStringList(_feedKey, updated);
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_feedKey);
  }

  String _titleForGoal(String goal) {
    switch (goal) {
      case 'weight_loss':
        return 'Lean pick';
      case 'muscle_gain':
        return 'Protein pick';
      case 'maintenance_recomp':
        return 'Recomp pick';
      default:
        return 'Healthy pick';
    }
  }
}

extension<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
