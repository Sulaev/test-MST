import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../services/favorites_service.dart';
import '../services/logger_service.dart';
import 'favorites_screen.dart';

class AnimalDetailScreen extends StatefulWidget {
  const AnimalDetailScreen({super.key, required this.animal});

  final Animal animal;

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  late final AudioPlayer _audioPlayer;
  bool _isPlayingSound = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadFavoriteState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingSound = false);
    });
  }

  Future<void> _loadFavoriteState() async {
    final value = await FavoritesService.isFavorite(widget.animal.id);
    if (!mounted) return;
    setState(() => _isFavorite = value);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAnimalSound() async {
    final soundUrl = widget.animal.soundUrl;
    if (soundUrl == null || soundUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sound is not available for this animal yet.')),
      );
      return;
    }

    try {
      setState(() => _isPlayingSound = true);
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(soundUrl));
    } catch (e) {
      LoggerService.error('Error playing animal sound', e);
      if (!mounted) return;
      setState(() => _isPlayingSound = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not play sound right now.')),
      );
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await FavoritesService.removeFromFavorites(widget.animal.id);
      } else {
        await FavoritesService.addToFavorites(widget.animal);
      }
      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite
                ? '${widget.animal.name} added to favorites.'
                : '${widget.animal.name} removed from favorites.',
          ),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      LoggerService.error('Error adding to favorites', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add to favorites.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;

    return Scaffold(
      appBar: AppBar(title: Text(animal.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Hero(
                    tag: 'animal_image_${animal.id}',
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.asset(
                        animal.imageUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 1280,
                        filterQuality: FilterQuality.low,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.orange.withValues(alpha: 0.12),
                          child: const Center(child: Icon(Icons.pets_rounded, size: 70)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton.filled(
                      onPressed: _toggleFavorite,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.92),
                        foregroundColor: _isFavorite ? Colors.red : Colors.black87,
                      ),
                      icon: Icon(
                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      ),
                      tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    animal.name,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _playAnimalSound,
              icon: Icon(_isPlayingSound ? Icons.volume_up_rounded : Icons.play_arrow_rounded),
              label: Text(_isPlayingSound ? 'Playing...' : 'Play animal sound'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.category_rounded, size: 18),
                  label: Text(animal.category),
                ),
                Chip(
                  avatar: const Icon(Icons.place_rounded, size: 18),
                  label: Text(animal.habitat),
                ),
                Chip(
                  avatar: const Icon(Icons.restaurant_rounded, size: 18),
                  label: Text(animal.diet),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'About',
              child: Text(animal.description, style: const TextStyle(fontSize: 16, height: 1.45)),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Fun facts',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final fact in animal.facts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(fact)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
