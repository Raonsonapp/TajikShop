import '../app_l10n.dart';

/// Расонидан ва «Ҳимояи харидор» дар экрани мол (tg/ru/en).
///
/// ЧАРО ҶУДО: ин матнҳо дар код МЕХКӮБ буданд — танҳо тоҷикӣ. Корбари
/// русзабон — ва дар Тоҷикистон онҳо кам нестанд — дар мобайни экрани
/// русӣ блоки тоҷикӣ мебинад. Ва маҳз ҳамин блок он чизест, ки
/// харидорро бовар мекунонад: агар ӯ онро нахонад, харид намекунад.
extension DeliveryL10n on AppL10n {
  String _dl(String ru, String en, String tg) =>
      lang == 'ru' ? ru : (lang == 'en' ? en : tg);

  // ── Расонидан ──

  String get deliveryWord => _dl('Доставка', 'Delivery', 'Расонидан');

  String get deliveryNone =>
      _dl('Нет — забираете в магазине', 'None — pickup in store',
          'Нест — аз мағоза мегиред');

  /// ⚠️ Ном маҳз `deliveryTimeLabel` аст, на `deliveryTime`.
  ///
  /// `deliveryTime` аллакай дар `ProfileL10n` ҳаст (вақти расонидан дар
  /// сабад — «то соати 18»), ва ду `extension`-и ҳамон синф бо ҳамон
  /// ном хатои тартиб медиҳад:
  ///
  ///   error • A member named 'deliveryTime' is defined in two
  ///   extensions, and neither is more specific
  ///
  /// `tools/l10n_guard.py` акнун чунин ҳолатро маҳаллӣ мегирад.
  String get deliveryTimeLabel =>
      _dl('Срок доставки', 'Delivery time', 'Мӯҳлати расиш');

  /// `5 рӯз` / `5 дней` / `5 days`.
  ///
  /// Шумора ҲАМРОҲИ матн аст, на берун аз он: дар забонҳои гуногун
  /// ҷойи рақам фарқ мекунад, ва «$n days» дар як ҷо дуруст, дар ҷойи
  /// дигар нодуруст мешавад.
  String deliveryDaysValue(int n) =>
      _dl('$n дн.', '$n days', '$n рӯз');

  String get deliveryByAgreement =>
      _dl('По договорённости с продавцом', 'By agreement with the seller',
          'Бо фурӯшанда мувофиқа');

  String get deliveryPriceLabel =>
      _dl('Цена доставки', 'Delivery price', 'Нархи доставка');

  String get deliveryFree => _dl('Бесплатно', 'Free', 'Ройгон');

  String get sizeAndDetails =>
      _dl('Размер / описание', 'Size / details', 'Размер / тавсиф');

  // ── Ҳимояи харидор ──

  // `buyerProtection` ин ҷо НЕСТ: он аллакай дар `OrderStepsL10n` бо
  // ҳамон матн ҳаст. Як мафҳум — як матн; нусхаи дуюм рӯзе аз нусхаи
  // аввал фарқ мекунад, ва ҳеҷ кас намефаҳмад кадомаш дуруст аст.

  String get buyerProtectionEscrow => _dl(
      'Деньги остаются на защищённом счёте до подтверждения получения товара',
      'The money stays in escrow until you confirm you received the item',
      'Пул то тасдиқи гирифтани мол дар ҳисоби ҳифзшуда мемонад');

  String get buyerProtectionRefund => _dl(
      'Если товар не пришёл или не подошёл — возврат средств',
      'If the item never arrives or does not match — you get a refund',
      'Агар мол наомад ё мувофиқ набошад — бозгашти маблағ');

  String get buyerProtectionDispute => _dl(
      'Решение спора с помощью администрации TajikShop',
      'Dispute resolution with help from the TajikShop team',
      'Ҳалли ихтилоф бо кӯмаки маъмурияти TajikShop');

  // ── Корти фурӯшанда (сабад) ──

  String get sellerCardMissing => _dl(
      'Продавец пока не указал карту — напишите ему в чат',
      'The seller has not added a card yet — message them in chat',
      'Фурӯшанда ҳанӯз корт нагузоштааст — бо ӯ чат кунед');

  String get sellerCardFailed => _dl(
      'Не удалось получить карту продавца. Напишите ему в чат.',
      'Could not load the seller\'s card. Message them in chat.',
      'Маълумоти корти фурӯшанда гирифта нашуд. Бо фурӯшанда чат кунед.');

  String get sellerNotFound =>
      _dl('Продавец не найден.', 'Seller not found.', 'Фурӯшанда ёфт нашуд.');

  String sellerCardTitle(String name) =>
      _dl('Карта продавца: $name', 'Seller card: $name',
          'Корти фурӯшанда: $name');

  String get chatWithSeller =>
      _dl('Чат с продавцом', 'Chat with the seller', 'Чат бо фурӯшанда');
}
