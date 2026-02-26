import 'gen_api_service.dart';
import 'ai_service.dart';

class FreeAiGeneratedMeditation {
  FreeAiGeneratedMeditation({
    required this.title,
    required this.description,
    required this.script,
    this.coverUrl,
  });

  final String title;
  final String description;
  final String script;
  final String? coverUrl;
}

/// Compatibility shim over GenAPI.
class FreeAiService {
  FreeAiService._();

  static final FreeAiService instance = FreeAiService._();

  Future<FreeAiGeneratedMeditation> generateMeditation({
    required MeditationGoal goal,
    required int durationMinutes,
    required VoiceStyle voiceStyle,
    required BackgroundSound backgroundSound,
  }) async {
    final generated = await GenApiService.instance.generateMeditation(
      goal: goal,
      durationMinutes: durationMinutes,
      voiceStyle: voiceStyle,
      backgroundSound: backgroundSound,
    );
    return FreeAiGeneratedMeditation(
      title: generated.title,
      description: generated.description,
      script: generated.script,
      coverUrl: generated.coverImage,
    );
  }
}
