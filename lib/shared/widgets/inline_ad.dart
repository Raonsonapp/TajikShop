import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';
import '../../core/ads/ad_config.dart';
import '../../core/ads/ad_service.dart';

/// Баннери реклама (Yandex, sticky) — дар поёни экран.
/// Интизори омодагии SDK мешавад, баъд бор мекунад (то «холӣ» намонад).
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _banner;
  StreamSubscription<BannerAdLoadState>? _sub;
  bool _loaded = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final width = MediaQuery.of(context).size.width.toInt();
    AdService.instance.initialized.then((_) {
      if (mounted) _load(width);
    });
  }

  void _load(int width) {
    if (!AdService.instance.ready || AdConfig.bannerAdUnitId.isEmpty) return;
    final banner = BannerAd(adSize: BannerAdSize.sticky(width: width));
    _sub = banner.loadStateStream.listen((state) {
      if (state is BannerAdLoadStateLoaded) {
        if (mounted) setState(() => _loaded = true);
      }
    });
    _banner = banner;
    banner.load(AdRequest(adUnitId: AdConfig.bannerAdUnitId));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _banner?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _banner == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.bottomCenter,
      child: AdWidget(bannerAd: _banner!),
    );
  }
}

/// Блоки калони реклама (Yandex inline) дар дохили feed — мисли маркетплейси воқеӣ.
class AdMrec extends StatefulWidget {
  const AdMrec({super.key});
  @override
  State<AdMrec> createState() => _AdMrecState();
}

class _AdMrecState extends State<AdMrec> {
  BannerAd? _banner;
  StreamSubscription<BannerAdLoadState>? _sub;
  bool _loaded = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final width = MediaQuery.of(context).size.width.toInt();
    AdService.instance.initialized.then((_) {
      if (mounted) _load(width);
    });
  }

  void _load(int width) {
    if (!AdService.instance.ready || AdConfig.mrecAdUnitId.isEmpty) return;
    final banner = BannerAd(
      adSize: BannerAdSize.inline(width: width - 32, maxHeight: 300),
    );
    _sub = banner.loadStateStream.listen((state) {
      if (state is BannerAdLoadStateLoaded) {
        if (mounted) setState(() => _loaded = true);
      }
    });
    _banner = banner;
    banner.load(AdRequest(adUnitId: AdConfig.mrecAdUnitId));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _banner?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _banner == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(child: AdWidget(bannerAd: _banner!)),
    );
  }
}
