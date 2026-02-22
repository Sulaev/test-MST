import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

class FirebaseAnalyticsState {
  const FirebaseAnalyticsState({
    required this.isInitialized,
    this.appInstanceId,
    this.lastError,
  });

  const FirebaseAnalyticsState.initial()
      : isInitialized = false,
        appInstanceId = null,
        lastError = null;

  final bool isInitialized;
  final String? appInstanceId;
  final String? lastError;

  FirebaseAnalyticsState copyWith({
    bool? isInitialized,
    String? appInstanceId,
    String? lastError,
  }) {
    return FirebaseAnalyticsState(
      isInitialized: isInitialized ?? this.isInitialized,
      appInstanceId: appInstanceId ?? this.appInstanceId,
      lastError: lastError,
    );
  }
}

class FirebaseAnalyticsService {
  final ValueNotifier<FirebaseAnalyticsState> state = ValueNotifier<FirebaseAnalyticsState>(
    const FirebaseAnalyticsState.initial(),
  );

  FirebaseAnalytics? _analytics;
  FirebaseApp? _app;

  Future<void> initialize(AppConfig config) async {
    if (!config.enableFirebaseAnalytics) {
      return;
    }
    try {
      final FirebaseOptions? options = _resolveOptions(config);
      final FirebaseApp app = options == null
          ? await Firebase.initializeApp()
          : await Firebase.initializeApp(options: options);
      _app = app;
      _analytics = FirebaseAnalytics.instanceFor(app: app);
      final String? appInstanceId = await _analytics?.appInstanceId;
      state.value = state.value.copyWith(
        isInitialized: true,
        appInstanceId: appInstanceId,
        lastError: null,
      );
    } catch (error) {
      state.value = state.value.copyWith(lastError: error.toString());
    }
  }

  Future<void> logEvent(String name, Map<String, Object> parameters) async {
    final FirebaseAnalytics? analytics = _analytics;
    if (analytics == null) {
      return;
    }
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {
      // Best-effort logging only.
    }
  }

  Map<String, dynamic> buildAttributionData() {
    final FirebaseApp? app = _app;
    final String? appInstanceId = state.value.appInstanceId;
    if (app == null || appInstanceId == null || appInstanceId.isEmpty) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{
      'app_instance_id': appInstanceId,
      'firebase_app_id': app.options.appId,
      'project_id': app.options.projectId,
    };
  }

  FirebaseOptions? _resolveOptions(AppConfig config) {
    if (kIsWeb) {
      return null;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (!_hasFirebaseAndroidConfig(config)) {
          return null;
        }
        return FirebaseOptions(
          apiKey: config.firebaseAndroidApiKey.trim(),
          appId: config.firebaseAndroidAppId.trim(),
          messagingSenderId: config.firebaseAndroidSenderId.trim(),
          projectId: config.firebaseAndroidProjectId.trim(),
          storageBucket: config.firebaseAndroidStorageBucket.trim().isEmpty
              ? null
              : config.firebaseAndroidStorageBucket.trim(),
        );
      case TargetPlatform.iOS:
        if (!_hasFirebaseIosConfig(config)) {
          return null;
        }
        return FirebaseOptions(
          apiKey: config.firebaseIosApiKey.trim(),
          appId: config.firebaseIosAppId.trim(),
          messagingSenderId: config.firebaseIosSenderId.trim(),
          projectId: config.firebaseIosProjectId.trim(),
          iosBundleId: config.firebaseIosBundleId.trim().isEmpty
              ? null
              : config.firebaseIosBundleId.trim(),
          storageBucket: config.firebaseIosStorageBucket.trim().isEmpty
              ? null
              : config.firebaseIosStorageBucket.trim(),
        );
      default:
        return null;
    }
  }

  bool _hasFirebaseAndroidConfig(AppConfig config) {
    return config.firebaseAndroidApiKey.trim().isNotEmpty &&
        config.firebaseAndroidAppId.trim().isNotEmpty &&
        config.firebaseAndroidProjectId.trim().isNotEmpty &&
        config.firebaseAndroidSenderId.trim().isNotEmpty;
  }

  bool _hasFirebaseIosConfig(AppConfig config) {
    return config.firebaseIosApiKey.trim().isNotEmpty &&
        config.firebaseIosAppId.trim().isNotEmpty &&
        config.firebaseIosProjectId.trim().isNotEmpty &&
        config.firebaseIosSenderId.trim().isNotEmpty;
  }

  void dispose() {
    state.dispose();
  }
}
