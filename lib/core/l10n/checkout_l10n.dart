import '../app_l10n.dart';

/// Хабарҳои сохтани фармоиш (tg/ru/en).
///
/// Сервер ҳоло ҳангоми рад кардани фармоиш на танҳо матн, балки РӮЙХАТИ
/// мушкилотро мефиристад: кадом мол тамом шуд, кадомаш хомӯш шуд, кадомаш
/// аз ҳадди ақали фурӯшанда камтар аст. Бе ин тарҷумаҳо харидор танҳо
/// «Хато» мебинад ва намедонад, дар сабадаш чиро дуруст кунад.
extension CheckoutL10n on AppL10n {
  String get cartChangedTitle => lang == 'ru'
      ? 'Корзина изменилась'
      : lang == 'en'
          ? 'Your cart changed'
          : 'Сабад тағйир ёфт';

  String get cartChangedBody => lang == 'ru'
      ? 'Пока вы выбирали, эти товары изменились. Проверьте корзину.'
      : lang == 'en'
          ? 'These items changed while you were choosing. Please check your cart.'
          : 'То шумо интихоб мекардед, ин молҳо тағйир ёфтанд. Сабадро бинед.';

  String get cartFixAndRetry => lang == 'ru'
      ? 'Проверить корзину'
      : lang == 'en'
          ? 'Review cart'
          : 'Сабадро дидан';

  /// Матни мушкилоти як мол.
  ///
  /// `code` аз сервер меояд (`money.go`). Коди нофаҳмо матни умумӣ
  /// мегирад — то барномаи кӯҳна бо серверди нав вайрон нашавад.
  String cartIssue(String code, {int available = 0, int minQty = 0}) {
    switch (code) {
      case 'inactive':
        return lang == 'ru'
            ? 'Продавец убрал этот товар'
            : lang == 'en'
                ? 'The seller removed this item'
                : 'Фурӯшанда ин молро гирифт';
      case 'out_of_stock':
        return lang == 'ru'
            ? 'Товар закончился'
            : lang == 'en'
                ? 'Out of stock'
                : 'Мол тамом шуд';
      case 'not_enough':
        return lang == 'ru'
            ? 'Осталось только $available шт.'
            : lang == 'en'
                ? 'Only $available left'
                : 'Танҳо $available дона мондааст';
      case 'below_min_qty':
        return lang == 'ru'
            ? 'Продавец продаёт от $minQty шт.'
            : lang == 'en'
                ? 'The seller sells from $minQty pcs'
                : 'Фурӯшанда аз $minQty дона мефурӯшад';
      case 'invalid_qty':
        return lang == 'ru'
            ? 'Неверное количество'
            : lang == 'en'
                ? 'Invalid quantity'
                : 'Шумора нодуруст аст';
      case 'invalid_price':
        return lang == 'ru'
            ? 'Цена товара изменилась'
            : lang == 'en'
                ? 'The price changed'
                : 'Нархи мол тағйир ёфт';
      default:
        return lang == 'ru'
            ? 'Товар изменился'
            : lang == 'en'
                ? 'This item changed'
                : 'Ин мол тағйир ёфт';
    }
  }
}
