import '../app_l10n.dart';

/// Дархости нарх — RFQ (tg/ru/en).
extension RFQL10n on AppL10n {
  String get rfqTitle => lang == 'ru'
      ? 'Запрос цены'
      : lang == 'en'
          ? 'Request for quote'
          : 'Дархости нарх';

  String get rfqMyRequests => lang == 'ru'
      ? 'Мои запросы'
      : lang == 'en'
          ? 'My requests'
          : 'Дархостҳои ман';

  String get rfqOpenRequests => lang == 'ru'
      ? 'Открытые запросы'
      : lang == 'en'
          ? 'Open requests'
          : 'Дархостҳои кушода';

  String get rfqNew => lang == 'ru'
      ? 'Новый запрос'
      : lang == 'en'
          ? 'New request'
          : 'Дархости нав';

  String get rfqExplain => lang == 'ru'
      ? 'Напишите, что нужно — продавцы сами предложат цену. Так дешевле, '
          'чем искать по одному.'
      : lang == 'en'
          ? 'Say what you need — sellers will quote you. Cheaper than '
              'hunting one by one.'
          : 'Нависед, ки чӣ лозим аст — фурӯшандагон худашон нарх '
              'пешниҳод мекунанд. Ин аз якто-якто ҷустан арзонтар аст.';

  String get rfqEmptyBuyer => lang == 'ru'
      ? 'Запросов пока нет'
      : lang == 'en'
          ? 'No requests yet'
          : 'Ҳанӯз дархост нест';

  String get rfqEmptySeller => lang == 'ru'
      ? 'Открытых запросов пока нет'
      : lang == 'en'
          ? 'No open requests yet'
          : 'Ҳанӯз дархости кушода нест';

  // ── Майдонҳо ──

  String get rfqWhatNeeded => lang == 'ru'
      ? 'Что нужно?'
      : lang == 'en'
          ? 'What do you need?'
          : 'Чӣ лозим аст?';

  String get rfqDetails => lang == 'ru'
      ? 'Подробности (качество, бренд, упаковка)'
      : lang == 'en'
          ? 'Details (quality, brand, packaging)'
          : 'Тафсилот (навъ, бренд, бастабандӣ)';

  String get rfqQuantity => lang == 'ru'
      ? 'Количество'
      : lang == 'en'
          ? 'Quantity'
          : 'Шумора';

  String get rfqTargetPrice => lang == 'ru'
      ? 'Желаемая цена за шт. (необязательно)'
      : lang == 'en'
          ? 'Target price per unit (optional)'
          : 'Нархи дилхоҳ барои як дона (ихтиёрӣ)';

  String get rfqDestination => lang == 'ru'
      ? 'Куда доставить'
      : lang == 'en'
          ? 'Deliver to'
          : 'Ба куҷо расонида шавад';

  String get rfqOpenFor => lang == 'ru'
      ? 'Сколько дней принимать предложения'
      : lang == 'en'
          ? 'Days to accept quotes'
          : 'Чанд рӯз пешниҳод қабул шавад';

  String rfqDays(int n) => lang == 'ru'
      ? '$n дн.'
      : lang == 'en'
          ? '$n d'
          : '$n рӯз';

  // ── Ҳолат ──

  String rfqStatus(String code) {
    switch (code) {
      case 'open':
        return lang == 'ru'
            ? 'Открыт'
            : lang == 'en'
                ? 'Open'
                : 'Кушода';
      case 'closed':
        return lang == 'ru'
            ? 'Закрыт'
            : lang == 'en'
                ? 'Closed'
                : 'Пӯшида';
      case 'awarded':
        return lang == 'ru'
            ? 'Выбрано предложение'
            : lang == 'en'
                ? 'Quote accepted'
                : 'Пешниҳод интихоб шуд';
      case 'cancelled':
        return lang == 'ru'
            ? 'Отменён'
            : lang == 'en'
                ? 'Cancelled'
                : 'Бекор шуд';
      default:
        return code;
    }
  }

  /// «3 рӯз мондааст» / «мӯҳлат гузашт».
  String rfqClosesIn(int days) {
    if (days < 0) {
      return lang == 'ru'
          ? 'срок прошёл'
          : lang == 'en'
              ? 'closed'
              : 'мӯҳлат гузашт';
    }
    if (days == 0) {
      return lang == 'ru'
          ? 'сегодня последний день'
          : lang == 'en'
              ? 'last day'
              : 'рӯзи охирин';
    }
    return lang == 'ru'
        ? 'ещё $days дн.'
        : lang == 'en'
            ? '$days days left'
            : '$days рӯз мондааст';
  }

  // ── Пешниҳод ──

  String get rfqQuotes => lang == 'ru'
      ? 'Предложения'
      : lang == 'en'
          ? 'Quotes'
          : 'Пешниҳодҳо';

  String rfqQuotesCount(int n) => lang == 'ru'
      ? '$n предл.'
      : lang == 'en'
          ? '$n quote${n == 1 ? '' : 's'}'
          : '$n пешниҳод';

  String get rfqNoQuotes => lang == 'ru'
      ? 'Предложений пока нет'
      : lang == 'en'
          ? 'No quotes yet'
          : 'Ҳанӯз пешниҳод нест';

  String get rfqSendQuote => lang == 'ru'
      ? 'Предложить цену'
      : lang == 'en'
          ? 'Send a quote'
          : 'Нарх пешниҳод кардан';

  String get rfqEditQuote => lang == 'ru'
      ? 'Изменить предложение'
      : lang == 'en'
          ? 'Change my quote'
          : 'Пешниҳодро иваз кардан';

  String get rfqUnitPrice => lang == 'ru'
      ? 'Цена за шт.'
      : lang == 'en'
          ? 'Price per unit'
          : 'Нархи як дона';

  String get rfqShipping => lang == 'ru'
      ? 'Доставка (всего)'
      : lang == 'en'
          ? 'Shipping (total)'
          : 'Расонидан (ҳама)';

  String get rfqMinQty => lang == 'ru'
      ? 'Минимум, шт.'
      : lang == 'en'
          ? 'Minimum, pcs'
          : 'Ҳадди ақал, дона';

  String get rfqLeadDays => lange('Срок изготовления, дн.',
      'Production time, days', 'Мӯҳлати омодагӣ, рӯз');

  String get rfqPaymentTerms => lange('Условия оплаты',
      'Payment terms', 'Шартҳои пардохт');

  String get rfqValidDays => lange('Предложение действует, дн.',
      'Quote valid for, days', 'Пешниҳод эътибор дорад, рӯз');

  String get rfqNote => lange('Примечание', 'Note', 'Эзоҳ');

  String get rfqTotal => lange('Итого', 'Total', 'Ҷамъ');

  String get rfqCheapest => lange('Дешевле всех', 'Cheapest', 'Аз ҳама арзон');

  String get rfqAccept => lange('Принять', 'Accept', 'Қабул кардан');

  String get rfqWithdraw => lange('Отозвать', 'Withdraw', 'Гирифтан');

  String get rfqClose => lange('Закрыть запрос', 'Close request',
      'Дархостро пӯшидан');

  String rfqVersion(int n) => lange('версия $n', 'version $n', 'версияи $n');

  /// Тавзеҳи он, ки чаро фурӯшанда пешниҳоди рақибонашро намебинад.
  ///
  /// Ин бояд гуфта шавад: вагарна фурӯшанда фикр мекунад, ки хато аст.
  String get rfqRivalsHidden => lange(
      'Вы видите только своё предложение. Цены других продавцов скрыты — '
          'так каждый даёт настоящую цену.',
      'You only see your own quote. Other sellers\' prices are hidden — '
          'that way everyone quotes honestly.',
      'Шумо танҳо пешниҳоди худро мебинед. Нархи фурӯшандагони дигар '
          'пинҳон аст — ҳамин тавр ҳар кас нархи ҳақиқиашро медиҳад.');

  String get rfqQuoteSent => lange('Предложение отправлено',
      'Quote sent', 'Пешниҳод фиристода шуд');

  String get rfqAccepted => lange('Предложение принято, заказ создан',
      'Quote accepted, order created',
      'Пешниҳод қабул шуд, фармоиш сохта шуд');

  String get rfqExpiredQuote => lange('Срок предложения прошёл',
      'This quote has expired', 'Мӯҳлати ин пешниҳод гузаштааст');

  /// Ёридиҳанда: се забон дар як сатр.
  ///
  /// Барои матнҳои дароз се сатри `lang == ...` файлро нахонда мекунад.
  String lange(String ru, String en, String tg) =>
      lang == 'ru' ? ru : (lang == 'en' ? en : tg);
}
