import 'dart:io' show Platform;

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place for runtime configuration.
/// Values from `--dart-define` (run_simple.sh), from .env, or from process environment.
class AppConfig {
  AppConfig._();

  /// Unified AI provider: https://gen-api.ru/docs
  static String get genApiKey {
    var v = String.fromEnvironment('GEN_API_KEY');
    if (v.isNotEmpty) return v;
    try {
      v = dotenv.env['GEN_API_KEY'] ?? '';
      if (v.isNotEmpty) return v;
    } catch (_) {}
    return Platform.environment['GEN_API_KEY'] ?? '';
  }

  static String get genApiToken {
    var v = String.fromEnvironment('GENAPI_TOKEN');
    if (v.isNotEmpty) return v;
    try {
      v = dotenv.env['GENAPI_TOKEN'] ?? '';
      if (v.isNotEmpty) return v;
    } catch (_) {}
    return Platform.environment['GENAPI_TOKEN'] ?? '';
  }

  static String get genApiAuthToken {
    final k = genApiKey;
    if (k.isNotEmpty) return k;
    return genApiToken;
  }
  static const String genApiBaseUrl = String.fromEnvironment(
    'GEN_API_BASE_URL',
    defaultValue: 'https://api.gen-api.ru',
  );

  /// Native GenAPI async generation format (request_id + status polling).
  static const String genApiNetworksPath = String.fromEnvironment(
    'GEN_API_NETWORKS_PATH',
    defaultValue: '/api/v1/networks',
  );
  static const String genApiRequestPathTemplate = String.fromEnvironment(
    'GEN_API_REQUEST_PATH_TEMPLATE',
    defaultValue: '/api/v1/request/get/{id}',
  );
  static const String genApiRequestAltPathTemplate = String.fromEnvironment(
    'GEN_API_REQUEST_ALT_PATH_TEMPLATE',
    defaultValue: '/api/v1/request/{id}',
  );
  static const String genApiTextNetwork = String.fromEnvironment(
    'GEN_API_TEXT_NETWORK',
    defaultValue: 'gpt-4-1',
  );
  static const bool genApiEnableText = bool.fromEnvironment(
    'GEN_API_ENABLE_TEXT',
    defaultValue: true,
  );
  static const String genApiImageNetwork = String.fromEnvironment(
    'GEN_API_IMAGE_NETWORK',
    defaultValue: 'flux-2',
  );
  static const bool genApiEnableImage = bool.fromEnvironment(
    'GEN_API_ENABLE_IMAGE',
    defaultValue: true,
  );
  static const String genApiTtsNetwork = String.fromEnvironment(
    'GEN_API_TTS_NETWORK',
    defaultValue: 'minimax-speech-2-8',
  );
  static const String genApiTtsModel = String.fromEnvironment(
    'GEN_API_TTS_MODEL',
    defaultValue: 'HD',
  );
  static const String genApiTtsVoiceSoft = String.fromEnvironment(
    'GEN_API_TTS_VOICE_SOFT',
    defaultValue: 'Patient_Man',
  );
  static const String genApiTtsVoiceNeutral = String.fromEnvironment(
    'GEN_API_TTS_VOICE_NEUTRAL',
    defaultValue: 'Patient_Man',
  );
  static const String genApiTtsVoiceDeep = String.fromEnvironment(
    'GEN_API_TTS_VOICE_DEEP',
    defaultValue: 'Patient_Man',
  );

  /// OpenAI-compatible endpoints exposed by GenAPI.
  static const String genApiChatPath = String.fromEnvironment(
    'GEN_API_CHAT_PATH',
    defaultValue: '/v1/chat/completions',
  );
  static const String genApiImagePath = String.fromEnvironment(
    'GEN_API_IMAGE_PATH',
    defaultValue: '/v1/images/generations',
  );

  /// Model identifiers from GenAPI catalog.
  static const String genApiTextModel = String.fromEnvironment(
    'GEN_API_TEXT_MODEL',
    defaultValue: 'gpt-4.1',
  );
  static const String genApiImageModel = String.fromEnvironment(
    'GEN_API_IMAGE_MODEL',
    defaultValue: 'flux',
  );

  // Legacy compatibility flags/keys kept so stale generated artifacts
  // or old files can still compile during transition.
  static const String freepikApiKey = '';
  static bool get enableFreepikTools => false;
  static bool get enableLocalAi => false;
  static const String localAiBaseUrl = '';
  static const String openAiKey = '';
  static bool get enableFreeAi => true;
}

