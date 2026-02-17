import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../services/animals_service.dart';
import '../services/logger_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Random _random = Random();
  late final AudioPlayer _audioPlayer;

  late List<_Round> _rounds;
  int _index = 0;
  int _score = 0;
  bool _locked = false;
  bool _isPlayingSound = false;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingSound = false);
    });
    _buildRounds();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _buildRounds() {
    final all = AnimalsService.getAllAnimals();
    all.shuffle(_random);

    final rounds = <_Round>[];

    final imageCandidates = all.take(min(6, all.length)).toList();
    for (final correct in imageCandidates) {
      final others = all.where((a) => a.id != correct.id).toList()..shuffle(_random);
      final options = <Animal>[correct, ...others.take(3)]..shuffle(_random);
      rounds.add(
        _Round(
          question: 'Tap the image of: ${correct.name}',
          correctId: correct.id,
          options: options,
          isSoundRound: false,
        ),
      );
    }

    final soundCandidates = all.where((a) => (a.soundUrl ?? '').isNotEmpty).toList()..shuffle(_random);
    for (final correct in soundCandidates.take(min(2, soundCandidates.length))) {
      final others = all.where((a) => a.id != correct.id).toList()..shuffle(_random);
      final options = <Animal>[correct, ...others.take(3)]..shuffle(_random);
      rounds.add(
        _Round(
          question: 'Listen and tap the correct animal image',
          correctId: correct.id,
          options: options,
          isSoundRound: true,
          soundAssetPath: correct.soundUrl,
        ),
      );
    }

    rounds.shuffle(_random);

    _rounds = rounds;
    _index = 0;
    _score = 0;
    _locked = false;
    _selectedId = null;
    _isPlayingSound = false;
  }

  Future<void> _playRoundSound() async {
    final round = _rounds[_index];
    final path = round.soundAssetPath;
    if (!round.isSoundRound || path == null || path.isEmpty) {
      return;
    }

    try {
      setState(() => _isPlayingSound = true);
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(path));
    } catch (e) {
      LoggerService.error('Error playing quiz sound', e);
      if (!mounted) return;
      setState(() => _isPlayingSound = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not play this sound.')),
      );
    }
  }

  Future<void> _stopRoundSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      LoggerService.error('Error stopping quiz sound', e);
    } finally {
      if (mounted) {
        setState(() => _isPlayingSound = false);
      }
    }
  }

  Future<void> _answer(String animalId) async {
    if (_locked) return;
    await _stopRoundSound();

    final round = _rounds[_index];
    final isCorrect = animalId == round.correctId;

    setState(() {
      _locked = true;
      _selectedId = animalId;
      if (isCorrect) _score++;
    });
  }

  Future<void> _next() async {
    await _stopRoundSound();
    if (_index < _rounds.length - 1) {
      setState(() {
        _index++;
        _locked = false;
        _selectedId = null;
        _isPlayingSound = false;
      });
      return;
    }

    _showResult();
  }

  void _showResult() {
    final percent = ((_score / _rounds.length) * 100).round();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz finished!'),
        content: Text('Score: $_score of ${_rounds.length}\nResult: $percent%'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(_buildRounds);
            },
            child: const Text('Play again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_index];

    return Scaffold(
      appBar: AppBar(title: const Text('Animal Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Round ${_index + 1}/${_rounds.length}'),
                        const Spacer(),
                        Text('Score: $_score'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: (_index + 1) / _rounds.length),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              round.question,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            if (round.isSoundRound) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _playRoundSound,
                icon: Icon(_isPlayingSound ? Icons.volume_up_rounded : Icons.play_arrow_rounded),
                label: Text(_isPlayingSound ? 'Playing...' : 'Play sound'),
              ),
            ],
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                itemCount: round.options.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, i) {
                  final animal = round.options[i];
                  final isSelected = _selectedId == animal.id;
                  final isCorrect = animal.id == round.correctId;

                  Color borderColor = Colors.transparent;
                  if (_locked && isCorrect) borderColor = Colors.green;
                  if (_locked && isSelected && !isCorrect) borderColor = Colors.red;

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async => _answer(animal.id),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 3),
                        color: Colors.white,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.asset(
                          animal.imageUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 720,
                          filterQuality: FilterQuality.low,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.orange.withValues(alpha: 0.12),
                            child: const Icon(Icons.pets_rounded, size: 40),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _locked ? _next : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(_index < _rounds.length - 1 ? 'Next round' : 'Finish'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Round {
  final String question;
  final String correctId;
  final List<Animal> options;
  final bool isSoundRound;
  final String? soundAssetPath;

  _Round({
    required this.question,
    required this.correctId,
    required this.options,
    required this.isSoundRound,
    this.soundAssetPath,
  });
}
