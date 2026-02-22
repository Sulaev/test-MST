import 'dart:convert';

import 'package:http/http.dart' as http;

class RecipeLookupService {
  RecipeLookupService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<RecipeMatch?> findRecipe(String query) async {
    if (query.trim().isEmpty) {
      return null;
    }

    final Uri uri = Uri.parse(
      'https://www.themealdb.com/api/json/v1/1/search.php?s=${Uri.encodeQueryComponent(query)}',
    );

    final http.Response response = await _client.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final Map<String, dynamic> map = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> meals = (map['meals'] as List<dynamic>?) ?? <dynamic>[];
    if (meals.isEmpty || meals.first is! Map<String, dynamic>) {
      return null;
    }
    final Map<String, dynamic> first = meals.first as Map<String, dynamic>;
    final String source = (first['strSource'] ?? first['strYoutube'] ?? '').toString();

    return RecipeMatch(
      title: (first['strMeal'] ?? query).toString(),
      imageUrl: first['strMealThumb']?.toString(),
      sourceUrl: source.isEmpty ? null : source,
    );
  }
}

class RecipeMatch {
  RecipeMatch({
    required this.title,
    this.imageUrl,
    this.sourceUrl,
  });

  final String title;
  final String? imageUrl;
  final String? sourceUrl;
}
