import 'ai_service.dart';

/// Compatibility shim: old call-sites now route to ready URLs / GenAPI flow.
class LocalAiService {
  LocalAiService._();

  static final LocalAiService instance = LocalAiService._();

  Future<GeneratedMeditation> generateMeditation({
    required MeditationGoal goal,
    required int durationMinutes,
    required VoiceStyle voiceStyle,
    required BackgroundSound backgroundSound,
  }) {
    return AIService.instance.generateMeditation(
      goal: goal,
      durationMinutes: durationMinutes,
      voiceStyle: voiceStyle,
      backgroundSound: backgroundSound,
    );
  }

  Future<String?> generateBackground({
    required MeditationGoal goal,
    required BackgroundSound backgroundSound,
  }) async {
    switch (backgroundSound) {
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
