import 'gen_api_service.dart';
import 'ai_service.dart';

class OpenAiGeneratedMeditation {
  OpenAiGeneratedMeditation({
    required this.title,
    required this.description,
    required this.script,
    this.coverDataUri,
    this.voiceFilePath,
  });

  final String title;
  final String description;
  final String script;
  final String? coverDataUri;
  final String? voiceFilePath;
}

/// Compatibility shim over GenAPI.
class OpenAiService {
  OpenAiService._();

  static final OpenAiService instance = OpenAiService._();

  Future<OpenAiGeneratedMeditation> generateMeditation({
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
    return OpenAiGeneratedMeditation(
      title: generated.title,
      description: generated.description,
      script: generated.script,
      coverDataUri: generated.coverImage,
      voiceFilePath: null,
    );
  }
}
