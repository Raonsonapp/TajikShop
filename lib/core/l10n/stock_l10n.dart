import '../app_l10n.dart';

/// Маҳсулоти нестшуда ва маҳсулоти тамомшуда (tg/ru/en).
extension StockL10n on AppL10n {
  // ── Маҳсулот дигар нест ──
  String get productGoneTitle => lang == 'ru'
      ? 'Этого товара больше нет'
      : lang == 'en'
          ? 'This product is gone'
          : 'Ин маҳсулот дигар нест';
  String get productGoneBody => lang == 'ru'
      ? 'Продавец удалил его или он закончился. Посмотрите похожие товары.'
      : lang == 'en'
          ? 'The seller removed it or it sold out. Try similar products.'
          : 'Фурӯшанда онро нест кард ё тамом шуд. Маҳсулоти монандро бинед.';
  String get productGoneSearch => lang == 'ru'
      ? 'Похожие товары'
      : lang == 'en'
          ? 'Similar products'
          : 'Маҳсулоти монанд';
  String get productGoneHome => lang == 'ru'
      ? 'На главную'
      : lang == 'en'
          ? 'Go home'
          : 'Ба саҳифаи асосӣ';

  // ── Тамом шуд: пурсиш ба фурӯшанда ──
  String get soldOutTitle => lang == 'ru'
      ? 'Товары закончились'
      : lang == 'en'
          ? 'Sold-out products'
          : 'Маҳсулоти тамомшуда';
  String get soldOutQuestion => lang == 'ru'
      ? 'Этот товар ещё есть?'
      : lang == 'en'
          ? 'Do you still have this?'
          : 'Ин маҳсулот боз ҳаст?';
  String get soldOutHint => lang == 'ru'
      ? 'Пока вы не ответите, товар не показывается покупателям.'
      : lang == 'en'
          ? 'Until you answer, buyers do not see it.'
          : 'То ҷавоб надиҳед, харидорон онро намебинанд.';
  String get soldOutYes => lang == 'ru'
      ? 'Да, есть'
      : lang == 'en'
          ? 'Yes, I have it'
          : 'Ҳа, боз ҳаст';
  String get soldOutNo => lang == 'ru'
      ? 'Нет, удалить'
      : lang == 'en'
          ? 'No, remove it'
          : 'Не, нест кун';
  String get soldOutHowMany => lang == 'ru'
      ? 'Сколько штук?'
      : lang == 'en'
          ? 'How many?'
          : 'Чанд дона?';
  String get soldOutBackOnSale => lang == 'ru'
      ? 'Товар снова в продаже'
      : lang == 'en'
          ? 'Back on sale'
          : 'Маҳсулот боз дар фурӯш аст';
  String get soldOutDeleted => lang == 'ru'
      ? 'Товар удалён'
      : lang == 'en'
          ? 'Product removed'
          : 'Маҳсулот нест карда шуд';
  String get soldOutDeleteConfirm => lang == 'ru'
      ? 'Удалить этот товар из приложения?'
      : lang == 'en'
          ? 'Remove this product from the app?'
          : 'Ин маҳсулотро аз барнома нест кунем?';
  String get soldOutEmpty => lang == 'ru'
      ? 'Все товары в наличии'
      : lang == 'en'
          ? 'Everything is in stock'
          : 'Ҳамаи маҳсулот дар анбор аст';
  String soldOutCount(int n) => lang == 'ru'
      ? '$n товаров ждут ответа'
      : lang == 'en'
          ? '$n products need an answer'
          : '$n маҳсулот ҷавоби шуморо интизор аст';
}
