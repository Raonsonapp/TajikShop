import '../app_l10n.dart';

/// Шумораи ихтиёрӣ ва моли тамомшуда (tg/ru/en).
extension StockPolicyL10n on AppL10n {
  String _sp(String ru, String en, String tg) =>
      lang == 'ru' ? ru : (lang == 'en' ? en : tg);

  String get stockUnlimited =>
      _sp('Без учёта количества', 'No quantity limit', 'Бе ҳисоби шумора');

  /// Тавзеҳ ҲАТМИСТ.
  ///
  /// Бе он фурӯшанда намефаҳмад, ки ин чӣ маъно дорад ва чаро баъд
  /// шумора нишон дода намешавад.
  String get stockUnlimitedHint => _sp(
      'Для тех, кто делает на заказ: швея, пекарь, мебельщик. '
          'Товар не будет «заканчиваться».',
      'For made-to-order sellers: tailor, baker, furniture maker. '
          'The item will never go out of stock.',
      'Барои онҳое, ки бо фармоиш месозанд: дӯзанда, нонвой, устои '
          'мебел. Мол ҳеҷ гоҳ «тамом» намешавад.');

  String get stockUnlimitedBadge =>
      _sp('Под заказ', 'Made to order', 'Бо фармоиш');

  // ── Моли тамомшуда ──

  String get soldOutWillHide => _sp(
      'Если не ответите, через 3 дня объявление скроется само',
      'If you do not reply, the listing hides itself in 3 days',
      'Агар ҷавоб надиҳед, баъди 3 рӯз эълон худаш пинҳон мешавад');

  String get listingHidden =>
      _sp('Объявление скрыто', 'Listing hidden', 'Эълон пинҳон шуд');

  /// Матни бозгардонӣ — фурӯшанда бояд БИДОНАД, ки ҳазф нашудааст.
  String get listingHiddenHint => _sp(
      'Товар не удалён — его можно вернуть в любой момент',
      'The item is not deleted — you can bring it back any time',
      'Мол ҳазф нашудааст — онро ҳар вақт баргардонидан мумкин');

  // ── Нест кардани эълони худ ──

  String get deleteMyPost =>
      _sp('Удалить объявление', 'Delete listing', 'Эълонро нест кардан');

  String get deleteMyPostAsk => _sp(
      'Удалить это объявление?', 'Delete this listing?',
      'Ин эълонро нест кунем?');

  /// Чаро мол гоҳе пинҳон мешавад, на ҳазф.
  ///
  /// Инро гуфтан лозим аст: вагарна фурӯшанда «нест кардам» мегӯяд, вале
  /// молро дар таърихи фармоиш мебинад ва фикр мекунад, ки хато шуд.
  String get deleteMyPostNote => _sp(
      'Если товар уже заказывали, он скроется из каталога, но останется '
          'в истории заказов — иначе покупатель потеряет свой заказ.',
      'If the item was already ordered, it is hidden from the catalogue but '
          'kept in order history — otherwise the buyer loses their order.',
      'Агар мол аллакай фармоиш шуда бошад, он аз каталог пинҳон мешавад, '
          'вале дар таърихи фармоиш мемонад — вагарна харидор фармоиши '
          'худро гум мекунад.');

  String get deletedOk =>
      _sp('Объявление удалено', 'Listing deleted', 'Эълон нест карда шуд');
}
