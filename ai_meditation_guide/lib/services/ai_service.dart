import '../config/app_config.dart';
import 'gen_api_service.dart';

enum MeditationGoal {
  reduceStress,
  improveSleep,
  increaseFocus,
  boostEnergy,
  calmAnxiety,
}

enum VoiceStyle { soft, neutral, deep }

enum BackgroundSound { nature, ambient, rain, none }

class GeneratedMeditation {
  GeneratedMeditation({
    required this.goal,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.script,
    this.coverImageUrl,
    this.coverAssetPath,
    this.audioUrl,
    this.backgroundAudioUrl,
  });

  final MeditationGoal goal;
  final String title;
  final String description;
  final int durationMinutes;
  final String script;

  /// If set, use `Image.network(coverImageUrl)`.
  final String? coverImageUrl;

  /// Fallback cover from local assets (e.g. stones images).
  final String? coverAssetPath;

  /// Pre-mixed voice (or final audio) URL to play.
  final String? audioUrl;

  /// Optional background stem (if you later decide to mix on-device).
  final String? backgroundAudioUrl;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'goal': goal.name,
        'title': title,
        'description': description,
        'durationMinutes': durationMinutes,
        'script': script,
        'coverImageUrl': coverImageUrl,
        'coverAssetPath': coverAssetPath,
        'audioUrl': audioUrl,
        'backgroundAudioUrl': backgroundAudioUrl,
      };

  factory GeneratedMeditation.fromJson(Map<String, dynamic> json) {
    final goalRaw = (json['goal'] ?? '').toString();
    final goal = MeditationGoal.values.firstWhere(
      (e) => e.name == goalRaw,
      orElse: () => MeditationGoal.reduceStress,
    );
    final durationRaw = json['durationMinutes'];
    final duration = durationRaw is num
        ? durationRaw.toInt()
        : int.tryParse(durationRaw?.toString() ?? '') ?? 2;
    return GeneratedMeditation(
      goal: goal,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      durationMinutes: duration,
      script: (json['script'] ?? '').toString(),
      coverImageUrl: (json['coverImageUrl'] ?? '').toString().trim().isEmpty
          ? null
          : (json['coverImageUrl']).toString(),
      coverAssetPath: (json['coverAssetPath'] ?? '').toString().trim().isEmpty
          ? null
          : (json['coverAssetPath']).toString(),
      audioUrl: (json['audioUrl'] ?? '').toString().trim().isEmpty
          ? null
          : (json['audioUrl']).toString(),
      backgroundAudioUrl:
          (json['backgroundAudioUrl'] ?? '').toString().trim().isEmpty
              ? null
              : (json['backgroundAudioUrl']).toString(),
    );
  }
}

class AIService {
  AIService._();

  static final AIService instance = AIService._();

  Future<GeneratedMeditation> generateMeditation({
    required MeditationGoal goal,
    required int durationMinutes,
    required VoiceStyle voiceStyle,
    required BackgroundSound backgroundSound,
  }) async {
    try {
      final generated = await GenApiService.instance.generateMeditation(
        goal: goal,
        durationMinutes: durationMinutes,
        voiceStyle: voiceStyle,
        backgroundSound: backgroundSound,
      );
    return GeneratedMeditation(
        goal: goal,
        title: generated.title,
        description: generated.description,
      durationMinutes: durationMinutes,
        script: generated.script,
        coverImageUrl: generated.coverImage,
        audioUrl: generated.voiceAudioUrl,
        backgroundAudioUrl: _buildReadyBackgroundUrl(backgroundSound),
      );
    } catch (e) {
      throw Exception('GenAPI generation failed: $e');
    }
  }

  String? _buildReadyBackgroundUrl(BackgroundSound sound) {
    switch (sound) {
      case BackgroundSound.nature:
        return 'assets/embientMusic/nature.mp3';
      case BackgroundSound.ambient:
        return 'assets/embientMusic/ambient.mp3';
      case BackgroundSound.rain:
        return 'assets/embientMusic/rain.wav';
      case BackgroundSound.none:
        return null;
  }
  }

}

