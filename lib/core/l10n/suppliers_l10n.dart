import '../app_l10n.dart';

/// Ҷустуҷӯи таъминкунанда (tg/ru/en).
extension SuppliersL10n on AppL10n {
  String _s(String ru, String en, String tg) =>
      lang == 'ru' ? ru : (lang == 'en' ? en : tg);

  String get supTitle =>
      _s('Поставщики', 'Suppliers', 'Таъминкунандагон');

  String get supExplain => _s(
      'Для оптовой закупки сначала выбирают поставщика, а потом уже товар. '
          'Все цифры ниже посчитаны по реальным заказам.',
      'For wholesale you pick a supplier first, then the goods. Every number '
          'below is counted from real orders.',
      'Барои хариди яклухт аввал таъминкунанда интихоб мешавад, баъд мол. '
          'Ҳамаи рақамҳои поён аз фармоишҳои ВОҚЕӢ ҳисоб шудаанд.');

  String get supEmpty =>
      _s('Поставщиков не найдено', 'No suppliers found',
          'Таъминкунанда ёфт нашуд');

  String get supOnlyVerified =>
      _s('Только проверенные', 'Verified only', 'Танҳо тасдиқшуда');

  String get supSearchHint =>
      _s('Название магазина', 'Shop name', 'Номи дӯкон');

  String get supRegionHint => _s('Регион', 'Region', 'Минтақа');

  // ── Рақамҳои тасдиқшуда ──

  String get supVerifiedData => _s(
      'Проверенные данные', 'Verified data', 'Маълумоти тасдиқшуда');

  /// Он чизе, ки ХУДИ фурӯшанда навиштааст.
  ///
  /// Ин сарлавҳа ҳатмист. Ҳамин ҷойест, ки платформаҳо одатан фиреб
  /// мекунанд: даъвои фурӯшанда ҳамчун маълумоти тасдиқшуда нишон дода
  /// мешавад. Харидор бояд фарқро БИНАД.
  String get supSelfReported => _s(
      'Со слов продавца', 'Seller’s own words', 'Аз гуфтаи фурӯшанда');

  String supOrdersDone(int n) => _s(
      '$n заказов выполнено', '$n orders completed', '$n фармоиш анҷом ёфт');

  String supCompletionRate(int pct) =>
      _s('$pct% выполнено', '$pct% completed', '$pct% анҷом ёфт');

  String supProducts(int n) =>
      _s('$n товаров', '$n items', '$n мол');

  String supRating(String v, int count) => _s(
      '$v ($count оценок)', '$v ($count ratings)', '$v ($count баҳо)');

  String supSince(String ym) =>
      _s('с $ym', 'since $ym', 'аз $ym');

  /// Чаро фоизи анҷом нест.
  ///
  /// Инро гуфтан лозим аст: вагарна харидор фикр мекунад, ки маълумот
  /// гум шуд. Ҳақиқат дигар аст — фармоиш кам аст ва рақам бемаъно
  /// мешуд.
  String get supNotEnoughOrders => _s(
      'Заказов пока мало — процент не считаем, он был бы обманчивым',
      'Too few orders yet — a percentage here would be misleading',
      'Фармоиш ҳанӯз кам аст — фоиз ҳисоб намешавад, он фиребанда мешуд');

  String get supWholesaleItems =>
      _s('Оптовые товары', 'Wholesale items', 'Молҳои яклухт');

  String supWholesaleFrom(String price, int qty) => _s(
      'от $price сом. при $qty шт.',
      'from $price TJS at $qty pcs',
      'аз $price сом. ҳангоми $qty дона');

  String get supNoWholesale => _s(
      'У этого поставщика пока нет оптовых цен',
      'This supplier has no wholesale pricing yet',
      'Ин таъминкунанда ҳанӯз нархи яклухт надорад');

  String get supVerifiedBadge =>
      _s('Проверен', 'Verified', 'Тасдиқшуда');
}
