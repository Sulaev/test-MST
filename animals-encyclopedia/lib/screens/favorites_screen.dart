import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../services/favorites_service.dart';
import '../services/logger_service.dart';
import 'animal_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Animal> _favorites = <Animal>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final favorites = await FavoritesService.getFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      LoggerService.error('Error loading favorites', e);
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(Animal animal) async {
    await FavoritesService.removeFromFavorites(animal.id);
    await _loadFavorites();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${animal.name} removed from favorites.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await FavoritesService.addToFavorites(animal);
            await _loadFavorites();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          if (_favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () async {
                await FavoritesService.clearFavorites();
                await _loadFavorites();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? const Center(
                  child: Text(
                    'No favorites yet.\nOpen any animal and tap Add favorite.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final animal = _favorites[index];
                    return Dismissible(
                      key: ValueKey(animal.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 18),
                        color: Colors.red,
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      onDismissed: (_) => _removeFavorite(animal),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 54,
                              height: 54,
                              child: Image.asset(
                                animal.imageUrl,
                                fit: BoxFit.cover,
                                cacheWidth: 180,
                                filterQuality: FilterQuality.low,
                                gaplessPlayback: true,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.pink.withValues(alpha: 0.12),
                                  child: const Icon(Icons.favorite_rounded),
                                ),
                              ),
                            ),
                          ),
                          title: Text(animal.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${animal.category} - ${animal.habitat}'),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AnimalDetailScreen(animal: animal)),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
