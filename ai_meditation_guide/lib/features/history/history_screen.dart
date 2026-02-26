import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/app_colors.dart';
import '../../services/meditation_library_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<SavedMeditationEntry>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = MeditationLibraryService.instance.getAll();
  }

  Future<void> _reload() async {
    setState(() {
      _itemsFuture = MeditationLibraryService.instance.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.goNamed('home'),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
        title: const Text('History'),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              ToggleButtons(
                isSelected: const [true, false],
                borderRadius: BorderRadius.circular(999),
                constraints: const BoxConstraints(minWidth: 120, minHeight: 36),
                children: const [
                  Text('Meditations'),
                  Text('Breathing'),
                ],
                onPressed: (_) {},
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<SavedMeditationEntry>>(
                  future: _itemsFuture,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? const <SavedMeditationEntry>[];
                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                          'No saved meditations yet.\nTap heart in player to save.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final meditation = item.meditation;
                        return Container(
                          height: 88,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => context.push('/player', extra: meditation),
                                  child: Row(
                                    children: [
                                      _HistoryCoverThumb(meditation: meditation),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${meditation.durationMinutes} MINUTES',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              meditation.description.isNotEmpty
                                                  ? meditation.description
                                                  : meditation.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF666666),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await MeditationLibraryService.instance.remove(item.id);
                                  await _reload();
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCoverThumb extends StatelessWidget {
  const _HistoryCoverThumb({required this.meditation});

  final dynamic meditation;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${meditation.durationMinutes} MIN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = (meditation.coverImageUrl ?? '').toString();
    if (url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        final bytes = _decodeDataUri(url);
        if (bytes != null) {
          return Image.memory(bytes, fit: BoxFit.cover);
        }
      }
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    final asset = (meditation.coverAssetPath ?? '').toString();
    if (asset.isNotEmpty) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6AA5FF), Color(0xFF84D0B5)],
        ),
      ),
    );
  }

  Uint8List? _decodeDataUri(String value) {
    final comma = value.indexOf(',');
    if (comma < 0) return null;
    final payload = value.substring(comma + 1).trim();
    if (payload.isEmpty) return null;
    try {
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }
}

