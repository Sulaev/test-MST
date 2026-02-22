import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

class AppMetricaState {
  const AppMetricaState({
    required this.isInitialized,
    this.deviceId,
    this.lastError,
  });

  const AppMetricaState.initial()
      : isInitialized = false,
        deviceId = null,
        lastError = null;

  final bool isInitialized;
  final String? deviceId;
  final String? lastError;

  AppMetricaState copyWith({
    bool? isInitialized,
    String? deviceId,
    String? lastError,
  }) {
    return AppMetricaState(
      isInitialized: isInitialized ?? this.isInitialized,
      deviceId: deviceId ?? this.deviceId,
      lastError: lastError,
    );
  }
}

class AppMetricaService {
  final ValueNotifier<AppMetricaState> state = ValueNotifier<AppMetricaState>(
    const AppMetricaState.initial(),
  );

  bool _isStarted = false;

  Future<void> initialize(AppConfig config) async {
    final String apiKey = config.appMetricaApiKey.trim();
    if (apiKey.isEmpty) {
      return;
    }
    try {
      await AppMetrica.activate(
        AppMetricaConfig(
          apiKey,
          logs: kDebugMode,
        ),
      );
      _isStarted = true;
      final String? deviceId = await AppMetrica.deviceId;
      state.value = state.value.copyWith(
        isInitialized: true,
        deviceId: deviceId,
        lastError: null,
      );
    } catch (error) {
      state.value = state.value.copyWith(lastError: error.toString());
    }
  }

  Future<void> logEvent(String eventName, Map<String, dynamic> parameters) async {
    if (!_isStarted) {
      return;
    }
    try {
      final Map<String, Object> sanitized = <String, Object>{};
      parameters.forEach((String key, dynamic value) {
        if (value == null) {
          return;
        }
        if (value is num || value is bool || value is String || value is List || value is Map) {
          sanitized[key] = value as Object;
        } else {
          sanitized[key] = value.toString();
        }
      });
      await AppMetrica.reportEventWithMap(eventName, sanitized);
    } catch (_) {
      // Best-effort logging only.
    }
  }

  void dispose() {
    state.dispose();
  }
}
