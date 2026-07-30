import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/ads/ad_config.dart';
import '../../core/ads/ad_service.dart';

/// Баннери реклама (AdMob 320×50) — дар поёни экран.
/// Агар реклама фаъол набошад → ҳеҷ чиз намоиш намедиҳад.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!AdService.instance.ready || AdConfig.bannerAdUnitId.isEmpty) return;
    final ad = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    );
    ad.load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      height: AdSize.banner.height.toDouble(),
      width: double.infinity,
      child: Center(
        child: SizedBox(
          width: AdSize.banner.width.toDouble(),
          height: AdSize.banner.height.toDouble(),
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}

/// MREC (300×250) — блоки калони реклама дар дохили feed (мисли маркетплейси воқеӣ).
class AdMrec extends StatefulWidget {
  const AdMrec({super.key});
  @override
  State<AdMrec> createState() => _AdMrecState();
}

class _AdMrecState extends State<AdMrec> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!AdService.instance.ready || AdConfig.mrecAdUnitId.isEmpty) return;
    final ad = BannerAd(
      adUnitId: AdConfig.mrecAdUnitId,
      size: AdSize.mediumRectangle, // 300×250
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    );
    ad.load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: AdSize.mediumRectangle.width.toDouble(),
          height: AdSize.mediumRectangle.height.toDouble(),
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}
