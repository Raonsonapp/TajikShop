import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/network_service.dart';
import 'core/services/server_wakeup_service.dart';
import 'core/services/user_session.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'routes/app_router.dart';
import 'shared/widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light));

  // Ҳама инициализатсияро try/catch-да — барнома crash накунад
  try { await UserSession.loadCachedData(); } catch (_) {}
  try { NetworkService.instance.init(); } catch (_) {}
  try { ServerWakeupService.instance.wakeUp(); } catch (_) {}
  try { ServerWakeupService.instance.startKeepAlive(); } catch (_) {}

  runApp(const ProviderScope(child: TajikShopApp()));
}

class TajikShopApp extends ConsumerWidget {
  const TajikShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final locale    = ref.watch(localeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'TajikShop',
      theme:     AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale:    locale,
      routerConfig: router,
      localizationsDelegates: const [
        _AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleNotifier.supported,
      builder: (context, child) =>
          OfflineBanner(child: child ?? const SizedBox()),
    );
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['tg', 'ru', 'en'].contains(locale.languageCode);
  @override
  Future<AppL10n> load(Locale locale) async => AppL10n(locale.languageCode);
  @override
  bool shouldReload(_) => false;
}

class AppL10n {
  final String lang;
  AppL10n(this.lang);
  static AppL10n of(BuildContext context) =>
      Localizations.of<AppL10n>(context, AppL10n) ?? AppL10n('tg');

  String get appName    => 'TajikShop';
  String get home       => lang == 'ru' ? 'Главная'   : lang == 'en' ? 'Home'      : 'Хона';
  String get discover   => lang == 'ru' ? 'Каталог'   : lang == 'en' ? 'Discover'  : 'Ёбед';
  String get favorites  => lang == 'ru' ? 'Избранное' : lang == 'en' ? 'Favorites' : 'Лайкҳо';
  String get cart       => lang == 'ru' ? 'Корзина'   : lang == 'en' ? 'Cart'      : 'Сабад';
  String get profile    => lang == 'ru' ? 'Профиль'   : lang == 'en' ? 'Profile'   : 'Профил';
  String get search     => lang == 'ru' ? 'Поиск'     : lang == 'en' ? 'Search'    : 'Ҷустуҷӯ';
  String get notifications => lang == 'ru' ? 'Уведомления' : lang == 'en' ? 'Notifications' : 'Огоҳиҳо';
  String get categories => lang == 'ru' ? 'Категории' : lang == 'en' ? 'Categories': 'Категорияҳо';
  String get allProducts=> lang == 'ru' ? 'Все товары': lang == 'en' ? 'All Products' : 'Ҳамаи маҳсулотҳо';
  String get trending   => lang == 'ru' ? 'Популярное': lang == 'en' ? 'Trending'  : '🔥 Маъруб';
  String get flashSale  => lang == 'ru' ? 'Флеш распродажа' : lang == 'en' ? 'Flash Sale' : '⚡ Flash Sale';
  String get seeAll     => lang == 'ru' ? 'Все'       : lang == 'en' ? 'See All'   : 'Ҳама';
  String get addToCart  => lang == 'ru' ? 'В корзину' : lang == 'en' ? 'Add to Cart' : 'Ба сабад';
  String get buyNow     => lang == 'ru' ? 'Купить'    : lang == 'en' ? 'Buy Now'   : 'Харидан';
  String get outOfStock => lang == 'ru' ? 'Нет в наличии' : lang == 'en' ? 'Out of Stock' : 'Тамом шуд';
  String get login      => lang == 'ru' ? 'Войти'     : lang == 'en' ? 'Login'     : 'Ворид шудан';
  String get register   => lang == 'ru' ? 'Регистрация' : lang == 'en' ? 'Register' : 'Бақайдгирӣ';
  String get email      => lang == 'ru' ? 'Электронная почта' : lang == 'en' ? 'Email' : 'Почтаи электронӣ';
  String get password   => lang == 'ru' ? 'Пароль'    : lang == 'en' ? 'Password'  : 'Парол';
  String get fullName   => lang == 'ru' ? 'Полное имя': lang == 'en' ? 'Full Name'  : 'Номи пурра';
  String get logout     => lang == 'ru' ? 'Выйти'     : lang == 'en' ? 'Logout'    : 'Баромадан';
  String get becomeSeller => lang == 'ru' ? 'Стать продавцом' : lang == 'en' ? 'Become Seller' : 'Фурӯшанда шудан';
  String get sellerDashboard => lang == 'ru' ? 'Панель продавца' : lang == 'en' ? 'Seller Dashboard' : 'Панели фурӯшанда';
  String get orders     => lang == 'ru' ? 'Заказы'    : lang == 'en' ? 'Orders'    : 'Фармоишҳо';
  String get settings   => lang == 'ru' ? 'Настройки' : lang == 'en' ? 'Settings'  : 'Танзимот';
  String get language   => lang == 'ru' ? 'Язык'      : lang == 'en' ? 'Language'  : 'Забон';
  String get darkMode   => lang == 'ru' ? 'Тёмная тема' : lang == 'en' ? 'Dark Mode' : 'Тарзи торик';
  String get lightMode  => lang == 'ru' ? 'Светлая тема' : lang == 'en' ? 'Light Mode' : 'Тарзи равшан';
  String get about      => lang == 'ru' ? 'О приложении' : lang == 'en' ? 'About'   : 'Дар бораи барнома';
  String get seller     => lang == 'ru' ? 'Продавец'  : lang == 'en' ? 'Seller'    : 'Фурӯшанда';
  String get buyer      => lang == 'ru' ? 'Покупатель': lang == 'en' ? 'Buyer'     : 'Харидор';
  String get admin      => lang == 'ru' ? 'Администратор' : lang == 'en' ? 'Admin' : 'Маъмур';
  String get error      => lang == 'ru' ? 'Ошибка'    : lang == 'en' ? 'Error'     : 'Хато';
  String get retry      => lang == 'ru' ? 'Повторить' : lang == 'en' ? 'Retry'     : 'Дубора';
  String get searchHint => lang == 'ru' ? 'Товары, продавцы...' : lang == 'en' ? 'Products, sellers...' : 'Маҳсулот, фурӯшанда...';
  String get noResults  => lang == 'ru' ? 'Нет результатов' : lang == 'en' ? 'No results' : 'Натиҷа нест';
  String get emptyCart  => lang == 'ru' ? 'Корзина пуста' : lang == 'en' ? 'Cart is empty' : 'Сабад холӣ аст';
  String get checkout   => lang == 'ru' ? 'Оформить заказ' : lang == 'en' ? 'Checkout' : 'Пардохт';
  String get total      => lang == 'ru' ? 'Итого'     : lang == 'en' ? 'Total'     : 'Ҷамъ';
  String get som        => lang == 'ru' ? 'сом.'      : lang == 'en' ? 'som.'      : 'сом.';
  String get uploadProduct => lang == 'ru' ? 'Добавить товар' : lang == 'en' ? 'Upload Product' : 'Маҳсулот гузоштан';
  String get successUpload => lang == 'ru' ? 'Товар добавлен! 🎉' : lang == 'en' ? 'Product uploaded! 🎉' : 'Маҳсулот гузошта шуд! 🎉';
  String get becomeSellerSuccess => lang == 'ru' ? 'Вы стали продавцом! 🎉' : lang == 'en' ? 'You are now a seller! 🎉' : 'Шумо фурӯшанда шудед! 🎉';
  String get noNotifications => lang == 'ru' ? 'Нет уведомлений' : lang == 'en' ? 'No notifications' : 'Огоҳӣ нест';
  String get markAllRead => lang == 'ru' ? 'Отметить все' : lang == 'en' ? 'Mark all read' : 'Ҳама хонда шуданд';
  String get save       => lang == 'ru' ? 'Сохранить' : lang == 'en' ? 'Save'      : 'Захира кардан';
  String get cancel     => lang == 'ru' ? 'Отмена'    : lang == 'en' ? 'Cancel'    : 'Бекор кардан';
  String get freeDelivery => lang == 'ru' ? 'Бесплатная доставка' : lang == 'en' ? 'Free Delivery' : 'Доставка ройгон';
  String get verified   => lang == 'ru' ? 'Проверено' : lang == 'en' ? 'Verified'  : 'Тасдиқшуда';
  String get returns    => lang == 'ru' ? 'Возврат'   : lang == 'en' ? 'Returns'   : 'Бозгашт';
  String get support    => lang == 'ru' ? 'Поддержка' : lang == 'en' ? 'Support'   : 'Дастгирӣ';
  String get dontHaveAccount => lang == 'ru' ? 'Нет аккаунта?' : lang == 'en' ? "Don't have account?" : 'Аккаунт надоред?';
  String get alreadyHaveAccount => lang == 'ru' ? 'Уже есть аккаунт?' : lang == 'en' ? 'Already have account?' : 'Аллакай аккаунт доред?';
  String get signIn     => lang == 'ru' ? 'Войти'     : lang == 'en' ? 'Sign In'   : 'Ворид шавед';
  String get signUp     => lang == 'ru' ? 'Зарегистрироваться' : lang == 'en' ? 'Sign Up' : 'Бақайдгирӣ';
  String get editProfile => lang == 'ru' ? 'Редактировать профиль' : lang == 'en' ? 'Edit Profile' : 'Вироиши профил';
  String get myProducts => lang == 'ru' ? 'Мои товары' : lang == 'en' ? 'My Products' : 'Маҳсулотҳои ман';
  String get noProducts => lang == 'ru' ? 'Нет товаров' : lang == 'en' ? 'No products' : 'Маҳсулот нест';
}
