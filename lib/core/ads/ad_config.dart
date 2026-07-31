/// ═══════════════════════════════════════════════════════════════════════════
///  Yandex Mobile Ads — конфигуратсияи реклама (даромад)
///
///  🟢 ҲОЗИР бо ID-ҳои ДЕМОи расмии Yandex кор мекунад — реклама фавран
///     пайдо мешавад (вале демо пул НАМЕдиҳад).
///
///  💰 БАРОИ ДАРОМАДИ ВОҚЕӢ:
///  1. Ба https://partner.yandex.ru равед (аз Тоҷикистон кушода мешавад ✅).
///  2. «Мобильные приложения» → барномаи худро илова кунед (Android).
///  3. Блокҳои реклама созед: Banner, Interstitial. Ҳар кадом `R-M-XXXXXX-Y` медиҳад.
///  4. ID-ҳои воқеиро дар поён гузоред ва `useDemoAds=false` кунед.
///  5. Барномаро аз нав build кунед.
/// ═══════════════════════════════════════════════════════════════════════════
class AdConfig {
  /// Режими демо — то ID-ҳои воқеӣ нагузоред, ҳамин мемонад.
  /// Баъди гузоштани ID-ҳои воқеӣ → ба `false` гузоред.
  static const bool useDemoAds = true;

  // ── ID-ҳои ДЕМОи расмии Yandex (ҳамеша кор мекунанд) ──
  static const String _demoBanner = 'demo-banner-yandex';
  static const String _demoInterstitial = 'demo-interstitial-yandex';

  // ── ID-ҳои ВОҚЕИИ шумо (аз partner.yandex.ru) — useDemoAds=false кунед ──
  static const String _realBanner = ''; // R-M-XXXXXX-1
  static const String _realMrec = ''; // R-M-XXXXXX-2
  static const String _realInterstitial = ''; // R-M-XXXXXX-3

  static String get bannerAdUnitId => useDemoAds ? _demoBanner : _realBanner;
  static String get mrecAdUnitId => useDemoAds ? _demoBanner : _realMrec;
  static String get interstitialAdUnitId =>
      useDemoAds ? _demoInterstitial : _realInterstitial;

  /// Реклама умуман фаъол аст?
  static bool get enabled =>
      useDemoAds || bannerAdUnitId.isNotEmpty || interstitialAdUnitId.isNotEmpty;

  /// Байни намоиши interstitial-ҳо чанд амал гузарад (frequency cap).
  static const int interstitialEveryNActions = 4;
}
