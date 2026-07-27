import '../app_l10n.dart';

/// Additional localized strings for the shop screens (home, product detail,
/// cart, search, categories). Kept separate from [AppL10n] to avoid edit
/// conflicts. Reuse base [AppL10n] getters for common words instead of
/// redefining them here.
extension ShopL10n on AppL10n {
  // ── Home ──
  String get homeRecommended =>
      lang == 'ru' ? 'Рекомендуем' : lang == 'en' ? 'Recommended' : 'Тавсияшуда';
  String get homeTabNew =>
      lang == 'ru' ? 'Новинки' : lang == 'en' ? 'New' : 'Нав';
  String get homeTabPopular =>
      lang == 'ru' ? 'Популярное' : lang == 'en' ? 'Popular' : 'Оммавӣ';
  String get homeTabDiscount =>
      lang == 'ru' ? 'Скидки' : lang == 'en' ? 'Discount' : 'Тахфиф';

  // ── Search ──
  String get searchNotFound =>
      lang == 'ru' ? 'не найдено' : lang == 'en' ? 'not found' : 'ёфт нашуд';
  String get searchTryAnother => lang == 'ru'
      ? 'Попробуйте другое слово'
      : lang == 'en'
          ? 'Try another word'
          : 'Калимаи дигар истифода кунед';
  String get resultsForWord => lang == 'ru'
      ? 'результатов для'
      : lang == 'en'
          ? 'results for'
          : 'натиҷа барои';
  String get recentSearches => lang == 'ru'
      ? 'Недавние запросы'
      : lang == 'en'
          ? 'Recent searches'
          : 'Ҷустуҷӯҳои охирин';
  String get recentlyViewed => lang == 'ru'
      ? 'Недавно просмотренные'
      : lang == 'en'
          ? 'Recently viewed'
          : 'Бознигаристашуда';
  String get sortNewest =>
      lang == 'ru' ? 'Новинки' : lang == 'en' ? 'Newest' : 'Нав';
  String get sortPriceAsc => lang == 'ru'
      ? 'Дешевле → Дороже'
      : lang == 'en'
          ? 'Cheap → Expensive'
          : 'Арзон → Қимат';
  String get sortPriceDesc => lang == 'ru'
      ? 'Дороже → Дешевле'
      : lang == 'en'
          ? 'Expensive → Cheap'
          : 'Қимат → Арзон';
  String get sortPopular =>
      lang == 'ru' ? 'Популярные' : lang == 'en' ? 'Popular' : 'Машҳур';

  // ── Categories ──
  String get categoryViewAction =>
      lang == 'ru' ? 'Показать' : lang == 'en' ? 'View' : 'Намоиш';
}
