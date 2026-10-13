import 'package:flutter_test/flutter_test.dart';
import 'package:tajikshop/core/app_l10n.dart';
import 'package:tajikshop/core/l10n/suppliers_l10n.dart';
import 'package:tajikshop/providers/locale_provider.dart';

/// Матнҳои ҷустуҷӯи таъминкунанда дар се забон.
void main() {
  for (final locale in LocaleNotifier.supported) {
    final l = AppL10n(locale.languageCode);

    test('«${locale.languageCode}» — ҳамаи матнҳо ҳастанд', () {
      for (final s in [
        l.supTitle,
        l.supExplain,
        l.supEmpty,
        l.supOnlyVerified,
        l.supSearchHint,
        l.supRegionHint,
        l.supVerifiedData,
        l.supSelfReported,
        l.supNotEnoughOrders,
        l.supWholesaleItems,
        l.supNoWholesale,
        l.supVerifiedBadge,
      ]) {
        expect(s.trim(), isNotEmpty);
        expect(s.contains(r'$'), isFalse, reason: 'рақами ивазнашуда: $s');
      }
    });

    test('«${locale.languageCode}» — матнҳои рақамдор', () {
      expect(l.supOrdersDone(12), contains('12'));
      expect(l.supCompletionRate(87), contains('87'));
      expect(l.supProducts(5), contains('5'));
      expect(l.supRating('4.6', 23), allOf(contains('4.6'), contains('23')));
      expect(l.supSince('2025-03'), contains('2025-03'));
      expect(l.supWholesaleFrom('80', 10),
          allOf(contains('80'), contains('10')));

      for (final s in [
        l.supOrdersDone(12),
        l.supCompletionRate(87),
        l.supProducts(5),
        l.supRating('4.6', 23),
        l.supSince('2025-03'),
        l.supWholesaleFrom('80', 10),
      ]) {
        expect(s.contains(r'$'), isFalse, reason: 'рақами ивазнашуда: $s');
      }
    });
  }

  // Ин фарқ дар UX ҳалкунанда аст: харидор бояд бидонад, кадом рақамро
  // платформа ҳисоб кардааст ва кадом сатрро худи фурӯшанда навиштааст.
  test('«тасдиқшуда» ва «аз гуфтаи фурӯшанда» матни ГУНОГУН доранд', () {
    for (final lang in ['tg', 'ru', 'en']) {
      final l = AppL10n(lang);
      expect(l.supVerifiedData, isNot(l.supSelfReported),
          reason: '$lang: ҳарду сарлавҳа як хел — харидор фарқро намебинад');
    }
  });

  test('се забон матни гуногун медиҳанд', () {
    final seen = <String>{};
    for (final lang in ['tg', 'ru', 'en']) {
      seen.add(AppL10n(lang).supSelfReported);
    }
    expect(seen.length, 3, reason: 'ягон забон тарҷума нашудааст');
  });
}
