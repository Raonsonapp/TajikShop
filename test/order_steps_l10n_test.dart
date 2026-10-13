import 'package:flutter_test/flutter_test.dart';
import 'package:tajikshop/core/app_l10n.dart';
import 'package:tajikshop/core/l10n/order_steps_l10n.dart';
import 'package:tajikshop/providers/locale_provider.dart';

/// Қадамҳои фармоиш бояд дар ҳар се забон бошанд.
///
/// Пештар онҳо дар `order_timeline.dart` сахт навишта шуда буданд —
/// танҳо тоҷикӣ. Корбари русзабон дар экрани фармоиши худаш матни
/// тоҷикӣ мебинад.
void main() {
  // Ҳамаи ҳолатҳое, ки сервер мефиристад.
  // `paid` нав аст — он барои пардохти ҳамён, ва пештар дар рӯйхат
  // набуд, пас дар экран коди хом «paid» нишон дода мешуд.
  const statuses = [
    'pending',
    'paid',
    'processing',
    'shipped',
    'delivered',
    'completed',
    'cancelled',
  ];

  for (final locale in LocaleNotifier.supported) {
    final l = AppL10n(locale.languageCode);

    test('«${locale.languageCode}» — ҳар ҳолат матн дорад', () {
      for (final s in statuses) {
        final text = l.orderStep(s);
        expect(text.trim(), isNotEmpty, reason: 'ҳолати «$s» матн надорад');
        // Коди хом набояд ба экран барояд.
        expect(text, isNot(s), reason: 'ҳолати «$s» тарҷума нашудааст');
      }
    });

    test('«${locale.languageCode}» — сарлавҳаҳо ҳастанд', () {
      expect(l.buyerProtection.trim(), isNotEmpty);
      expect(l.sellersWord.trim(), isNotEmpty);
      expect(l.trackingCodeLabel.trim(), isNotEmpty);
      expect(l.itemsCount(3), contains('3'));
    });
  }

  test('ҳолати нашинохта ҳамон тавре бармегардад', () {
    // Агар сервер рӯзе ҳолати нав илова кунад, экран набояд холӣ монад.
    expect(AppL10n('tg').orderStep('ягон-ҳолати-нав'), 'ягон-ҳолати-нав');
  });

  test('се забон матни гуногун медиҳанд', () {
    for (final s in statuses) {
      final seen = <String>{};
      for (final lang in ['tg', 'ru', 'en']) {
        seen.add(AppL10n(lang).orderStep(s));
      }
      expect(seen.length, 3, reason: 'ҳолати «$s» дар ягон забон тарҷума нашудааст');
    }
  });
}
