import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

/// Хидмати марказии реклама (Google AdMob).
/// - SDK-ро як маротиба инициализатсия мекунад.
/// - Виджетҳо тавассути [initialized] интизори омодагӣ мешаванд (то реклама
///   пеш аз init бор нашавад — ин сабаби «холӣ мондан» буд).
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  final Completer<void> _initDone = Completer<void>();
  bool _initialized = false;
  InterstitialAd? _interstitial;
  int _actionCounter = 0;

  /// То инициализатсия анҷом ёбад (муваффақ ё нокас) пур мешавад.
  Future<void> get initialized => _initDone.future;

  bool get ready => _initialized && AdConfig.enabled;

  Future<void> init() async {
    if (_initialized) return;
    if (!AdConfig.enabled) {
      if (!_initDone.isCompleted) _initDone.complete();
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitial();
    } catch (e) {
      debugPrint('AdService init failed: $e');
    } finally {
      if (!_initDone.isCompleted) _initDone.complete();
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
              _loadInterstitial();
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
      _interstitial = null;
    } else {
      _loadInterstitial();
    }
  }
}
