import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
  }

  BannerAd createBannerAd({
    required String adUnitId,
    required BannerAdListener listener,
  }) {
    return BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      listener: listener,
      request: const AdRequest(),
    );
  }
}

