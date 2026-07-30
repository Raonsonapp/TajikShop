import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/foundation.dart';
import 'ad_config.dart';

/// Хидмати марказии реклама (AppLovin MAX).
/// - SDK-ро як маротиба инициализатсия мекунад.
/// - Interstitial-ро пешакӣ бор карда, бо frequency-cap нишон медиҳад.
/// Ҳангоми набудани SDK Key ҳамаи амалҳо no-op мешаванд (барнома вайрон намешавад).
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;
  bool _interstitialLoaded = false;
  int _actionCounter = 0;

  bool get ready => _initialized && AdConfig.enabled;

  Future<void> init() async {
    if (_initialized || !AdConfig.enabled) return;
    try {
      if (AdConfig.testDeviceAdvertisingIds.isNotEmpty) {
        AppLovinMAX.setTestDeviceAdvertisingIds(
            AdConfig.testDeviceAdvertisingIds);
      }
      final conf = await AppLovinMAX.initialize(AdConfig.sdkKey);
      if (conf == null) return;
      _initialized = true;
      _setupInterstitial();
      _loadInterstitial();
    } catch (e) {
      debugPrint('AdService init failed: $e');
    }
  }

  // ── Interstitial ──
  void _setupInterstitial() {
    if (AdConfig.interstitialAdUnitId.isEmpty) return;
    AppLovinMAX.setInterstitialListener(InterstitialListener(
      onAdLoadedCallback: (ad) => _interstitialLoaded = true,
      onAdLoadFailedCallback: (adUnitId, error) {
        _interstitialLoaded = false;
      },
      onAdDisplayedCallback: (ad) {},
      onAdDisplayFailedCallback: (ad, error) => _loadInterstitial(),
      onAdClickedCallback: (ad) {},
      onAdHiddenCallback: (ad) {
        _interstitialLoaded = false;
        _loadInterstitial(); // барои дафъаи оянда бор кунед
      },
    ));
  }

  void _loadInterstitial() {
    if (!ready || AdConfig.interstitialAdUnitId.isEmpty) return;
    AppLovinMAX.loadInterstitial(AdConfig.interstitialAdUnitId);
  }

  /// Ҳар N амал як interstitial нишон медиҳад (агар омода бошад).
  void maybeShowInterstitial() {
    if (!ready || AdConfig.interstitialAdUnitId.isEmpty) return;
    _actionCounter++;
    if (_actionCounter % AdConfig.interstitialEveryNActions != 0) return;
    if (_interstitialLoaded) {
      AppLovinMAX.showInterstitial(AdConfig.interstitialAdUnitId);
    } else {
      _loadInterstitial();
    }
  }
}
