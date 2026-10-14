import 'package:flutter_test/flutter_test.dart';
import 'package:tajikshop/core/app_l10n.dart';
import 'package:tajikshop/core/l10n/stock_policy_l10n.dart';
import 'package:tajikshop/data/models/product_model.dart';
import 'package:tajikshop/providers/locale_provider.dart';

/// Моли «бо фармоиш» — дӯзанда, нонвой, устои мебел.
///
/// Чунин фурӯшанда шумора надорад: ӯ ҳар вақт месозад. Пештар барнома
/// ба ӯ маҷбур мекард шумора нависад, ва баъди фурӯш эълонаш «Тамом
/// шуд» мешуд — харидор мерафт, дар ҳоле ки мол дастрас буд.
void main() {
  group('ProductModel.madeToOrder', () {
    /// ⚠️ Муҳимтарин санҷиши ин файл.
    ///
    /// Ном дар модел маҳз МУСБАТ аст (`madeToOrder`, на `trackStock`).
    /// Сервер дар ҳамаи дархостҳо ин майдонро намефиристад — рӯйхатҳои
    /// тавсия, flash sale ва ҷустуҷӯ онро надоранд. Бо `trackStock`
    /// ҳар ҷавоби нопурра шуморо пинҳон мекард; акнун ҷавоби нопурра
    /// рафтори ОДДӢ медиҳад.
    test('майдони нарасида → моли ОДДӢ, на бо фармоиш', () {
      final p = ProductModel.fromJson({
        'id': 'p1',
        'title': 'Орд',
        'price': 100,
        'stock': 0,
        'is_active': true,
      });
      expect(p.madeToOrder, isFalse,
          reason: 'ҷавоби бе `made_to_order` набояд молро бешумор кунад');
      expect(p.inStock, isFalse, reason: 'захираи сифр = тамом шуд');
    });

    test('`made_to_order: true` → ҳатто бо захираи сифр дастрас', () {
      final p = ProductModel.fromJson({
        'id': 'p2',
        'title': 'Кӯрта бо фармоиш',
        'price': 250,
        'stock': 0,
        'is_active': true,
        'made_to_order': true,
      });
      expect(p.madeToOrder, isTrue);
      expect(p.inStock, isTrue,
          reason: 'дӯзанда ҳеҷ гоҳ «тамом» намешавад — вагарна харидор '
              'меравад, дар ҳоле ки мол сохта мешавад');
    });

    /// Моли хомӯшшуда бояд хомӯш монад.
    ///
    /// «Бо фармоиш» маънои «ҳамеша дар бозор»-ро надорад: агар фурӯшанда
    /// эълонро худаш хомӯш кунад, он набояд баргардад.
    test('`is_active: false` аз «бо фармоиш» болотар аст', () {
      final p = ProductModel.fromJson({
        'id': 'p3',
        'title': 'X',
        'price': 10,
        'stock': 0,
        'is_active': false,
        'made_to_order': true,
      });
      expect(p.inStock, isFalse);
    });

    /// Арзиши ғайримантиқӣ набояд барномаро вайрон кунад.
    test('арзиши нодуруст ҳамчун `false` хонда мешавад', () {
      for (final v in <Object?>[null, 'true', 1, 0, 'yes']) {
        final p = ProductModel.fromJson({
          'id': 'p4',
          'title': 'X',
          'price': 10,
          'stock': 0,
          'is_active': true,
          'made_to_order': v,
        });
        expect(p.madeToOrder, isFalse,
            reason: '`$v` набояд ҳамчун «бо фармоиш» фаҳмида шавад');
      }
    });
  });

  group('матнҳои шумораи ихтиёрӣ', () {
    for (final locale in LocaleNotifier.supported) {
      final l = AppL10n(locale.languageCode);

      test('«${locale.languageCode}» — ҳамаи матнҳо ҳастанд', () {
        for (final s in [
          l.stockUnlimited,
          l.stockUnlimitedHint,
          l.stockUnlimitedBadge,
          l.soldOutWillHide,
          l.listingHidden,
          l.listingHiddenHint,
          l.deleteMyPost,
          l.deleteMyPostAsk,
          l.deleteMyPostNote,
          l.deletedOk,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
      });
    }

    /// Матнҳо дар се забон бояд ФАРҚ кунанд.
    ///
    /// Бе ин санҷиш нусхабардории фаромӯшшуда (`_sp(ru, ru, ru)`) ба
    /// корбари русзабон матни тоҷикӣ медод, ва касе онро намедид.
    test('тарҷумаҳо такрор нашудаанд', () {
      final tg = AppL10n('tg');
      final ru = AppL10n('ru');
      final en = AppL10n('en');
      expect(tg.stockUnlimited, isNot(ru.stockUnlimited));
      expect(ru.stockUnlimited, isNot(en.stockUnlimited));
      expect(tg.deleteMyPost, isNot(ru.deleteMyPost));
      expect(ru.deleteMyPost, isNot(en.deleteMyPost));
      expect(tg.soldOutWillHide, isNot(ru.soldOutWillHide));
      expect(ru.soldOutWillHide, isNot(en.soldOutWillHide));
    });
  });
}
