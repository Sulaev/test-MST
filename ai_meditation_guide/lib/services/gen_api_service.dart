import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'ai_service.dart';

class GenApiGeneratedMeditation {
  GenApiGeneratedMeditation({
    required this.title,
    required this.description,
    required this.script,
    this.coverImage,
    this.voiceAudioUrl,
  });

  final String title;
  final String description;
  final String script;
  final String? coverImage;
  final String? voiceAudioUrl;
}

class GenApiService {
  GenApiService._();

  static final GenApiService instance = GenApiService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: null,
      receiveTimeout: null,
      sendTimeout: null,
      baseUrl: AppConfig.genApiBaseUrl,
    ),
  );

  Future<GenApiGeneratedMeditation> generateMeditation({
    required MeditationGoal goal,
    required int durationMinutes,
    required VoiceStyle voiceStyle,
    required BackgroundSound backgroundSound,
  }) async {
    if (AppConfig.genApiAuthToken.isEmpty) {
      throw Exception('GEN_API_KEY / GENAPI_TOKEN is empty');
    }

    final headers = <String, String>{
      'Authorization': 'Bearer ${AppConfig.genApiAuthToken}',
      'Content-Type': 'application/json',
    };

    final text = AppConfig.genApiEnableText
        ? await _generateText(
            headers: headers,
            goal: goal,
            durationMinutes: durationMinutes,
            voiceStyle: voiceStyle,
            backgroundSound: backgroundSound,
          )
        : _buildDefaultText(goal: goal, durationMinutes: durationMinutes);

    final cover = AppConfig.genApiEnableImage
        ? await _generateCoverDataUri(
            headers: headers,
            title: text.title,
            goal: goal,
          ).catchError((_) => null)
        : null;
    final voiceAudio = await _generateVoiceAudioUrl(
      headers: headers,
      script: text.script,
      style: voiceStyle,
    ).catchError((_) => null);

    return GenApiGeneratedMeditation(
      title: text.title,
      description: text.description,
      script: text.script,
      coverImage: cover,
      voiceAudioUrl: voiceAudio,
    );
  }

  Future<({String title, String description, String script})> _generateText({
    required Map<String, String> headers,
    required MeditationGoal goal,
    required int durationMinutes,
    required VoiceStyle voiceStyle,
    required BackgroundSound backgroundSound,
  }) async {
    final prompt = '''
You are a meditation coach.
Generate one guided meditation in English.

Goal: ${goal.name}
Duration: $durationMinutes minutes
Voice style: ${voiceStyle.name}
Background sound: ${backgroundSound.name}

Return STRICT JSON with keys:
title, description, script.
Script should be calm, clear, and around ${durationMinutes * 90}-${durationMinutes * 140} words.
''';

    Map<String, dynamic> finalResult;
    try {
      finalResult = await _submitAndWaitNetwork(
        headers: headers,
        networkId: AppConfig.genApiTextNetwork,
        payload: <String, dynamic>{
          'messages': [
            {'role': 'system', 'content': 'You generate meditation content.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
        },
      );
    } catch (_) {
      // Fallback to OpenAI-compatible endpoint when async network endpoint is unstable.
      finalResult = await _generateTextViaCompatEndpoint(
        headers: headers,
        prompt: prompt,
      );
    }
    final outText = _extractOutputText(finalResult) ?? '';
    final parsed = _safeJsonObject(outText);
    final fallbackFromRaw = _deriveTextFromRaw(
      raw: outText,
      goal: goal,
      durationMinutes: durationMinutes,
    );

    final title = _readString(parsed, 'title') ?? fallbackFromRaw.title;
    final description =
        _readString(parsed, 'description') ?? fallbackFromRaw.description;
    final script = _readString(parsed, 'script') ?? fallbackFromRaw.script;

    return (
      title: (title?.isNotEmpty == true) ? title! : 'Meditation',
      description: (description?.isNotEmpty == true)
          ? description!
          : 'Generated meditation session.',
      script: (script?.isNotEmpty == true)
          ? script!
          : 'Close your eyes and breathe slowly.',
    );
  }

  Future<String?> _generateCoverDataUri({
    required Map<String, String> headers,
    required String title,
    required MeditationGoal goal,
  }) async {
    final prompt = '''
Photorealistic cinematic scene for a meditation cover.
Create either:
- an enchanted magical forest at golden hour with light rays through mist, or
- a peaceful open field with wildflowers, soft morning fog and warm sunlight.

Style: ultra-detailed, natural colors, realistic lens look, shallow depth of field,
high dynamic range, calming atmosphere, no fantasy creatures, no people.
Composition: centered, clean, minimal, suitable for app cover.
Constraints: no text, no logos, no watermark.
Theme: ${goal.name}. Mood: $title.
''';

    try {
      Map<String, dynamic> finalResult;
      try {
        finalResult = await _submitAndWaitNetwork(
          headers: headers,
          networkId: AppConfig.genApiImageNetwork,
          payload: <String, dynamic>{
            'model': 'standard',
            'prompt': prompt,
            'width': 1024,
            'height': 1024,
          },
        );
      } catch (_) {
        // Fallback to OpenAI-compatible image endpoint.
        finalResult = await _generateImageViaCompatEndpoint(
          headers: headers,
          prompt: prompt,
        );
      }
      final imageUrl = _extractOutputImageUrl(finalResult);
      if (imageUrl != null && imageUrl.isNotEmpty) return imageUrl;
      final b64 = _extractOutputBase64(finalResult);
      if (b64 != null && b64.isNotEmpty) return 'data:image/png;base64,$b64';
    } catch (e) {
      throw Exception('GenAPI image network failed: ${_formatDioError(e)}');
    }
    return null;
  }

  Future<Map<String, dynamic>> _generateTextViaCompatEndpoint({
    required Map<String, String> headers,
    required String prompt,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      AppConfig.genApiChatPath,
      data: <String, dynamic>{
        'model': AppConfig.genApiTextModel,
        'messages': [
          {'role': 'system', 'content': 'You generate meditation content.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      },
      options: Options(headers: headers),
    );
    return res.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _generateImageViaCompatEndpoint({
    required Map<String, String> headers,
    required String prompt,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      AppConfig.genApiImagePath,
      data: <String, dynamic>{
        'model': AppConfig.genApiImageModel,
        'prompt': prompt,
        'size': '1024x1024',
      },
      options: Options(headers: headers),
    );
    return res.data ?? <String, dynamic>{};
  }

  Future<String?> _generateVoiceAudioUrl({
    required Map<String, String> headers,
    required String script,
    required VoiceStyle style,
  }) async {
    final normalized = script.replaceAll('\n', ' ').trim();
    final prompt = normalized.length > 1800
        ? normalized.substring(0, 1800)
        : normalized;
    if (prompt.isEmpty) return null;

    final voiceId = switch (style) {
      VoiceStyle.soft => AppConfig.genApiTtsVoiceSoft,
      VoiceStyle.neutral => AppConfig.genApiTtsVoiceNeutral,
      VoiceStyle.deep => AppConfig.genApiTtsVoiceDeep,
    };

    final result = await _submitAndWaitNetwork(
      headers: headers,
      networkId: AppConfig.genApiTtsNetwork,
      payload: <String, dynamic>{
        'prompt': prompt,
        // Keep payload minimal and strictly aligned with required fields.
        // Extra fields may trigger validation variance across network versions.
        'model': AppConfig.genApiTtsModel,
        'voice_id': voiceId,
        'output_format': 'url',
      },
    );

    final url = _extractOutputAudioUrl(result);
    return (url != null && url.isNotEmpty) ? url : null;
  }

  Future<Map<String, dynamic>> _submitAndWaitNetwork({
    required Map<String, String> headers,
    required String networkId,
    required Map<String, dynamic> payload,
  }) async {
    final submit = await _postNetwork(
      headers: headers,
      networkId: networkId,
      payload: payload,
    );

    final body = submit.data ?? <String, dynamic>{};
    final status = (body['status'] ?? '').toString().toLowerCase();
    if (_isDoneStatus(status)) return body;
    if (_isFailedStatus(status)) {
      throw Exception(_extractError(body) ?? 'network request failed');
    }

    final requestIdRaw = body['request_id'];
    final requestId = requestIdRaw is num
        ? requestIdRaw.toInt().toString()
        : requestIdRaw?.toString();
    if (requestId == null || requestId.isEmpty) {
      throw Exception('No request_id in GenAPI response: $body');
    }

    while (true) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final polled = await _pollRequest(headers: headers, requestId: requestId);
      final polledStatus = (polled['status'] ?? '').toString().toLowerCase();
      if (_isDoneStatus(polledStatus)) return polled;
      if (_isFailedStatus(polledStatus)) {
        throw Exception(_extractError(polled) ?? 'request failed, id=$requestId');
      }
    }
  }

  Future<Response<Map<String, dynamic>>> _postNetwork({
    required Map<String, String> headers,
    required String networkId,
    required Map<String, dynamic> payload,
  }) async {
    final paths = <String>[
      '${AppConfig.genApiNetworksPath}/$networkId',
      '/api/v1/networks/$networkId',
    ];
    Object? lastError;
    for (final path in paths) {
      try {
        return await _dio.post<Map<String, dynamic>>(
          path,
          data: <String, dynamic>{...payload},
          options: Options(headers: headers),
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('GenAPI submit failed: ${_formatDioError(lastError)}');
  }

  Future<Map<String, dynamic>> _pollRequest({
    required Map<String, String> headers,
    required String requestId,
  }) async {
    final candidates = <String>[
      AppConfig.genApiRequestPathTemplate.replaceAll('{id}', requestId),
      AppConfig.genApiRequestAltPathTemplate.replaceAll('{id}', requestId),
      '/api/v1/request/get/$requestId',
      '/api/v1/request/$requestId',
      '/api/v1/requests/$requestId',
      '/api/v1/requests/$requestId/status',
    ];

    Object? lastError;
    for (final path in candidates) {
      try {
        final res = await _dio.get<Map<String, dynamic>>(
          path,
          options: Options(headers: headers),
        );
        return res.data ?? <String, dynamic>{};
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Unable to poll GenAPI request status: $lastError');
  }

  bool _isDoneStatus(String status) =>
      status == 'done' ||
      status == 'completed' ||
      status == 'success' ||
      status == 'succeeded' ||
      status == 'finished';

  bool _isFailedStatus(String status) =>
      status == 'failed' ||
      status == 'error' ||
      status == 'cancelled' ||
      status == 'canceled';

  String? _extractOutputText(Map<String, dynamic> body) {
    final fromChoices = _extractTextFromAny(body['choices']);
    if (fromChoices != null && fromChoices.isNotEmpty) return fromChoices;
    if (body['result'] is List && (body['result'] as List).isNotEmpty) {
      final resultList = body['result'] as List;
      final chunks = resultList
          .map((e) => e is String ? e.trim() : '')
          .where((e) => e.isNotEmpty)
          .toList();
      if (chunks.isNotEmpty) return chunks.join('\n');
    }
    if (body['full_response'] is List && (body['full_response'] as List).isNotEmpty) {
      final full = body['full_response'] as List;
      for (final item in full) {
        if (item is Map) {
          final text = item['text'] ?? item['content'] ?? item['output'];
          if (text is String && text.trim().isNotEmpty) return text.trim();
          final nested = _extractTextFromAny(item['choices']);
          if (nested != null && nested.isNotEmpty) return nested;
        }
      }
    }
    final candidates = <dynamic>[
      body['output'],
      body['result'],
      body['data'],
      body['response'],
      body['text'],
    ];
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) return c.trim();
      if (c is Map) {
        final asMap = Map<String, dynamic>.from(c);
        final t = asMap['text'] ?? asMap['content'] ?? asMap['output'];
        if (t is String && t.trim().isNotEmpty) return t.trim();
      }
      if (c is List && c.isNotEmpty && c.first is String) {
        final s = (c.first as String).trim();
        if (s.isNotEmpty) return s;
      }
      final nested = _extractTextFromAny(c);
      if (nested != null && nested.isNotEmpty) return nested;
    }
    return null;
  }

  String? _extractTextFromAny(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final s = value.trim();
      return s.isEmpty ? null : s;
    }
    if (value is List) {
      for (final item in value) {
        final text = _extractTextFromAny(item);
        if (text != null && text.isNotEmpty) return text;
      }
      return null;
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final directKeys = <String>[
        'text',
        'content',
        'output',
        'message',
      ];
      for (final key in directKeys) {
        final text = _extractTextFromAny(map[key]);
        if (text != null && text.isNotEmpty) return text;
      }
      final choices = _extractTextFromAny(map['choices']);
      if (choices != null && choices.isNotEmpty) return choices;
      for (final entry in map.values) {
        final text = _extractTextFromAny(entry);
        if (text != null && text.isNotEmpty) return text;
      }
    }
    return null;
  }

  String? _extractOutputImageUrl(Map<String, dynamic> body) {
    String? find(dynamic v) {
      if (v is String) {
        final s = v.trim();
        if (s.startsWith('http://') || s.startsWith('https://')) return s;
        return null;
      }
      if (v is List) {
        for (final item in v) {
          final r = find(item);
          if (r != null) return r;
        }
        return null;
      }
      if (v is Map) {
        for (final e in v.values) {
          final r = find(e);
          if (r != null) return r;
        }
      }
      return null;
    }

    return find(body['result']) ??
        find(body['output']) ??
        find(body['result']) ??
        find(body['data']) ??
        find(body['response']);
  }

  String? _extractOutputAudioUrl(Map<String, dynamic> body) {
    String? find(dynamic v) {
      if (v is String) {
        final s = v.trim();
        if (s.startsWith('http://') || s.startsWith('https://')) return s;
        return null;
      }
      if (v is List) {
        for (final item in v) {
          final r = find(item);
          if (r != null) return r;
        }
        return null;
      }
      if (v is Map) {
        final preferred = <String>['audio_url', 'url', 'output_url', 'file_url'];
        for (final k in preferred) {
          final candidate = v[k];
          final r = find(candidate);
          if (r != null) return r;
        }
        for (final e in v.values) {
          final r = find(e);
          if (r != null) return r;
        }
      }
      return null;
    }

    return find(body['output']) ??
        find(body['result']) ??
        find(body['full_response']) ??
        find(body['response']) ??
        find(body['data']);
  }

  ({String title, String description, String script}) _deriveTextFromRaw({
    required String raw,
    required MeditationGoal goal,
    required int durationMinutes,
  }) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) {
      return (
        title: 'Meditation',
        description: 'Generated meditation session.',
        script: 'Close your eyes and breathe slowly.',
      );
    }

    final lines = cleaned
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final first = lines.isNotEmpty ? lines.first : cleaned;
    final title = first.length > 70 ? first.substring(0, 70).trim() : first;
    final description = 'Guided ${goal.name} meditation for $durationMinutes minutes.';
    return (title: title, description: description, script: cleaned);
  }

  ({String title, String description, String script}) _buildDefaultText({
    required MeditationGoal goal,
    required int durationMinutes,
  }) {
    const script2min = '''
Find a comfortable position and allow your body to settle.
Gently close your eyes.

Take a slow breath in through your nose for four counts,
and exhale softly through your mouth for six counts.
Again, inhale calm, exhale tension.

Bring your attention to your shoulders, your jaw, and your hands.
Let each area soften.
If thoughts appear, acknowledge them kindly and let them pass.
Return to your breath.

Now notice one simple sound around you.
Notice one sensation in your body.
Notice one steady point of calm inside.

With every exhale, repeat silently:
I am safe.
I am here.
I can let go.

Take two final slow breaths.
Feel a little more space in your chest,
a little more quiet in your mind.

When you are ready, gently move your fingers,
roll your shoulders, and open your eyes.
Carry this calm with you.
''';
    return (
      title: _defaultTitleForGoal(goal),
      description:
          'A gentle guided meditation to help you reset and relax in about two minutes.',
      script: script2min.trim(),
    );
  }

  String _defaultTitleForGoal(MeditationGoal goal) {
    switch (goal) {
      case MeditationGoal.reduceStress:
        return '2-Minute Calm for Stress Relief';
      case MeditationGoal.improveSleep:
        return '2-Minute Wind-Down for Better Sleep';
      case MeditationGoal.increaseFocus:
        return '2-Minute Focus Reset';
      case MeditationGoal.boostEnergy:
        return '2-Minute Gentle Energy Boost';
      case MeditationGoal.calmAnxiety:
        return '2-Minute Grounding for Anxiety';
    }
  }

  String? _extractOutputBase64(Map<String, dynamic> body) {
    String? find(dynamic v) {
      if (v is Map) {
        final b = v['b64_json'] ?? v['base64'] ?? v['image_base64'];
        if (b is String && b.trim().isNotEmpty) return b.trim();
        for (final e in v.values) {
          final r = find(e);
          if (r != null) return r;
        }
      } else if (v is List) {
        for (final item in v) {
          final r = find(item);
          if (r != null) return r;
        }
      }
      return null;
    }
    return find(body['result']) ??
        find(body['output']) ??
        find(body['result']) ??
        find(body['data']) ??
        find(body['response']);
  }

  String? _extractError(Map<String, dynamic> body) {
    final err = body['error'] ?? body['message'] ?? body['detail'];
    if (err == null) return null;
    return err.toString();
  }

  String _formatDioError(Object? e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      final uri = e.requestOptions.uri;
      return 'status=$code uri=$uri data=$data';
    }
    return '$e';
  }

  String? _readString(Map<String, dynamic> obj, String key) {
    final v = obj[key];
    if (v is String) return v.trim();
    if (v == null) return null;
    return v.toString().trim();
  }

  Map<String, dynamic> _safeJsonObject(String content) {
    try {
      final parsed = jsonDecode(content);
      if (parsed is Map<String, dynamic>) return parsed;
      return <String, dynamic>{};
    } catch (_) {
      final start = content.indexOf('{');
      final end = content.lastIndexOf('}');
      if (start < 0 || end <= start) return <String, dynamic>{};
      try {
        final parsed = jsonDecode(content.substring(start, end + 1));
        if (parsed is Map<String, dynamic>) return parsed;
      } catch (_) {}
      return <String, dynamic>{};
    }
  }
}
