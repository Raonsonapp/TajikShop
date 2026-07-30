import 'dart:io' show Platform;

/// ═══════════════════════════════════════════════════════════════════════════
///  Google AdMob — конфигуратсияи реклама (даромад)
///
///  🟢 ҲОЗИР бо ID-ҳои ТЕСТӢ кор мекунад — реклама фавран пайдо мешавад
///     (вале test-реклама пул НАМЕдиҳад).
///
///  💰 БАРОИ ДАРОМАДИ ВОҚЕӢ:
///  1. Ба https://admob.google.com равед (бо ҳамон Gmail — аз Тоҷикистон кушода мешавад).
///  2. App илова кунед (Android) → App ID-ро гиред (ca-app-pub-XXXX~YYYY).
///  3. 3 воҳиди реклама созед: Banner, Interstitial, ва боз як Banner барои MREC.
///  4. ID-ҳои воқеиро дар поён ба ҷои ID-ҳои тестӣ гузоред.
///  5. ⚠️ App ID-ро ИНЧУНИН дар android/app/src/main/AndroidManifest.xml
///        (meta-data com.google.android.gms.ads.APPLICATION_ID) иваз кунед.
///  6. Барномаро аз нав build кунед.
/// ═══════════════════════════════════════════════════════════════════════════
class AdConfig {
  /// Режими тест — то ID-ҳои воқеӣ нагузоред, ҳамин мемонад.
  /// Баъди гузоштани ID-ҳои воқеӣ — ба `false` гузоред.
  static const bool useTestAds = true;

  // ── ID-ҳои ТЕСТИИ расмии Google (ҳамеша кор мекунанд) ──
  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testMrec = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';

  // ── ID-ҳои ВОҚЕИИ шумо (аз AdMob dashboard) — useTestAds=false кунед ──
  static const String _realBannerAndroid = ''; // ca-app-pub-.../...
  static const String _realMrecAndroid = '';
  static const String _realInterstitialAndroid = '';

  static bool get _isAndroid {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return true;
    }
  }

  static String get bannerAdUnitId =>
      useTestAds ? _testBanner : (_isAndroid ? _realBannerAndroid : '');
  static String get mrecAdUnitId =>
      useTestAds ? _testMrec : (_isAndroid ? _realMrecAndroid : '');
  static String get interstitialAdUnitId => useTestAds
      ? _testInterstitial
      : (_isAndroid ? _realInterstitialAndroid : '');

  /// Реклама умуман фаъол аст?
  static bool get enabled =>
      useTestAds || bannerAdUnitId.isNotEmpty || interstitialAdUnitId.isNotEmpty;

  /// Байни намоиши interstitial-ҳо чанд амал гузарад (frequency cap).
  static const int interstitialEveryNActions = 4;
}
