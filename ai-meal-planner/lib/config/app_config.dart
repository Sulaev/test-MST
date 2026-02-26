import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  /// Конфиг из --dart-define с подстановкой из .env (flutter_dotenv), если значение не задано.
  /// Вызывать после dotenv.load() в main().
  factory AppConfig.fromEnvironmentWithDotenv() {
    final String attWaitRaw = String.fromEnvironment(
      'APPSFLYER_ATT_WAIT_SECONDS',
      defaultValue: dotenv.env['APPSFLYER_ATT_WAIT_SECONDS'] ?? '12',
    );
    final double attWaitSeconds = double.tryParse(attWaitRaw) ?? 12.0;
    final bool enableAds = bool.fromEnvironment(
      'ENABLE_ADS',
      defaultValue: _parseBool(dotenv.env['ENABLE_ADS'], false),
    );
    final bool enableFreepikTools = bool.fromEnvironment(
      'ENABLE_FREEPIK_TOOLS',
      defaultValue: _parseBool(dotenv.env['ENABLE_FREEPIK_TOOLS'], false),
    );
    final bool enableFirebaseAnalytics = bool.fromEnvironment(
      'ENABLE_FIREBASE_ANALYTICS',
      defaultValue: _parseBool(dotenv.env['ENABLE_FIREBASE_ANALYTICS'], false),
    );
    return AppConfig(
      freepikApiKey: _str('FREEPIK_API_KEY', ''),
      appMetricaApiKey: _str('APPMETRICA_API_KEY', ''),
      apphudApiKey: _str('APPHUD_API_KEY', ''),
      apphudPlacementId: _str('APPHUD_PLACEMENT_ID', ''),
      apphudPaywallId: _str('APPHUD_PAYWALL_ID', ''),
      apphudWeeklyProductId: _str('APPHUD_PRODUCT_WEEKLY', ''),
      apphudMonthlyProductId: _str('APPHUD_PRODUCT_MONTHLY', ''),
      appsflyerDevKey: _str('APPSFLYER_DEV_KEY', ''),
      appsflyerAppleAppId: _str('APPSFLYER_APPLE_APP_ID', ''),
      appsflyerAttWaitSeconds: attWaitSeconds,
      admobAppId: _str('ADMOB_APP_ID', ''),
      admobBannerAdUnitId: _str('ADMOB_BANNER_AD_UNIT_ID', ''),
      admobInterstitialAdUnitId: _str('ADMOB_INTERSTITIAL_AD_UNIT_ID', ''),
      admobRewardedAdUnitId: _str('ADMOB_REWARDED_AD_UNIT_ID', ''),
      admobRewardedInterstitialAdUnitId: _str(
        'ADMOB_REWARDED_INTERSTITIAL_AD_UNIT_ID',
        '',
      ),
      admobAppOpenAdUnitId: _str('ADMOB_APP_OPEN_AD_UNIT_ID', ''),
      admobNativeAdUnitId: _str('ADMOB_NATIVE_AD_UNIT_ID', ''),
      enableAds: enableAds,
      enableFirebaseAnalytics: enableFirebaseAnalytics,
      firebaseAndroidApiKey: _str('FIREBASE_ANDROID_API_KEY', ''),
      firebaseAndroidAppId: _str('FIREBASE_ANDROID_APP_ID', ''),
      firebaseAndroidProjectId: _str('FIREBASE_ANDROID_PROJECT_ID', ''),
      firebaseAndroidSenderId: _str('FIREBASE_ANDROID_SENDER_ID', ''),
      firebaseAndroidStorageBucket: _str(
        'FIREBASE_ANDROID_STORAGE_BUCKET',
        '',
      ),
      firebaseIosApiKey: _str('FIREBASE_IOS_API_KEY', ''),
      firebaseIosAppId: _str('FIREBASE_IOS_APP_ID', ''),
      firebaseIosProjectId: _str('FIREBASE_IOS_PROJECT_ID', ''),
      firebaseIosSenderId: _str('FIREBASE_IOS_SENDER_ID', ''),
      firebaseIosBundleId: _str('FIREBASE_IOS_BUNDLE_ID', ''),
      firebaseIosStorageBucket: _str('FIREBASE_IOS_STORAGE_BUCKET', ''),
      enableFreepikTools: enableFreepikTools,
      freepikBaseUrl: _str(
        'FREEPIK_BASE_URL',
        'https://api.freepik.com',
      ),
    );
  }

  /// Ключ должен совпадать с константой в switch (fromEnvironment требует литерал).
  static String _str(String envKey, String fallback) {
    final fromDotenv = (dotenv.env[envKey] ?? '').trim();
    switch (envKey) {
      case 'FREEPIK_API_KEY':
        const v = String.fromEnvironment('FREEPIK_API_KEY', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'APPMETRICA_API_KEY':
        const v = String.fromEnvironment('APPMETRICA_API_KEY', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'APPHUD_API_KEY':
        const v = String.fromEnvironment('APPHUD_API_KEY', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'APPHUD_PLACEMENT_ID':
        const v = String.fromEnvironment('APPHUD_PLACEMENT_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'APPHUD_PAYWALL_ID':
        const v = String.fromEnvironment('APPHUD_PAYWALL_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'APPHUD_PRODUCT_WEEKLY':
        const v = String.fromEnvironment('APPHUD_PRODUCT_WEEKLY', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'APPHUD_PRODUCT_MONTHLY':
        const v = String.fromEnvironment('APPHUD_PRODUCT_MONTHLY', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'APPSFLYER_DEV_KEY':
        const v = String.fromEnvironment('APPSFLYER_DEV_KEY', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'APPSFLYER_APPLE_APP_ID':
        const v = String.fromEnvironment('APPSFLYER_APPLE_APP_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'ADMOB_APP_ID':
        const v = String.fromEnvironment('ADMOB_APP_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'ADMOB_BANNER_AD_UNIT_ID':
        const v = String.fromEnvironment('ADMOB_BANNER_AD_UNIT_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'ADMOB_INTERSTITIAL_AD_UNIT_ID':
        const v = String.fromEnvironment('ADMOB_INTERSTITIAL_AD_UNIT_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'ADMOB_REWARDED_AD_UNIT_ID':
        const v = String.fromEnvironment('ADMOB_REWARDED_AD_UNIT_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'ADMOB_REWARDED_INTERSTITIAL_AD_UNIT_ID':
        const v = String.fromEnvironment('ADMOB_REWARDED_INTERSTITIAL_AD_UNIT_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'ADMOB_APP_OPEN_AD_UNIT_ID':
        const v = String.fromEnvironment('ADMOB_APP_OPEN_AD_UNIT_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'ADMOB_NATIVE_AD_UNIT_ID':
        const v = String.fromEnvironment('ADMOB_NATIVE_AD_UNIT_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'FIREBASE_ANDROID_API_KEY':
        const v = String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'FIREBASE_ANDROID_APP_ID':
        const v = String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'FIREBASE_ANDROID_PROJECT_ID':
        const v = String.fromEnvironment('FIREBASE_ANDROID_PROJECT_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'FIREBASE_ANDROID_SENDER_ID':
        const v = String.fromEnvironment('FIREBASE_ANDROID_SENDER_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'FIREBASE_ANDROID_STORAGE_BUCKET':
        const v = String.fromEnvironment('FIREBASE_ANDROID_STORAGE_BUCKET', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'FIREBASE_IOS_API_KEY':
        const v = String.fromEnvironment('FIREBASE_IOS_API_KEY', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'FIREBASE_IOS_APP_ID':
        const v = String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'FIREBASE_IOS_PROJECT_ID':
        const v = String.fromEnvironment('FIREBASE_IOS_PROJECT_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'FIREBASE_IOS_SENDER_ID':
        const v = String.fromEnvironment('FIREBASE_IOS_SENDER_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'FIREBASE_IOS_BUNDLE_ID':
        const v = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'FIREBASE_IOS_STORAGE_BUCKET':
        const v = String.fromEnvironment('FIREBASE_IOS_STORAGE_BUCKET', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      case 'FREEPIK_BASE_URL':
        const v = String.fromEnvironment('FREEPIK_BASE_URL', defaultValue: '');
        return v.isNotEmpty ? v : (fromDotenv.isEmpty ? fallback : fromDotenv);
      default:
        return fromDotenv.isEmpty ? fallback : fromDotenv;
    }
  }

  static bool _parseBool(String? v, bool fallback) {
    if (v == null || v.trim().isEmpty) return fallback;
    final t = v.trim().toLowerCase();
    return t == 'true' || t == '1';
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
