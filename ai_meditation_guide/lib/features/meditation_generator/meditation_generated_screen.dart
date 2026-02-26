import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/app_colors.dart';
import '../../services/ai_service.dart';

class MeditationGeneratedScreen extends StatelessWidget {
  const MeditationGeneratedScreen({super.key, required this.meditation});

  final GeneratedMeditation meditation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        title: const Text('Your Meditation'),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _Cover(meditation: meditation),
                const SizedBox(height: 18),
                Text(
                  meditation.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  meditation.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      meditation.script,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: GestureDetector(
                    onTap: () => context.push('/player', extra: meditation),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: const EdgeInsets.only(left: 10, right: 4),
                      child: Row(
                        children: [
                          const SizedBox(width: 56),
                          Expanded(
                            child: Text(
                              'START',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F7FA).withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.meditation});

  final GeneratedMeditation meditation;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(28);
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius,
        ),
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (meditation.coverImageUrl != null && meditation.coverImageUrl!.isNotEmpty) {
      final url = meditation.coverImageUrl!;
      if (url.startsWith('data:image')) {
        final bytes = _tryDecodeDataUri(url);
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallback(),
          );
        }
      }
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    if (meditation.coverAssetPath != null && meditation.coverAssetPath!.isNotEmpty) {
      return Image.asset(
        meditation.coverAssetPath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return const ColoredBox(color: Colors.transparent);
  }

  Uint8List? _tryDecodeDataUri(String value) {
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

