import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';
import '../../core/ads/ad_config.dart';
import '../../core/ads/ad_service.dart';

/// Баннери реклама (Yandex, sticky) — дар поёни экран.
/// Интизори омодагии SDK мешавад, баъд бор мекунад (то «холӣ» намонад).

/// Рекламаро БЕХАТАР нест мекунад.
///
/// `.catchError` ин ҷо КИФОЯ НЕСТ, ва ман инро аз рӯи коди худи плагин
/// тасдиқ кардам. `yandex_mobileads/ad.dart:28` чунин аст:
///
///     _channel.invokeMethod('destroy');     // бе `return`, бе `await`
///
/// Яъне Future-и `invokeMethod` ба ҷое намеравад. `BannerAd.destroy()`
/// муваффақона тамом мешавад, ва хатои дарунӣ ДОШТА НАШУДА мемонад — пас
/// ягон `.catchError`-и мо ба он намерасад.
///
/// Агар тарафи нативӣ объекти рекламаро насохта бошад (реклама бор нашуд
/// ё SDK омода набуд), он `MissingPluginException` мепартояд. Дар барнома
/// онро `PlatformDispatcher.onError` фурӯ мебарад, пас касе намебинад —
/// вале дар тести эмулятор он тамоми тестро мешиканад ва хатои АСЛИРО
/// пинҳон мекунад.
///
/// `runZonedGuarded` хатоҳои async-и дохили зонаро медорад, аз ҷумла
/// Future-и партофташудаи плагин.
void _safeDestroyAd(BannerAd? ad) {
  if (ad == null) return;
  runZonedGuarded(() {
    ad.destroy();
  }, (_, __) {
    // Хатои плагини сеюм ҳангоми пӯшидани экран — барои мо коре нест.
  });
}

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
    _safeDestroyAd(_banner);
    _banner = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _banner == null) return const SizedBox.shrink();
    // ⚠️ AdWidget платформа-view аст ва андозаи хоси худро надорад. Агар
    // констрейнти аниқ дода нашавад, view-и нативӣ метавонад дар кунҷи
    // чапи боло (0,0) ҳамчун росткунҷаи хокистарранг часпад. Барои ҳамин
    // ҳатман бо баландии муайян маҳдуд мекунем.
    return SizedBox(
      width: double.infinity,
      height: _kStickyBannerHeight,
      child: AdWidget(bannerAd: _banner!),
    );
  }
}

/// Баландии баннери sticky (dp) — платформа-view-ро маҳдуд мекунад.
const double _kStickyBannerHeight = 60;

/// Баландии блоки inline (MREC) — платформа-view-ро маҳдуд мекунад.
const double _kInlineAdHeight = 250;

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
    _safeDestroyAd(_banner);
    _banner = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _banner == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: _kInlineAdHeight,
        child: AdWidget(bannerAd: _banner!),
      ),
    );
  }
}
