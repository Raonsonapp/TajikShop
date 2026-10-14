import 'package:flutter_test/flutter_test.dart';
import 'package:tajikshop/core/app_l10n.dart';
import 'package:tajikshop/core/l10n/home_search_l10n.dart';
import 'package:tajikshop/providers/locale_provider.dart';

/// Матнҳои саҳифаи асосӣ ва ҷустуҷӯ.
///
/// Ин ду экрани аввалине ҳастанд, ки ҳар корбар мебинад — ва ҳамаи
/// матнашон дар код МЕХКӮБ буд. Корбари русзабон забонро ба русӣ
/// мегузошт ва ҳамон «Машҳуртарин», «Филтрҳо»-ро медид; аз ҳама
/// бадтар — ӯ фикр мекунад, ки интихоби забон КОР НАМЕКУНАД.
void main() {
  for (final locale in LocaleNotifier.supported) {
    final l = AppL10n(locale.languageCode);

    test('«${locale.languageCode}» — ҳамаи матнҳо ҳастанд', () {
      for (final s in [
        l.greeting,
        l.barcodeNotFound('123'),
        l.allWord,
        l.specialOffer,
        l.summerSale,
        l.summerSaleHint,
        l.mostPopular,
        l.bestSelling,
        l.flashDeals,
        l.storyPublished,
        l.storyFailed,
        l.myStory,
        l.firstStoryHint,
        l.cargoFromChina,
        l.cargoHint,
        l.nearbyShopsTitle,
        l.nearbyShopsHint,
        l.sortNew,
        l.sortCheap,
        l.sortExpensive,
        l.filtersTitle,
        l.filtersClear,
        l.priceSomoni,
        l.minRating,
        l.categoryWord,
        l.sortWord,
        l.applyWord,
        l.priceFrom,
        l.priceTo,
      ]) {
        expect(s.trim(), isNotEmpty);
      }
    });

    test('«${locale.languageCode}» — коди штрих дар матн мемонад', () {
      expect(l.barcodeNotFound('4601234'), contains('4601234'));
    });

    test('«${locale.languageCode}» — 7 пешниҳоди ҷустуҷӯ', () {
      expect(l.searchSuggestions.length, 7);
      for (final s in l.searchSuggestions) {
        expect(s.trim(), isNotEmpty);
      }
    });
  }

  /// ⚠️ Муҳимтарин санҷиши ин файл.
  ///
  /// Калидҳои тартиб ба СЕРВЕР мераванд (`price_asc`, `popular`).
  /// Агар онҳо аз забон ба забон фарқ кунанд, тартиб дар як забон кор
  /// мекунад ва дар дигаре хомӯшона вайрон мешавад — ва инро касе
  /// намебинад, зеро хато нест, танҳо натиҷаи нодуруст.
  test('калидҳои тартиб дар ҳар се забон ЯКХЕЛА', () {
    final keys = AppL10n('tg').sortOptions.keys.toList();
    expect(keys, [null, 'price_asc', 'price_desc', 'popular']);
    for (final lang in ['ru', 'en']) {
      expect(AppL10n(lang).sortOptions.keys.toList(), keys,
          reason: 'калидҳои «$lang» фарқ мекунанд — тартиб дар он забон '
              'хомӯшона вайрон мешавад');
    }
  });

  test('тарҷумаҳо такрор нашудаанд', () {
    final tg = AppL10n('tg');
    final ru = AppL10n('ru');
    final en = AppL10n('en');
    for (final get in <String Function(AppL10n)>[
      (x) => x.mostPopular,
      (x) => x.bestSelling,
      (x) => x.filtersTitle,
      (x) => x.applyWord,
      (x) => x.sortCheap,
    ]) {
      expect(get(tg), isNot(get(ru)));
      expect(get(ru), isNot(get(en)));
      expect(get(tg), isNot(get(en)));
    }
  });
}
