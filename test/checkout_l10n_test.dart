import 'package:flutter_test/flutter_test.dart';
import 'package:tajikshop/core/app_l10n.dart';
import 'package:tajikshop/core/l10n/checkout_l10n.dart';
import 'package:tajikshop/providers/locale_provider.dart';

/// Хабарҳои рад кардани фармоиш бояд дар ҲАР СЕ забон бошанд.
///
/// Ин муҳофиз аз хатои оддӣ аст: сатри нав илова мешавад, вале танҳо
/// тоҷикӣ навишта мешавад — ва корбари русзабон матни тоҷикӣ мебинад.
void main() {
  // Ҳамаи кодҳое, ки сервер мефиристад (`money.go`), + коди нофаҳмо.
  const codes = [
    'inactive',
    'out_of_stock',
    'not_enough',
    'below_min_qty',
    'invalid_qty',
    'invalid_price',
    'ягон-коди-нофаҳмо',
  ];

  for (final locale in LocaleNotifier.supported) {
    final l = AppL10n(locale.languageCode);

    test('«${locale.languageCode}» — ҳамаи сарлавҳаҳо ҳастанд', () {
      expect(l.cartChangedTitle.trim(), isNotEmpty);
      expect(l.cartChangedBody.trim(), isNotEmpty);
      expect(l.cartFixAndRetry.trim(), isNotEmpty);
    });

    test('«${locale.languageCode}» — ҳар коди мушкилӣ матн дорад', () {
      for (final code in codes) {
        final msg = l.cartIssue(code, available: 3, minQty: 12);
        expect(msg.trim(), isNotEmpty, reason: 'коди «$code» матн надорад');
        // Рақами хом набояд дар матн гум шавад: агар сатр бо
        // интерполятсия навишта шуда бошад, он бояд ВОҚЕАН иваз шавад,
        // на ҳамчун `$available` боқӣ монад.
        expect(msg.contains(r'$'), isFalse,
            reason: 'коди «$code» рақами ивазнашуда дорад: $msg');
      }
    });
  }

  test('`not_enough` рақами анборро нишон медиҳад', () {
    for (final lang in ['tg', 'ru', 'en']) {
      final msg = AppL10n(lang).cartIssue('not_enough', available: 7);
      expect(msg, contains('7'), reason: '$lang: шумораи боқимонда нест');
    }
  });

  test('`below_min_qty` ҳадди ақалро нишон медиҳад', () {
    for (final lang in ['tg', 'ru', 'en']) {
      final msg = AppL10n(lang).cartIssue('below_min_qty', minQty: 24);
      expect(msg, contains('24'), reason: '$lang: ҳадди ақал нест');
    }
  });

  test('се забон матни гуногун медиҳанд', () {
    final seen = <String>{};
    for (final lang in ['tg', 'ru', 'en']) {
      seen.add(AppL10n(lang).cartIssue('out_of_stock'));
    }
    expect(seen.length, 3, reason: 'ягон забон тарҷума нашудааст');
  });
}
