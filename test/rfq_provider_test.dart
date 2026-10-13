import 'package:flutter_test/flutter_test.dart';
import 'package:tajikshop/core/app_l10n.dart';
import 'package:tajikshop/core/l10n/rfq_l10n.dart';
import 'package:tajikshop/providers/locale_provider.dart';
import 'package:tajikshop/providers/rfq_provider.dart';

void main() {
  group('rfqDaysLeft', () {
    // Фарқи РӮЗҲОИ тақвимӣ, на соатҳо. Агар мӯҳлат фардо соати 9 бошад
    // ва ҳоло соати 20, фарқи соатҳо 13 аст — яъне «0 рӯз». Вале корбар
    // бояд «1 рӯз» бинад.
    test('мӯҳлати фардо = 1 рӯз, ҳатто агар камтар аз 24 соат монда бошад', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final at = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
      expect(rfqDaysLeft({'closes_at': at.toIso8601String()}), 1);
    });

    test('мӯҳлати имрӯз = 0', () {
      final now = DateTime.now();
      final at = DateTime(now.year, now.month, now.day, 23, 59);
      expect(rfqDaysLeft({'closes_at': at.toIso8601String()}), 0);
    });

    test('мӯҳлати гузашта = манфӣ', () {
      final at = DateTime.now().subtract(const Duration(days: 3));
      expect(rfqDaysLeft({'closes_at': at.toIso8601String()}), lessThan(0));
    });

    // Маълумоти вайрон набояд барномаро шиканад.
    test('маълумоти вайрон = 0', () {
      expect(rfqDaysLeft({}), 0);
      expect(rfqDaysLeft({'closes_at': null}), 0);
      expect(rfqDaysLeft({'closes_at': ''}), 0);
      expect(rfqDaysLeft({'closes_at': 'ин сана нест'}), 0);
    });
  });

  group('тарҷумаҳо', () {
    const statuses = ['open', 'closed', 'awarded', 'cancelled'];

    for (final locale in LocaleNotifier.supported) {
      final l = AppL10n(locale.languageCode);

      test('«${locale.languageCode}» — ҳолатҳо тарҷума шудаанд', () {
        for (final s in statuses) {
          final text = l.rfqStatus(s);
          expect(text.trim(), isNotEmpty);
          expect(text, isNot(s), reason: 'ҳолати «$s» тарҷума нашудааст');
        }
      });

      test('«${locale.languageCode}» — сарлавҳаҳо ҳастанд', () {
        for (final s in [
          l.rfqTitle,
          l.rfqMyRequests,
          l.rfqOpenRequests,
          l.rfqNew,
          l.rfqExplain,
          l.rfqQuotes,
          l.rfqSendQuote,
          l.rfqUnitPrice,
          l.rfqTotal,
          l.rfqAccept,
          l.rfqRivalsHidden,
        ]) {
          expect(s.trim(), isNotEmpty);
          expect(s.contains(r'$'), isFalse, reason: 'рақами ивазнашуда: $s');
        }
      });

      test('«${locale.languageCode}» — матнҳои рақамдор', () {
        expect(l.rfqDays(5), contains('5'));
        expect(l.rfqQuotesCount(3), contains('3'));
        expect(l.rfqClosesIn(4), contains('4'));
        expect(l.rfqVersion(2), contains('2'));
        for (final s in [
          l.rfqDays(5),
          l.rfqQuotesCount(3),
          l.rfqClosesIn(4),
          l.rfqVersion(2),
        ]) {
          expect(s.contains(r'$'), isFalse, reason: 'рақами ивазнашуда: $s');
        }
      });

      test('«${locale.languageCode}» — мӯҳлат: имрӯз, гузашта, оянда', () {
        // Ҳар се ҳолат бояд матни ГУНОГУН диҳанд — вагарна корбар
        // намефаҳмад, ки мӯҳлат гузашт.
        final seen = <String>{
          l.rfqClosesIn(-1),
          l.rfqClosesIn(0),
          l.rfqClosesIn(5),
        };
        expect(seen.length, 3);
      });
    }

    test('се забон матни гуногун медиҳанд', () {
      for (final s in statuses) {
        final seen = <String>{};
        for (final lang in ['tg', 'ru', 'en']) {
          seen.add(AppL10n(lang).rfqStatus(s));
        }
        expect(seen.length, 3,
            reason: 'ҳолати «$s» дар ягон забон тарҷума нашудааст');
      }
    });

    test('ҳолати нашинохта ҳамон тавре бармегардад', () {
      expect(AppL10n('tg').rfqStatus('ҳолати-нав'), 'ҳолати-нав');
    });
  });
}
