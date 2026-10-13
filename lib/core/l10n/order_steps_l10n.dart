import '../app_l10n.dart';

/// Қадамҳои фармоиш ва ҳимояи харидор (tg/ru/en).
///
/// Ин матнҳо пештар дар `order_timeline.dart` сахт навишта шуда буданд —
/// танҳо тоҷикӣ. Яъне корбари русзабон дар экрани фармоиши худ матни
/// тоҷикӣ мебинад.
extension OrderStepsL10n on AppL10n {
  /// Номи ҳолати фармоиш.
  ///
  /// Коди нашинохта ҳамон тавре бармегардад — то агар сервер рӯзе ҳолати
  /// нав илова кунад, барнома матни холӣ нишон надиҳад.
  String orderStep(String code) {
    switch (code) {
      case 'pending':
        return lang == 'ru'
            ? 'Заказ принят'
            : lang == 'en'
                ? 'Order placed'
                : 'Фармоиш қабул шуд';
      case 'paid':
        return lang == 'ru'
            ? 'Оплачено'
            : lang == 'en'
                ? 'Paid'
                : 'Пардохт шуд';
      case 'processing':
        return lang == 'ru'
            ? 'Продавец собирает'
            : lang == 'en'
                ? 'Seller is preparing'
                : 'Фурӯшанда омода мекунад';
      case 'shipped':
        return lang == 'ru'
            ? 'В пути'
            : lang == 'en'
                ? 'On the way'
                : 'Дар роҳ';
      case 'delivered':
        return lang == 'ru'
            ? 'Доставлено'
            : lang == 'en'
                ? 'Delivered'
                : 'Супорида шуд';
      case 'completed':
        return lang == 'ru'
            ? 'Завершено'
            : lang == 'en'
                ? 'Completed'
                : 'Анҷом ёфт';
      case 'cancelled':
        return lang == 'ru'
            ? 'Отменено'
            : lang == 'en'
                ? 'Cancelled'
                : 'Бекор шуд';
      default:
        return code;
    }
  }

  String get buyerProtection => lang == 'ru'
      ? 'Защита покупателя'
      : lang == 'en'
          ? 'Buyer protection'
          : 'Ҳимояи харидор';

  String get sellersWord => lang == 'ru'
      ? 'Продавцы'
      : lang == 'en'
          ? 'Sellers'
          : 'Фурӯшандагон';

  String get trackingCodeLabel => lang == 'ru'
      ? 'Код отслеживания: '
      : lang == 'en'
          ? 'Tracking code: '
          : 'Коди пайгирӣ: ';

  /// «$n мол» — шумораи мол дар зер-фармоиши як фурӯшанда.
  String itemsCount(int n) => lang == 'ru'
      ? '$n тов.'
      : lang == 'en'
          ? '$n item${n == 1 ? '' : 's'}'
          : '$n мол';
}
