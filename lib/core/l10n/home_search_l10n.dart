import '../app_l10n.dart';
// `sortPopular` ва `recentlyViewed` дар `ShopL10n` ҳастанд. Азбаски
// ҳамаи `extension`-ҳо ба ҳамон `AppL10n` васл мешаванд, танҳо import
// кофист — нусхабардорӣ лозим нест.
import 'shop_l10n.dart';

/// Саҳифаи асосӣ ва ҷустуҷӯ (tg/ru/en).
///
/// ЧАРО ҶУДО: инҳо ду экрани аввалине ҳастанд, ки ҳар корбар мебинад —
/// ва ҳамаи матнашон дар код МЕХКӮБ буд. Корбари русзабон забонро ба
/// русӣ мегузошт ва ҳамон «Машҳуртарин», «Серхаридор», «Филтрҳо»-ро
/// медид. Аз ҳама бадтар: ӯ фикр мекунад, ки интихоби забон КОР
/// НАМЕКУНАД — ва дигар ба он даст намерасонад.
extension HomeSearchL10n on AppL10n {
  String _hs(String ru, String en, String tg) =>
      lang == 'ru' ? ru : (lang == 'en' ? en : tg);

  // ── Саҳифаи асосӣ ──

  String get greeting => _hs('Привет 👋', 'Hello 👋', 'Салом 👋');

  String barcodeNotFound(String code) => _hs(
      'Товар с кодом «$code» не найден',
      'No product with code "$code"',
      'Маҳсулот бо коди «$code» ёфт нашуд');

  String get allWord => _hs('Все', 'All', 'Ҳама');

  String get specialOffer =>
      _hs('Особая скидка', 'Special offer', 'Тахфифи махсус');

  String get summerSale =>
      _hs('Летняя распродажа', 'Summer sale', 'Тарабфурӯшии тобистона');

  String get summerSaleHint => _hs(
      'До 50% скидки на выбранные товары',
      'Up to 50% off selected items',
      'То 50% тахфиф ба маҳсулоти интихобшуда');

  String get mostPopular => _hs('Самое популярное', 'Most popular', 'Машҳуртарин');

  String get bestSelling => _hs('Хиты продаж', 'Best sellers', 'Серхаридор');

  // `recentlyViewed` ин ҷо НЕСТ — он дар `ShopL10n` ҳаст.

  String get flashDeals =>
      _hs('Молниеносные скидки', 'Flash deals', 'Тахфифҳои барқӣ');

  // ── Ҳикояҳо ──

  String get storyPublished =>
      _hs('История опубликована ✅', 'Story published ✅', 'Ҳикоя нашр шуд ✅');

  String get storyFailed => _hs('Ошибка при публикации истории',
      'Could not publish the story', 'Хатогӣ ҳангоми нашри ҳикоя');

  String get myStory => _hs('Моя история', 'My story', 'Ҳикояи ман');

  String get firstStoryHint => _hs('Опубликуйте свою первую историю',
      'Publish your first story', 'Аввалин ҳикояи худро нашр кунед');

  // ── Блокҳои саҳифаи асосӣ ──

  String get cargoFromChina =>
      _hs('📦 Карго из Китая', '📦 Cargo from China', '📦 Карго аз Хитой');

  String get cargoHint => _hs('Доставка в Таджикистан и Россию',
      'Delivery to Tajikistan and Russia', 'Доставка ба Тоҷикистон ва Русия');

  String get nearbyShopsTitle =>
      _hs('🗺 Магазины рядом', '🗺 Shops nearby', '🗺 Дӯконҳои наздик');

  String get nearbyShopsHint => _hs('Найдите местный бизнес на карте',
      'Find local businesses on the map', 'Бизнесҳои маҳаллиро дар харита ёбед');

  // ── Ҷустуҷӯ: пешниҳодҳои омода ──

  /// Пешниҳодҳои ҷустуҷӯ низ тарҷума мешаванд.
  ///
  /// Инҳо на танҳо матнанд — ин ҳамон чизест, ки ба сервер фиристода
  /// мешавад. Корбари русзабон «Телевизор»-ро ҳамин тавр менависад, ва
  /// «Либос»-ро «Одежда». Пас ҷустуҷӯ бо калимаи забони ӯ бояд кор
  /// кунад, вагарна зеркунӣ натиҷаи холӣ медиҳад.
  List<String> get searchSuggestions => lang == 'ru'
      ? const [
          'Телевизор', 'Одежда', 'Обувь', 'Ноутбук', 'Серьги',
          'Смартфон', 'Мебель',
        ]
      : lang == 'en'
          ? const [
              'TV', 'Clothes', 'Shoes', 'Laptop', 'Earrings',
              'Smartphone', 'Furniture',
            ]
          : const [
              'Телевизор', 'Либос', 'Пойафзол', 'Ноутбук', 'Гӯшвора',
              'Смартфон', 'Мебел',
            ];

  // ── Ҷустуҷӯ: тартиб ва филтрҳо ──

  String get sortNew => _hs('Новые', 'New', 'Нав');
  String get sortCheap => _hs('Дешёвые', 'Cheapest', 'Арзон');
  String get sortExpensive => _hs('Дорогие', 'Priciest', 'Гарон');
  // `sortPopular` ин ҷо НЕСТ — он дар `ShopL10n` ҳаст.

  String get filtersTitle => _hs('Фильтры', 'Filters', 'Филтрҳо');
  String get filtersClear => _hs('Сбросить', 'Clear', 'Тоза');
  String get priceSomoni => _hs('Цена (сомони)', 'Price (somoni)', 'Нарх (сомонӣ)');
  String get minRating =>
      _hs('Минимальная оценка', 'Minimum rating', 'Баҳои камтарин');
  String get categoryWord => _hs('Категория', 'Category', 'Категория');
  String get sortWord => _hs('Сортировка', 'Sort', 'Тартиб');
  String get applyWord => _hs('Применить', 'Apply', 'Татбиқ');

  String get priceFrom => _hs('От', 'From', 'Аз');
  String get priceTo => _hs('До', 'To', 'То');

  /// Тартибҳо ҳамчун ҷадвал: калид ба сервер меравад, матн ба экран.
  ///
  /// Пештар ин `static const Map` буд ва маҳз бо ҳамин сабаб тарҷума
  /// намешуд: `const` ба `AppL10n` даст расонида наметавонад.
  Map<String?, String> get sortOptions => {
        null: sortNew,
        'price_asc': sortCheap,
        'price_desc': sortExpensive,
        'popular': sortPopular,
      };
}
