import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

/// Хидмати марказии реклама (Google AdMob).
/// - SDK-ро як маротиба инициализатсия мекунад.
/// - Interstitial-ро пешакӣ бор карда, бо frequency-cap нишон медиҳад.
/// Ҳангоми ғайрифаъол буданаш ҳамаи амалҳо no-op мешаванд.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;
  InterstitialAd? _interstitial;
  int _actionCounter = 0;

  bool get ready => _initialized && AdConfig.enabled;

  Future<void> init() async {
    if (_initialized || !AdConfig.enabled) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitial();
    } catch (e) {
      debugPrint('AdService init failed: $e');
    }
  }

  // ── Interstitial ──
  void _loadInterstitial() {
    if (!ready || AdConfig.interstitialAdUnitId.isEmpty) return;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial = null;
              _loadInterstitial(); // барои дафъаи оянда
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _interstitial = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (err) {
          _interstitial = null;
          debugPrint('Interstitial load failed: ${err.message}');
        },
      ),
    );
  }

  /// Ҳар N амал як interstitial нишон медиҳад (агар омода бошад).
  void maybeShowInterstitial() {
    if (!ready) return;
    _actionCounter++;
    if (_actionCounter % AdConfig.interstitialEveryNActions != 0) return;
    final ad = _interstitial;
    if (ad != null) {
      ad.show();
      _interstitial = null; // callback дубора бор мекунад
    } else {
      _loadInterstitial();
    }
  }
}
