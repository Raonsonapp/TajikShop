import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';
import '../../core/ads/ad_config.dart';
import '../../core/ads/ad_service.dart';

/// Баннери реклама (AppLovin MAX) — дар поёни экран ё дохили feed.
/// Агар реклама фаъол набошад ё ID холӣ бошад → ҳеҷ чиз намоиш намедиҳад.
class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AdService.instance.ready || AdConfig.bannerAdUnitId.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: MaxAdView(
        adUnitId: AdConfig.bannerAdUnitId,
        adFormat: AdFormat.banner,
      ),
    );
  }
}

/// MREC (300×250) — блоки калони реклама дар дохили feed (мисли маркетплейси воқеӣ).
class AdMrec extends StatelessWidget {
  const AdMrec({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AdService.instance.ready || AdConfig.mrecAdUnitId.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 300,
          height: 250,
          child: MaxAdView(
            adUnitId: AdConfig.mrecAdUnitId,
            adFormat: AdFormat.mrec,
          ),
        ),
      ),
    );
  }
}
