import 'dart:convert';

import 'package:ai_meal_planner/config/app_config.dart';
import 'package:ai_meal_planner/services/freepik_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('extracts result url from data.url payload', () async {
    final MockClient client = MockClient((http.Request request) async {
      return http.Response(
        jsonEncode(<String, dynamic>{
          'data': <String, dynamic>{'url': 'https://cdn.example.com/result.png'},
        }),
        200,
      );
    });
    final FreepikService service = FreepikService(client: client);
    final AppConfig config = AppConfig.fromEnvironment();

    final String url = await service.removeBackground(
      config: configWith(config, freepikApiKey: 'test-key'),
      imageUrl: 'https://example.com/source.png',
    );
    expect(url, 'https://cdn.example.com/result.png');
  });

  test('throws if api key missing', () async {
    final FreepikService service = FreepikService(client: MockClient((_) async => http.Response('{}', 200)));
    final AppConfig config = AppConfig.fromEnvironment();
    expect(
      () => service.segmentObject(
        config: configWith(config, freepikApiKey: ''),
        imageUrl: 'https://example.com/source.png',
      ),
      throwsA(isA<FreepikException>()),
    );
  });
}

AppConfig configWith(
  AppConfig base, {
  required String freepikApiKey,
}) {
  return AppConfig(
    freepikApiKey: freepikApiKey,
    appMetricaApiKey: base.appMetricaApiKey,
    apphudApiKey: base.apphudApiKey,
    apphudPlacementId: base.apphudPlacementId,
    apphudPaywallId: base.apphudPaywallId,
    apphudWeeklyProductId: base.apphudWeeklyProductId,
    apphudMonthlyProductId: base.apphudMonthlyProductId,
    appsflyerDevKey: base.appsflyerDevKey,
    appsflyerAppleAppId: base.appsflyerAppleAppId,
    appsflyerAttWaitSeconds: base.appsflyerAttWaitSeconds,
    admobAppId: base.admobAppId,
    admobBannerAdUnitId: base.admobBannerAdUnitId,
    admobInterstitialAdUnitId: base.admobInterstitialAdUnitId,
    admobRewardedAdUnitId: base.admobRewardedAdUnitId,
    admobRewardedInterstitialAdUnitId: base.admobRewardedInterstitialAdUnitId,
    admobAppOpenAdUnitId: base.admobAppOpenAdUnitId,
    admobNativeAdUnitId: base.admobNativeAdUnitId,
    enableAds: base.enableAds,
    enableFirebaseAnalytics: base.enableFirebaseAnalytics,
    firebaseAndroidApiKey: base.firebaseAndroidApiKey,
    firebaseAndroidAppId: base.firebaseAndroidAppId,
    firebaseAndroidProjectId: base.firebaseAndroidProjectId,
    firebaseAndroidSenderId: base.firebaseAndroidSenderId,
    firebaseAndroidStorageBucket: base.firebaseAndroidStorageBucket,
    firebaseIosApiKey: base.firebaseIosApiKey,
    firebaseIosAppId: base.firebaseIosAppId,
    firebaseIosProjectId: base.firebaseIosProjectId,
    firebaseIosSenderId: base.firebaseIosSenderId,
    firebaseIosBundleId: base.firebaseIosBundleId,
    firebaseIosStorageBucket: base.firebaseIosStorageBucket,
    enableFreepikTools: base.enableFreepikTools,
    freepikBaseUrl: base.freepikBaseUrl,
  );
}
