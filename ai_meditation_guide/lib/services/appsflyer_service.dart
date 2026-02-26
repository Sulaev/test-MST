import 'package:appsflyer_sdk/appsflyer_sdk.dart';

class AppsFlyerService {
  AppsFlyerService._();

  static final AppsFlyerService instance = AppsFlyerService._();

  late final AppsflyerSdk _sdk;
  bool _isInitialized = false;

  Future<void> init({required bool attAuthorized}) async {
    if (_isInitialized) return;

    final options = AppsFlyerOptions(
      afDevKey: 'GAgckFyN4yETigBtP4qtRG',
      appId: '6749377146',
      showDebug: true,
      timeToWaitForATTUserAuthorization: 60,
    );

    _sdk = AppsflyerSdk(options);
    await _sdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );

    _sdk.onInstallConversionData((res) {
      // TODO: передать данные атрибуции в Apphud.
    });

    _isInitialized = true;
  }

  Future<void> logEvent(String name, Map<String, dynamic> values) async {
    if (!_isInitialized) return;
    await _sdk.logEvent(name, values);
  }
}

