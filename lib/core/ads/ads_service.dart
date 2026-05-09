import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

// Raonson App ID: 19230220
// Banner Unit ID: R-M-19230220-1
// Interstitial Unit ID: R-M-19230220-2

class AdsService {
  static const _bannerId = 'R-M-19230220-1';
  static const _interstitialId = 'R-M-19230220-2';

  static Future<void> init() async {
    await MobileAds.initialize();
  }

  static Future<void> showInterstitial() async {
    final loader = await InterstitialAdLoader.create(
      onAdLoaded: (ad) {
        ad.show();
        ad.destroy();
      },
      onAdFailedToLoad: (_, __) {},
    );
    await loader.loadAd(
      adRequestConfiguration: const AdRequestConfiguration(
        adUnitId: _interstitialId,
      ),
    );
  }
}

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loader = await BannerAdLoader.create(
      onAdLoaded: (ad) {
        setState(() { _ad = ad; _loaded = true; });
      },
      onAdFailedToLoad: (_, __) {},
    );
    await loader.loadAd(
      adRequestConfiguration: const AdRequestConfiguration(
        adUnitId: 'R-M-19230220-1',
      ),
    );
  }

  @override
  void dispose() {
    _ad?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return AdWidget(ad: _ad!);
  }
}
