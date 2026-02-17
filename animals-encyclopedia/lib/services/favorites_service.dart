import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animal.dart';
import 'logger_service.dart';

class FavoritesService {
  static const String _keyFavorites = 'favorites_animals';

  static Future<List<Animal>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_keyFavorites);
      
      if (favoritesJson == null) {
        return [];
      }
      
      final List<dynamic> favoritesList = json.decode(favoritesJson);
      return favoritesList
          .map((item) => Animal.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      LoggerService.error('Error loading favorites', e);
      return [];
    }
  }

  static Future<void> addToFavorites(Animal animal) async {
    try {
      final favorites = await getFavorites();
      
      // Проверяем, не добавлено ли уже
      if (favorites.any((fav) => fav.id == animal.id)) {
        LoggerService.info('Animal already in favorites: ${animal.name}');
        return;
      }
      
      favorites.add(animal);
      await _saveFavorites(favorites);
      LoggerService.info('Animal added to favorites: ${animal.name}');
    } catch (e) {
      LoggerService.error('Error adding to favorites', e);
      rethrow;
    }
  }

  static Future<void> removeFromFavorites(String animalId) async {
    try {
      final favorites = await getFavorites();
      favorites.removeWhere((animal) => animal.id == animalId);
      await _saveFavorites(favorites);
      LoggerService.info('Animal removed from favorites: $animalId');
    } catch (e) {
      LoggerService.error('Error removing from favorites', e);
      rethrow;
    }
  }

  static Future<void> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyFavorites);
      LoggerService.info('Favorites cleared');
    } catch (e) {
      LoggerService.error('Error clearing favorites', e);
      rethrow;
    }
  }

  static Future<bool> isFavorite(String animalId) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((animal) => animal.id == animalId);
    } catch (e) {
      LoggerService.error('Error checking favorite status', e);
      return false;
    }
  }

  static Future<void> _saveFavorites(List<Animal> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = json.encode(
        favorites.map((animal) => animal.toJson()).toList(),
      );
      await prefs.setString(_keyFavorites, favoritesJson);
    } catch (e) {
      LoggerService.error('Error saving favorites', e);
      rethrow;
    }
  }
}
