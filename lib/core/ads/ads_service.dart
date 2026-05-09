import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

/// Raonson ID: 19230220
/// Banner ID: R-M-19230220-1
/// Interstitial ID: R-M-19230220-2

class AdsService {
  static const _bannerId = 'R-M-19230220-1';
  static const _interstitialId = 'R-M-19230220-2';

  static Future<void> init() async {
    await MobileAds.initialize();
  }

  static BannerAdWidget buildBanner() {
    return BannerAdWidget(
      adUnitId: _bannerId,
      adSize: AdSize.sticky(width: 320),
      onAdLoaded: (_) {},
      onAdFailedToLoad: (_, __) {},
    );
  }

  static Future<void> showInterstitial() async {
    final loader = await InterstitialAdLoader.create(
      onAdLoaded: (ad) => ad.show(),
      onAdFailedToLoad: (_, __) {},
    );
    await loader.loadAd(adRequestConfiguration: AdRequestConfiguration(adUnitId: _interstitialId));
  }
}

/// Widget - banner рекламро дар саҳифа нишон медиҳад
class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: AdsService.buildBanner(),
    );
  }
}
