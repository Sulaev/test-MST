import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';

typedef AdEventLogger = Future<void> Function(String eventName, Map<String, dynamic> params);

class AdmobService {
  AdmobService({this.onEvent});

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  AppOpenAd? _appOpenAd;

  final ValueNotifier<bool> isBannerReady = ValueNotifier<bool>(false);

  final AdEventLogger? onEvent;

  Future<void> _log(String event, Map<String, dynamic> params) async {
    final AdEventLogger? logger = onEvent;
    if (logger == null) {
      return;
    }
    await logger(event, params);
  }

  Future<void> initialize(AppConfig config) async {
    if (!config.enableAds || config.admobAppId.trim().isEmpty) {
      return;
    }
    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      // Ignore init failures in unsupported environments.
    }
  }

  Future<void> loadBanner(AppConfig config) async {
    if (!config.enableAds || config.admobBannerAdUnitId.trim().isEmpty) {
      return;
    }
    _bannerAd?.dispose();
    isBannerReady.value = false;
    final Completer<void> completer = Completer<void>();
    final BannerAd banner = BannerAd(
      adUnitId: config.admobBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          isBannerReady.value = true;
          unawaited(_log('ad_banner_loaded', <String, dynamic>{
            'ad_unit_id': config.admobBannerAdUnitId,
          }));
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          isBannerReady.value = false;
          unawaited(_log('ad_banner_load_failed', <String, dynamic>{
            'ad_unit_id': config.admobBannerAdUnitId,
            'error_code': error.code,
            'error_message': error.message,
          }));
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onAdOpened: (Ad ad) {
          unawaited(_log('ad_banner_opened', <String, dynamic>{
            'ad_unit_id': config.admobBannerAdUnitId,
          }));
        },
        onAdClosed: (Ad ad) {
          unawaited(_log('ad_banner_closed', <String, dynamic>{
            'ad_unit_id': config.admobBannerAdUnitId,
          }));
        },
        onAdClicked: (Ad ad) {
          unawaited(_log('ad_banner_clicked', <String, dynamic>{
            'ad_unit_id': config.admobBannerAdUnitId,
          }));
        },
      ),
    );
    _bannerAd = banner;
    banner.load();
    await completer.future;
  }

  Widget? buildBannerWidget() {
    final BannerAd? banner = _bannerAd;
    if (!isBannerReady.value || banner == null) {
      return null;
    }
    return SizedBox(
      width: banner.size.width.toDouble(),
      height: banner.size.height.toDouble(),
      child: AdWidget(ad: banner),
    );
  }

  Future<void> preloadInterstitial(AppConfig config) async {
    if (!config.enableAds || config.admobInterstitialAdUnitId.trim().isEmpty) {
      return;
    }
    _interstitialAd?.dispose();
    _interstitialAd = null;
    await InterstitialAd.load(
      adUnitId: config.admobInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          unawaited(_log('ad_interstitial_loaded', <String, dynamic>{
            'ad_unit_id': config.admobInterstitialAdUnitId,
          }));
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          unawaited(_log('ad_interstitial_load_failed', <String, dynamic>{
            'ad_unit_id': config.admobInterstitialAdUnitId,
            'error_code': error.code,
            'error_message': error.message,
          }));
        },
      ),
    );
  }

  Future<void> showInterstitialIfAvailable(AppConfig config) async {
    if (!config.enableAds || config.admobInterstitialAdUnitId.trim().isEmpty) {
      return;
    }
    final InterstitialAd? ad = _interstitialAd;
    if (ad == null) {
      await preloadInterstitial(config);
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        unawaited(_log('ad_interstitial_shown', <String, dynamic>{
          'ad_unit_id': config.admobInterstitialAdUnitId,
        }));
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _interstitialAd = null;
        unawaited(_log('ad_interstitial_dismissed', <String, dynamic>{
          'ad_unit_id': config.admobInterstitialAdUnitId,
        }));
        preloadInterstitial(config);
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _interstitialAd = null;
        unawaited(_log('ad_interstitial_show_failed', <String, dynamic>{
          'ad_unit_id': config.admobInterstitialAdUnitId,
          'error_code': error.code,
          'error_message': error.message,
        }));
        preloadInterstitial(config);
      },
    );
    ad.show();
  }

  Future<void> preloadRewarded(AppConfig config) async {
    if (!config.enableAds || config.admobRewardedAdUnitId.trim().isEmpty) {
      return;
    }
    await RewardedAd.load(
      adUnitId: config.admobRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd?.dispose();
          _rewardedAd = ad;
          unawaited(_log('ad_rewarded_loaded', <String, dynamic>{
            'ad_unit_id': config.admobRewardedAdUnitId,
          }));
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          unawaited(_log('ad_rewarded_load_failed', <String, dynamic>{
            'ad_unit_id': config.admobRewardedAdUnitId,
            'error_code': error.code,
            'error_message': error.message,
          }));
        },
      ),
    );
  }

  Future<void> preloadAppOpen(AppConfig config) async {
    if (!config.enableAds || config.admobAppOpenAdUnitId.trim().isEmpty) {
      return;
    }
    await AppOpenAd.load(
      adUnitId: config.admobAppOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          _appOpenAd?.dispose();
          _appOpenAd = ad;
          unawaited(_log('ad_app_open_loaded', <String, dynamic>{
            'ad_unit_id': config.admobAppOpenAdUnitId,
          }));
        },
        onAdFailedToLoad: (LoadAdError error) {
          _appOpenAd = null;
          unawaited(_log('ad_app_open_load_failed', <String, dynamic>{
            'ad_unit_id': config.admobAppOpenAdUnitId,
            'error_code': error.code,
            'error_message': error.message,
          }));
        },
      ),
    );
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _appOpenAd?.dispose();
    isBannerReady.dispose();
  }
}
