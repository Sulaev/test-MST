import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';

class AdmobService {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  AppOpenAd? _appOpenAd;

  final ValueNotifier<bool> isBannerReady = ValueNotifier<bool>(false);

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
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          isBannerReady.value = false;
          if (!completer.isCompleted) {
            completer.complete();
          }
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
        },
        onAdFailedToLoad: (_) {
          _interstitialAd = null;
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
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _interstitialAd = null;
        preloadInterstitial(config);
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _interstitialAd = null;
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
        },
        onAdFailedToLoad: (_) {
          _rewardedAd = null;
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
        },
        onAdFailedToLoad: (_) {
          _appOpenAd = null;
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
