import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:yandex_mobileads/mobile_ads.dart';
import 'ad_config.dart';

/// Хидмати марказии реклама (Yandex Mobile Ads).
/// - SDK-ро як маротиба инициализатсия мекунад.
/// - Interstitial-ро пешакӣ бор карда, бо frequency-cap нишон медиҳад.
/// Виджетҳо тавассути [initialized] интизори омодагӣ мешаванд.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  final Completer<void> _initDone = Completer<void>();
  bool _initialized = false;
  InterstitialAd? _interstitial;
  int _actionCounter = 0;

  /// То инициализатсия анҷом ёбад пур мешавад.
  Future<void> get initialized => _initDone.future;

  bool get ready => _initialized && AdConfig.enabled;

  Future<void> init() async {
    if (_initialized) return;
    if (!AdConfig.enabled) {
      if (!_initDone.isCompleted) _initDone.complete();
      return;
    }
    try {
      await YandexAds.initialize();
      _initialized = true;
      _loadInterstitial();
    } catch (e) {
      debugPrint('AdService init failed: $e');
    } finally {
      if (!_initDone.isCompleted) _initDone.complete();
    }
  }

  // ── Interstitial ──
  Future<void> _loadInterstitial() async {
    if (!ready || AdConfig.interstitialAdUnitId.isEmpty) return;
    try {
      final loader = InterstitialAdLoader();
      final ad = await loader.loadAd(
        adRequest: AdRequest(adUnitId: AdConfig.interstitialAdUnitId),
      );
      await ad.setAdEventListener(
        eventListener: InterstitialAdEventListener(
          onAdDismissed: () {
            ad.destroy();
            _interstitial = null;
            _loadInterstitial();
          },
          onAdFailedToShow: (error) {
            ad.destroy();
            _interstitial = null;
            _loadInterstitial();
          },
        ),
      );
      _interstitial = ad;
    } catch (e) {
      _interstitial = null;
      debugPrint('Interstitial load failed: $e');
    }
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
