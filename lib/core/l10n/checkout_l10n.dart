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

  String get wholesaleWord => lang == 'ru'
      ? 'Оптом'
      : lang == 'en'
          ? 'Wholesale'
          : 'Яклухт';

  String get retailWord => lang == 'ru'
      ? 'В розницу'
      : lang == 'en'
          ? 'Retail'
          : 'Чакана';

  /// «Боз $more дона гиред — $price сом. мешавад».
  ///
  /// Маҳз ҳамин матн фармоиши калонтарро водор мекунад: харидор мебинад,
  /// ки то зинаи арзонтар чанд дона мондааст.
  String tierHint(int more, double price) {
    final p = price.toStringAsFixed(0);
    return lang == 'ru'
        ? 'Ещё $more шт. → $p сом. за шт.'
        : lang == 'en'
            ? '$more more → $p TJS each'
            : 'Боз $more дона → $p сом. донааш';
  }

  /// «Аз $minQty дона» — сутуни чапи ҷадвали зинаҳо.
  ///
  /// Ҷудо аз нарх аст, то ҷадвал ду сутун дошта бошад. Пештар ман як
  /// сатри пурра месохтам ва баъд онро бо `split(' — ')` мешикастам —
  /// ин ба ҷудокунандаи тарҷума вобаста буд ва дар забони нав вайрон
  /// мешуд.
  String tierQtyLabel(int minQty) => lang == 'ru'
      ? 'от $minQty шт.'
      : lang == 'en'
          ? 'from $minQty pcs'
          : 'аз $minQty дона';

  String get tiersTitle => lang == 'ru'
      ? 'Оптовые цены'
      : lang == 'en'
          ? 'Wholesale pricing'
          : 'Нархи яклухт';

  // ── Муҳаррири зинаҳо (фурӯшанда) ──

  /// Тавзеҳ бо нархи ҳозираи чакана.
  String tiersHint(double retail) {
    final p = retail.toStringAsFixed(0);
    return lang == 'ru'
        ? 'Чем больше купят, тем дешевле за штуку. Розница: $p сом. '
            'Оптовая цена должна быть ниже.'
        : lang == 'en'
            ? 'The more they buy, the cheaper per unit. Retail: $p TJS. '
                'Wholesale must be lower.'
            : 'Ҳар чи зиёдтар гиранд, донааш арзонтар. Чакана: $p сом. '
                'Нархи яклухт бояд камтар бошад.';
  }

  String get tierQtyField => lang == 'ru'
      ? 'От, шт.'
      : lang == 'en'
          ? 'From, pcs'
          : 'Аз, дона';

  String get tierAdd => lang == 'ru'
      ? 'Добавить уровень'
      : lang == 'en'
          ? 'Add tier'
          : 'Зина илова кардан';

  String get tierRemove => lang == 'ru'
      ? 'Убрать'
      : lang == 'en'
          ? 'Remove'
          : 'Бардоштан';

  String get tierErrMinQty => lang == 'ru'
      ? 'Уровень должен быть от 2 шт.'
      : lang == 'en'
          ? 'A tier must start from 2 pcs'
          : 'Зина бояд аз 2 дона боло бошад';

  String get tierErrPrice => lang == 'ru'
      ? 'Укажите количество и цену числом'
      : lang == 'en'
          ? 'Enter quantity and price as numbers'
          : 'Шумора ва нархро бо рақам нависед';

  String get tierErrAboveRetail => lang == 'ru'
      ? 'Оптовая цена должна быть ниже розничной'
      : lang == 'en'
          ? 'Wholesale price must be below retail'
          : 'Нархи яклухт бояд аз чакана камтар бошад';

  String get tierErrDuplicate => lang == 'ru'
      ? 'Два уровня с одинаковым количеством'
      : lang == 'en'
          ? 'Two tiers with the same quantity'
          : 'Ду зина бо ҳамон шумора';

  /// Қоидаи «зинаи калонтар — нархи камтар».
  ///
  /// Он аз мантиқи савдо меояд: харидори ЯКЛУХТ набояд БЕШТАР пардозад.
  String get tierErrIncreasing => lang == 'ru'
      ? 'Чем больше количество, тем ниже должна быть цена'
      : lang == 'en'
          ? 'A bigger tier must have a lower price'
          : 'Зинаи калонтар бояд нархи камтар дошта бошад';

  String get tierSaveError => lang == 'ru'
      ? 'Не удалось сохранить уровни'
      : lang == 'en'
          ? 'Could not save tiers'
          : 'Зинаҳо нигоҳ дошта нашуданд';

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
