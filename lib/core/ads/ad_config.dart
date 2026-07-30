/// ═══════════════════════════════════════════════════════════════════════════
///  AppLovin MAX — конфигуратсияи реклама (даромад)
///
///  ⚠️  БАРОИ ФАЪОЛ КАРДАНИ РЕКЛАМА:
///  1. Дар https://dashboard.applovin.com ҳисоб созед (ройгон).
///  2. SDK Key-ро аз «Account → Keys» гиред → ба [_sdkKeyDefault] гузоред.
///  3. Дар «MAX → Ad Units» барои Android 4 воҳиди реклама созед:
///       Banner, MREC, Interstitial, Rewarded — ва ID-ҳояшонро дар поён гузоред.
///  4. Барномаро аз нав build кунед.
///
///  То он даме ки SDK Key холӣ бошад, реклама ХОМӮШ аст — барнома бехато кор мекунад.
///  ID-ҳоро метавон бо --dart-define низ дод (барои CI/секрет нигоҳ доштан).
/// ═══════════════════════════════════════════════════════════════════════════
class AdConfig {
  // ── SDK Key (аз AppLovin dashboard → Account → Keys) ──
  static const String _sdkKeyDefault = '';
  static const String sdkKey =
      String.fromEnvironment('APPLOVIN_SDK_KEY', defaultValue: _sdkKeyDefault);

  // ── Воҳидҳои реклама (Ad Unit IDs) ──
  static const String bannerAdUnitId = String.fromEnvironment(
      'APPLOVIN_BANNER_ID',
      defaultValue: '');
  static const String mrecAdUnitId = String.fromEnvironment(
      'APPLOVIN_MREC_ID',
      defaultValue: '');
  static const String interstitialAdUnitId = String.fromEnvironment(
      'APPLOVIN_INTERSTITIAL_ID',
      defaultValue: '');
  static const String rewardedAdUnitId = String.fromEnvironment(
      'APPLOVIN_REWARDED_ID',
      defaultValue: '');

  /// Реклама умуман фаъол аст? (SDK Key лозим)
  static bool get enabled => sdkKey.trim().isNotEmpty;

  /// Дар режими санҷиш дастгоҳро тест-дастгоҳ эълон кунед (advertising ID-ро гузоред).
  static const List<String> testDeviceAdvertisingIds = [];

  /// Байни намоиши interstitial-ҳо чанд амал гузарад (frequency cap).
  static const int interstitialEveryNActions = 4;
}
