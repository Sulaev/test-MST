import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

class AppsflyerState {
  const AppsflyerState({
    required this.isInitialized,
    required this.isStarted,
    this.appsFlyerUid,
    this.lastConversionData,
    this.lastError,
  });

  const AppsflyerState.initial()
      : isInitialized = false,
        isStarted = false,
        appsFlyerUid = null,
        lastConversionData = null,
        lastError = null;

  final bool isInitialized;
  final bool isStarted;
  final String? appsFlyerUid;
  final Map<String, dynamic>? lastConversionData;
  final String? lastError;

  AppsflyerState copyWith({
    bool? isInitialized,
    bool? isStarted,
    String? appsFlyerUid,
    Map<String, dynamic>? lastConversionData,
    String? lastError,
  }) {
    return AppsflyerState(
      isInitialized: isInitialized ?? this.isInitialized,
      isStarted: isStarted ?? this.isStarted,
      appsFlyerUid: appsFlyerUid ?? this.appsFlyerUid,
      lastConversionData: lastConversionData ?? this.lastConversionData,
      lastError: lastError,
    );
  }
}

class AppsflyerService {
  final ValueNotifier<AppsflyerState> state = ValueNotifier<AppsflyerState>(
    const AppsflyerState.initial(),
  );

  AppsflyerSdk? _sdk;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AppsFlyer] $message');
    }
  }

  Future<void> initialize({
    required AppConfig config,
    required Future<void> Function(Map<String, dynamic> conversionData, String? appsFlyerUid)
        onConversionData,
  }) async {
    if (config.appsflyerDevKey.trim().isEmpty) {
      _log('initialize skipped: dev key missing');
      return;
    }
    try {
      _log(
        'initialize: devKeyLen=${config.appsflyerDevKey.trim().length}, '
        'appleAppId=${config.appsflyerAppleAppId.trim().isEmpty ? '<empty>' : config.appsflyerAppleAppId.trim()}',
      );
      final AppsFlyerOptions options = AppsFlyerOptions(
        afDevKey: config.appsflyerDevKey.trim(),
        // `appId` is required by the SDK options type, but it's only used on iOS.
        // On Android we keep it empty to avoid coupling to iOS App Store id.
        appId: config.appsflyerAppleAppId.trim(),
        showDebug: false,
        manualStart: true,
        timeToWaitForATTUserAuthorization: config.appsflyerAttWaitSeconds,
      );
      final AppsflyerSdk sdk = AppsflyerSdk(options);
      _sdk = sdk;

      sdk.onInstallConversionData((dynamic data) async {
        _log('conversion callback fired');
        final Map<String, dynamic> payload = _toStringKeyedMap(data);
        final String? uid = await sdk.getAppsFlyerUID();
        String? errorMsg;
        if (payload['status'] == 'failure' || payload['status'] == 'error') {
          final String? statusCode = payload['data']?.toString();
          if (statusCode?.contains('400') == true) {
            errorMsg = 'AppsFlyer initialization failed (400). Please check your AppsFlyer dev key and app ID.';
          } else {
            errorMsg = 'AppsFlyer conversion data error: ${payload['data'] ?? payload['status']}';
          }
        }
        state.value = state.value.copyWith(
          lastConversionData: payload,
          appsFlyerUid: uid,
          lastError: errorMsg,
        );
        _log('conversion status=${payload['status'] ?? '<none>'}, uid=${uid ?? '<none>'}');
        await onConversionData(payload, uid);
      });

      await sdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: false,
      );
      _log('initSdk: ok');
      sdk.startSDK();
      _log('startSDK: called');
      final String? uid = await sdk.getAppsFlyerUID();
      state.value = state.value.copyWith(
        isInitialized: true,
        isStarted: true,
        appsFlyerUid: uid,
        lastError: null,
      );
      _log('initialize done: started=true, uid=${uid ?? '<none>'}');
    } catch (error) {
      final String message = error.toString();
      state.value = state.value.copyWith(lastError: message);
      _log('initialize failed: $message');
    }
  }

  Future<void> setAttStatus(String value) async {
    final AppsflyerSdk? sdk = _sdk;
    if (sdk == null) {
      return;
    }
    try {
      sdk.setAdditionalData(<String, dynamic>{'att_status': value});
    } catch (_) {
      // Optional metadata only.
    }
  }

  Future<void> logEvent(String eventName, Map<String, dynamic> values) async {
    final AppsflyerSdk? sdk = _sdk;
    if (sdk == null) {
      return;
    }
    await sdk.logEvent(eventName, values);
  }

  Future<void> dispose() async {
    state.dispose();
  }

  Map<String, dynamic> _toStringKeyedMap(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (dynamic key, dynamic mapValue) => MapEntry<String, dynamic>(
          key.toString(),
          mapValue,
        ),
      );
    }
    return <String, dynamic>{'value': value.toString()};
  }
}
