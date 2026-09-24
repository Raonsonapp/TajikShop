import 'package:flutter_test/flutter_test.dart';
import 'package:tajikshop/core/ads/ad_config.dart';

/// Муҳофиз аз хатои «ID-ҳои воқеиро гузоштам, вале пул намеояд».
///
/// Реклама аз рӯи `useDemoAds` интихоб мешавад. Агар ID-ҳои воқеӣ гузошта
/// шаванд, вале ин калид `true` монад, барнома ҳамоно рекламаи ДЕМОи
/// Yandex-ро нишон медиҳад — он кор мекунад, зебо менамояд, вале ҳеҷ пул
/// намедиҳад. Ин хато дар кор ҳеҷ гоҳ намоён намешавад.
void main() {
  test('ID-ҳои воқеӣ гузошта шуда бошанд, реҷаи демо бояд хомӯш бошад', () {
    if (AdConfig.hasRealIds) {
      expect(AdConfig.usingDemo, isFalse,
          reason: 'ID-ҳои воқеӣ ҳастанд, вале useDemoAds=true — '
              'реклама демо мемонад ва даромад намедиҳад. '
              'Дар ad_config.dart useDemoAds=false кунед.');
    }
  });

  test('реҷаи демо бе ID-и воқеӣ иҷозат аст (ҳолати ҳозира)', () {
    if (!AdConfig.hasRealIds) {
      // Ҳанӯз ID-и воқеӣ нест — демо кор мекунад, вале даромад нест.
      expect(AdConfig.enabled, isTrue);
    }
  });

  test('ҳар N амал як interstitial — маънои дуруст дорад', () {
    expect(AdConfig.interstitialEveryNActions, greaterThan(0));
  });
}
