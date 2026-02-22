class AppConfig {
  const AppConfig({
    required this.freepikApiKey,
    required this.appMetricaApiKey,
    required this.apphudApiKey,
    required this.apphudPlacementId,
    required this.apphudPaywallId,
    required this.apphudWeeklyProductId,
    required this.apphudMonthlyProductId,
    required this.appsflyerDevKey,
    required this.appsflyerAppleAppId,
    required this.appsflyerAttWaitSeconds,
    required this.admobAppId,
    required this.admobBannerAdUnitId,
    required this.admobInterstitialAdUnitId,
    required this.admobRewardedAdUnitId,
    required this.admobRewardedInterstitialAdUnitId,
    required this.admobAppOpenAdUnitId,
    required this.admobNativeAdUnitId,
    required this.enableAds,
    required this.enableFirebaseAnalytics,
    required this.firebaseAndroidApiKey,
    required this.firebaseAndroidAppId,
    required this.firebaseAndroidProjectId,
    required this.firebaseAndroidSenderId,
    required this.firebaseAndroidStorageBucket,
    required this.firebaseIosApiKey,
    required this.firebaseIosAppId,
    required this.firebaseIosProjectId,
    required this.firebaseIosSenderId,
    required this.firebaseIosBundleId,
    required this.firebaseIosStorageBucket,
    required this.enableFreepikTools,
    required this.freepikBaseUrl,
  });

  factory AppConfig.fromEnvironment() {
    const String attWaitRaw = String.fromEnvironment(
      'APPSFLYER_ATT_WAIT_SECONDS',
      defaultValue: '12',
    );
    final double attWaitSeconds = double.tryParse(attWaitRaw) ?? 12.0;
    const bool enableAds = bool.fromEnvironment('ENABLE_ADS', defaultValue: false);
    const bool enableFreepikTools =
        bool.fromEnvironment('ENABLE_FREEPIK_TOOLS', defaultValue: false);
    const bool enableFirebaseAnalytics =
        bool.fromEnvironment('ENABLE_FIREBASE_ANALYTICS', defaultValue: false);
    return AppConfig(
      freepikApiKey: const String.fromEnvironment('FREEPIK_API_KEY', defaultValue: ''),
      appMetricaApiKey: const String.fromEnvironment(
        'APPMETRICA_API_KEY',
        defaultValue: '',
      ),
      apphudApiKey: const String.fromEnvironment(
        'APPHUD_API_KEY',
        defaultValue: '',
      ),
      apphudPlacementId: const String.fromEnvironment(
        'APPHUD_PLACEMENT_ID',
        defaultValue: '',
      ),
      apphudPaywallId: const String.fromEnvironment(
        'APPHUD_PAYWALL_ID',
        defaultValue: '',
      ),
      apphudWeeklyProductId: const String.fromEnvironment(
        'APPHUD_PRODUCT_WEEKLY',
        defaultValue: '',
      ),
      apphudMonthlyProductId: const String.fromEnvironment(
        'APPHUD_PRODUCT_MONTHLY',
        defaultValue: '',
      ),
      appsflyerDevKey: const String.fromEnvironment(
        'APPSFLYER_DEV_KEY',
        defaultValue: '',
      ),
      appsflyerAppleAppId: const String.fromEnvironment(
        'APPSFLYER_APPLE_APP_ID',
        defaultValue: '',
      ),
      appsflyerAttWaitSeconds: attWaitSeconds,
      admobAppId: const String.fromEnvironment(
        'ADMOB_APP_ID',
        defaultValue: '',
      ),
      admobBannerAdUnitId: const String.fromEnvironment(
        'ADMOB_BANNER_AD_UNIT_ID',
        defaultValue: '',
      ),
      admobInterstitialAdUnitId: const String.fromEnvironment(
        'ADMOB_INTERSTITIAL_AD_UNIT_ID',
        defaultValue: '',
      ),
      admobRewardedAdUnitId: const String.fromEnvironment(
        'ADMOB_REWARDED_AD_UNIT_ID',
        defaultValue: '',
      ),
      admobRewardedInterstitialAdUnitId: const String.fromEnvironment(
        'ADMOB_REWARDED_INTERSTITIAL_AD_UNIT_ID',
        defaultValue: '',
      ),
      admobAppOpenAdUnitId: const String.fromEnvironment(
        'ADMOB_APP_OPEN_AD_UNIT_ID',
        defaultValue: '',
      ),
      admobNativeAdUnitId: const String.fromEnvironment(
        'ADMOB_NATIVE_AD_UNIT_ID',
        defaultValue: '',
      ),
      enableAds: enableAds,
      enableFirebaseAnalytics: enableFirebaseAnalytics,
      firebaseAndroidApiKey:
          const String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: ''),
      firebaseAndroidAppId:
          const String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: ''),
      firebaseAndroidProjectId:
          const String.fromEnvironment('FIREBASE_ANDROID_PROJECT_ID', defaultValue: ''),
      firebaseAndroidSenderId:
          const String.fromEnvironment('FIREBASE_ANDROID_SENDER_ID', defaultValue: ''),
      firebaseAndroidStorageBucket:
          const String.fromEnvironment('FIREBASE_ANDROID_STORAGE_BUCKET', defaultValue: ''),
      firebaseIosApiKey: const String.fromEnvironment('FIREBASE_IOS_API_KEY', defaultValue: ''),
      firebaseIosAppId: const String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: ''),
      firebaseIosProjectId:
          const String.fromEnvironment('FIREBASE_IOS_PROJECT_ID', defaultValue: ''),
      firebaseIosSenderId:
          const String.fromEnvironment('FIREBASE_IOS_SENDER_ID', defaultValue: ''),
      firebaseIosBundleId:
          const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: ''),
      firebaseIosStorageBucket:
          const String.fromEnvironment('FIREBASE_IOS_STORAGE_BUCKET', defaultValue: ''),
      enableFreepikTools: enableFreepikTools,
      freepikBaseUrl: const String.fromEnvironment(
        'FREEPIK_BASE_URL',
        defaultValue: 'https://api.freepik.com',
      ),
    );
  }

  final String freepikApiKey;
  final String appMetricaApiKey;
  final String apphudApiKey;
  final String apphudPlacementId;
  final String apphudPaywallId;
  final String apphudWeeklyProductId;
  final String apphudMonthlyProductId;
  final String appsflyerDevKey;
  final String appsflyerAppleAppId;
  final double appsflyerAttWaitSeconds;
  final String admobAppId;
  final String admobBannerAdUnitId;
  final String admobInterstitialAdUnitId;
  final String admobRewardedAdUnitId;
  final String admobRewardedInterstitialAdUnitId;
  final String admobAppOpenAdUnitId;
  final String admobNativeAdUnitId;
  final bool enableAds;
  final bool enableFirebaseAnalytics;
  final String firebaseAndroidApiKey;
  final String firebaseAndroidAppId;
  final String firebaseAndroidProjectId;
  final String firebaseAndroidSenderId;
  final String firebaseAndroidStorageBucket;
  final String firebaseIosApiKey;
  final String firebaseIosAppId;
  final String firebaseIosProjectId;
  final String firebaseIosSenderId;
  final String firebaseIosBundleId;
  final String firebaseIosStorageBucket;
  final bool enableFreepikTools;
  final String freepikBaseUrl;

  int get configuredSecretsCount {
    return <String>[
      freepikApiKey,
      appMetricaApiKey,
      apphudApiKey,
      apphudPlacementId,
      apphudPaywallId,
      apphudWeeklyProductId,
      apphudMonthlyProductId,
      appsflyerDevKey,
      appsflyerAppleAppId,
      admobAppId,
      admobBannerAdUnitId,
      admobInterstitialAdUnitId,
      admobRewardedAdUnitId,
      admobRewardedInterstitialAdUnitId,
      admobAppOpenAdUnitId,
      admobNativeAdUnitId,
      firebaseAndroidApiKey,
      firebaseAndroidAppId,
      firebaseAndroidProjectId,
      firebaseAndroidSenderId,
      firebaseAndroidStorageBucket,
      firebaseIosApiKey,
      firebaseIosAppId,
      firebaseIosProjectId,
      firebaseIosSenderId,
      firebaseIosBundleId,
      firebaseIosStorageBucket,
    ].where((String item) => item.trim().isNotEmpty).length;
  }
}
