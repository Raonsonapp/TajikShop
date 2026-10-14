import 'package:flutter_test/flutter_test.dart';
import 'package:tajikshop/core/app_l10n.dart';
import 'package:tajikshop/core/l10n/delivery_l10n.dart';
import 'package:tajikshop/providers/locale_provider.dart';

/// Матнҳои расонидан ва «Ҳимояи харидор».
///
/// Инҳо дар код МЕХКӮБ буданд — танҳо тоҷикӣ. Корбари русзабон дар
/// мобайни экрани русӣ блоки тоҷикӣ мебинад. Ва маҳз ҳамин блок он
/// чизест, ки харидорро бовар мекунонад: агар ӯ онро нахонад, харид
/// намекунад.
void main() {
  for (final locale in LocaleNotifier.supported) {
    final l = AppL10n(locale.languageCode);

    test('«${locale.languageCode}» — ҳамаи матнҳо ҳастанд', () {
      for (final s in [
        l.deliveryWord,
        l.deliveryNone,
        l.deliveryTime,
        l.deliveryDaysValue(5),
        l.deliveryByAgreement,
        l.deliveryPriceLabel,
        l.deliveryFree,
        l.sizeAndDetails,
        l.buyerProtection,
        l.buyerProtectionEscrow,
        l.buyerProtectionRefund,
        l.buyerProtectionDispute,
        l.sellerCardMissing,
        l.sellerCardFailed,
        l.sellerNotFound,
        l.sellerCardTitle('Карим'),
        l.chatWithSeller,
      ]) {
        expect(s.trim(), isNotEmpty);
      }
    });

    test('«${locale.languageCode}» — шумора дар матн мемонад', () {
      expect(l.deliveryDaysValue(7), contains('7'));
      expect(l.sellerCardTitle('Карим'), contains('Карим'));
    });
  }

  /// Тарҷумаҳо бояд ФАРҚ кунанд.
  ///
  /// Бе ин санҷиш нусхабардории фаромӯшшуда (`_dl(ru, ru, ru)`) ба
  /// корбари русзабон матни тоҷикӣ медод, ва касе онро намедид.
  test('тарҷумаҳо такрор нашудаанд', () {
    final tg = AppL10n('tg');
    final ru = AppL10n('ru');
    final en = AppL10n('en');
    for (final get in <String Function(AppL10n)>[
      (x) => x.buyerProtection,
      (x) => x.buyerProtectionEscrow,
      (x) => x.deliveryWord,
      (x) => x.deliveryFree,
      (x) => x.chatWithSeller,
    ]) {
      expect(get(tg), isNot(get(ru)));
      expect(get(ru), isNot(get(en)));
      expect(get(tg), isNot(get(en)));
    }
  });
}
