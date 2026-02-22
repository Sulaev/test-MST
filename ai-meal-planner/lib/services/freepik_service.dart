import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class FreepikService {
  FreepikService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> removeBackground({
    required AppConfig config,
    required String imageUrl,
  }) async {
    return _process(
      config: config,
      endpointPath: '/v1/ai/remove-background',
      imageUrl: imageUrl,
    );
  }

  Future<String> segmentObject({
    required AppConfig config,
    required String imageUrl,
  }) async {
    return _process(
      config: config,
      endpointPath: '/v1/ai/segment',
      imageUrl: imageUrl,
    );
  }

  Future<String> _process({
    required AppConfig config,
    required String endpointPath,
    required String imageUrl,
  }) async {
    if (!config.enableFreepikTools) {
      throw const FreepikException('Freepik tools are disabled by feature flag.');
    }
    final String token = config.freepikApiKey.trim();
    if (token.isEmpty) {
      throw const FreepikException('FREEPIK_API_KEY is not configured.');
    }
    final Uri uri = Uri.parse('${config.freepikBaseUrl}$endpointPath');
    final http.Response response = await _client
        .post(
          uri,
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, dynamic>{'image_url': imageUrl.trim()}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FreepikException('Freepik request failed (HTTP ${response.statusCode}).');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FreepikException('Freepik response format is invalid.');
    }

    final String? resultUrl = _extractResultUrl(decoded);
    if (resultUrl == null || resultUrl.isEmpty) {
      throw const FreepikException('Freepik response has no result URL.');
    }
    return resultUrl;
  }

  String? _extractResultUrl(Map<String, dynamic> map) {
    final List<Object?> candidates = <Object?>[
      map['result_url'],
      map['url'],
      (map['data'] is Map<String, dynamic>) ? (map['data'] as Map<String, dynamic>)['url'] : null,
      (map['output'] is Map<String, dynamic>)
          ? (map['output'] as Map<String, dynamic>)['url']
          : null,
    ];
    for (final Object? item in candidates) {
      final String value = item?.toString() ?? '';
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}

class FreepikException implements Exception {
  const FreepikException(this.message);
  final String message;

  @override
  String toString() => message;
}
