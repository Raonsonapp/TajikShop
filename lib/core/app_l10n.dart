import 'package:flutter/material.dart';

class AppL10n {
  final String lang;
  AppL10n(this.lang);

  static AppL10n of(BuildContext context) =>
      Localizations.of<AppL10n>(context, AppL10n) ?? AppL10n('tg');

  String get appName    => 'TajikShop Pro';
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
  String get myWallet   => lang == 'ru' ? 'Мой кошелёк' : lang == 'en' ? 'My Wallet' : 'Ҳамёни ман';
  String get myAddresses => lang == 'ru' ? 'Мои адреса' : lang == 'en' ? 'My Addresses' : 'Суроғаҳои ман';
  String get storeLocation => lang == 'ru' ? 'Локация магазина (GPS)' : lang == 'en' ? 'Store Location (GPS)' : 'Ҷойгиршавии мағоза (GPS)';
  String get popularSearches => lang == 'ru' ? 'Популярные запросы' : lang == 'en' ? 'Popular searches' : 'Ҷустуҷӯи маъмул';
  String get searchProductsHint => lang == 'ru' ? 'Поиск товаров...' : lang == 'en' ? 'Search products...' : 'Ҷустуҷӯи маҳсулот...';

  // ── Home ──
  String get noProductsYet => lang == 'ru' ? 'Пока нет товаров' : lang == 'en' ? 'No products yet' : 'Ҳоло маҳсулот нест';
  String get beFirstToPost => lang == 'ru' ? 'Разместите первое объявление! 🚀' : lang == 'en' ? 'Post the first listing! 🚀' : 'Аввалин эълонро шумо гузоред! 🚀';

  // ── Product detail ──
  String get report => lang == 'ru' ? 'Пожаловаться' : lang == 'en' ? 'Report' : 'Гузориш додан';
  String get endsIn => lang == 'ru' ? 'Конец: ' : lang == 'en' ? 'Ends: ' : 'Тамом: ';
  String get reviewsWord => lang == 'ru' ? 'отзывов' : lang == 'en' ? 'reviews' : 'шарҳ';
  String get inStock => lang == 'ru' ? '✓ В наличии' : lang == 'en' ? '✓ In Stock' : '✓ Мавҷуд';
  String get notAvailable => lang == 'ru' ? '✗ Нет' : lang == 'en' ? '✗ Out' : '✗ Нест';
  String get variants => lang == 'ru' ? 'Варианты' : lang == 'en' ? 'Variants' : 'Вариантҳо';
  String get notAvailableShort => lang == 'ru' ? 'нет' : lang == 'en' ? 'N/A' : 'нест';
  String get wholesalePriceLabel => lang == 'ru' ? 'Оптовая цена' : lang == 'en' ? 'Wholesale price' : 'Нархи яклухт';
  String get from => lang == 'ru' ? 'от' : lang == 'en' ? 'from' : 'аз';
  String get pcs => lang == 'ru' ? 'шт' : lang == 'en' ? 'pcs' : 'дона';
  String get minOrderLabel => lang == 'ru' ? 'Мин. заказ' : lang == 'en' ? 'Min order' : 'Ҳадди ақали фармоиш';
  String get messageWord => lang == 'ru' ? 'Сообщение' : lang == 'en' ? 'Message' : 'Паём';
  String get description => lang == 'ru' ? 'Описание' : lang == 'en' ? 'Description' : 'Тавсиф';
  String get noDescription => lang == 'ru' ? 'Нет описания' : lang == 'en' ? 'No description' : 'Тавсифе нест';
  String get reviewsTitle => lang == 'ru' ? 'Отзывы' : lang == 'en' ? 'Reviews' : 'Шарҳҳо';
  String get writeReview => lang == 'ru' ? 'Написать отзыв' : lang == 'en' ? 'Write review' : 'Шарҳ навиштан';
  String get noReviewsYet => lang == 'ru' ? 'Пока нет отзывов. Будьте первым!' : lang == 'en' ? 'No reviews yet. Be the first!' : 'Ҳоло шарҳе нест. Аввалин шуда шарҳ нависед!';
  String get andMore => lang == 'ru' ? 'и ещё' : lang == 'en' ? 'and' : 'ва боз';
  String get qaTitle => lang == 'ru' ? 'Вопросы и ответы' : lang == 'en' ? 'Q&A' : 'Савол ва ҷавоб';
  String get askQuestion => lang == 'ru' ? 'Задать вопрос' : lang == 'en' ? 'Ask question' : 'Савол додан';
  String get noQuestionsYet => lang == 'ru' ? 'Пока нет вопросов. Спросите первым!' : lang == 'en' ? 'No questions yet. Ask first!' : 'Ҳоло саволе нест. Аввалин шуда пурсед!';
  String get questionShort => lang == 'ru' ? 'В: ' : lang == 'en' ? 'Q: ' : 'С: ';
  String get answerShort => lang == 'ru' ? 'О: ' : lang == 'en' ? 'A: ' : 'Ҷ: ';
  String get answerAction => lang == 'ru' ? 'Ответить' : lang == 'en' ? 'Answer' : 'Ҷавоб додан';
  String get noAnswerYet => lang == 'ru' ? 'Пока нет ответа' : lang == 'en' ? 'No answer yet' : 'Ҳанӯз ҷавоб нест';
  String get askQuestionTitle => lang == 'ru' ? 'Напишите свой вопрос' : lang == 'en' ? 'Write your question' : 'Саволи худро нависед';
  String get askQuestionHint => lang == 'ru' ? 'Например: Есть гарантия?' : lang == 'en' ? 'E.g.: Is there a warranty?' : 'Масалан: Кафолат дорад?';
  String get send => lang == 'ru' ? 'Отправить' : lang == 'en' ? 'Send' : 'Фиристодан';
  String get questionSent => lang == 'ru' ? 'Вопрос отправлен ✅' : lang == 'en' ? 'Question sent ✅' : 'Савол фиристода шуд ✅';
  String get yourAnswer => lang == 'ru' ? 'Ваш ответ' : lang == 'en' ? 'Your answer' : 'Ҷавоби шумо';
  String get writeAnswerHint => lang == 'ru' ? 'Напишите ответ...' : lang == 'en' ? 'Write answer...' : 'Ҷавобро нависед...';
  String get loginToReview => lang == 'ru' ? 'Войдите, чтобы оставить отзыв' : lang == 'en' ? 'Login to write a review' : 'Барои шарҳ навиштан ворид шавед';
  String get similarProducts => lang == 'ru' ? 'Похожие товары' : lang == 'en' ? 'Similar products' : 'Маҳсулоти монанд';
  String get addedToCart => lang == 'ru' ? '✅ Добавлено в корзину' : lang == 'en' ? '✅ Added to cart' : '✅ Ба сабад илова шуд';
  String get loginToBuy => lang == 'ru' ? 'Войдите для покупки' : lang == 'en' ? 'Login to buy' : 'Барои харид ворид шавед';
  String get loginToFavorite => lang == 'ru' ? 'Войдите, чтобы добавить в избранное' : lang == 'en' ? 'Login to add to favorites' : 'Барои дӯстдошта ворид шавед';
  String get copied => lang == 'ru' ? 'Скопировано 📋' : lang == 'en' ? 'Copied 📋' : 'Нусха гирифта шуд 📋';
  String get errorAddingToCart => lang == 'ru' ? 'Ошибка при добавлении в корзину' : lang == 'en' ? 'Error adding to cart' : 'Хато ҳангоми илова ба сабад';
  String get loginToMessage => lang == 'ru' ? 'Войдите, чтобы написать сообщение' : lang == 'en' ? 'Login to send a message' : 'Барои паём навиштан ворид шавед';
  String get loginToReport => lang == 'ru' ? 'Войдите, чтобы пожаловаться' : lang == 'en' ? 'Login to report' : 'Барои гузориш ворид шавед';
  String get reportReasonFake => lang == 'ru' ? 'Подделка / мошенник' : lang == 'en' ? 'Fake / scam' : 'Қалбакӣ / фиребгар';
  String get reportReasonWrongPrice => lang == 'ru' ? 'Неверная цена' : lang == 'en' ? 'Wrong price' : 'Нархи нодуруст';
  String get reportReasonInappropriate => lang == 'ru' ? 'Неприемлемый контент' : lang == 'en' ? 'Inappropriate content' : 'Мӯҳтавои номатлуб';
  String get reportReasonSpam => lang == 'ru' ? 'Спам' : lang == 'en' ? 'Spam' : 'Спам';
  String get reportReasonOther => lang == 'ru' ? 'Другое' : lang == 'en' ? 'Other' : 'Дигар';
  String get reportReasonTitle => lang == 'ru' ? 'Причина жалобы' : lang == 'en' ? 'Report reason' : 'Сабаби гузориш';
  String get reportSent => lang == 'ru' ? 'Жалоба отправлена. Спасибо!' : lang == 'en' ? 'Report sent. Thank you!' : 'Гузориш фиристода шуд. Раҳмат!';
  String get following => lang == 'ru' ? 'Вы подписаны' : lang == 'en' ? 'Following' : 'Пайгирӣ шуд';
  String get follow => lang == 'ru' ? 'Подписаться' : lang == 'en' ? 'Follow' : 'Пайгирӣ';
  String get loginToFollow => lang == 'ru' ? 'Войдите, чтобы подписаться' : lang == 'en' ? 'Login to follow' : 'Барои пайгирӣ ворид шавед';
  String get loginToAsk => lang == 'ru' ? 'Войдите, чтобы задать вопрос' : lang == 'en' ? 'Login to ask a question' : 'Барои савол додан ворид шавед';
  String get loginToVote => lang == 'ru' ? 'Войдите, чтобы проголосовать' : lang == 'en' ? 'Login to vote' : 'Барои овоз додан ворид шавед';
  String get helpful => lang == 'ru' ? 'Полезно' : lang == 'en' ? 'Helpful' : 'Фоиданок';
  String get userWord => lang == 'ru' ? 'Пользователь' : lang == 'en' ? 'User' : 'Корбар';
  String get rateThis => lang == 'ru' ? 'Поставьте оценку' : lang == 'en' ? 'Rate this' : 'Баҳои худро гузоред';
  String get reviewHint => lang == 'ru' ? 'Напишите своё мнение (необязательно)...' : lang == 'en' ? 'Write your opinion (optional)...' : 'Фикри худро нависед (ихтиёрӣ)...';
  String get reviewAdded => lang == 'ru' ? 'Ваш отзыв добавлен ✅' : lang == 'en' ? 'Your review added ✅' : 'Шарҳи шумо илова шуд ✅';
  String get errorSendingReview => lang == 'ru' ? 'Ошибка при отправке отзыва' : lang == 'en' ? 'Error sending review' : 'Хато ҳангоми фиристодани шарҳ';

  // ── Cart / checkout ──
  String get loginToViewCart => lang == 'ru' ? 'Войдите, чтобы посмотреть корзину' : lang == 'en' ? 'Login to view cart' : 'Барои дидани сабад ворид шавед';
  String get clearShort => lang == 'ru' ? 'Очистить' : lang == 'en' ? 'Clear' : 'Тоза';
  String get shopNow => lang == 'ru' ? 'За покупками' : lang == 'en' ? 'Shop now' : 'Харид кунед';
  String get productsWord => lang == 'ru' ? 'Товары' : lang == 'en' ? 'Products' : 'Маҳсулот';
  String get delivery => lang == 'ru' ? 'Доставка' : lang == 'en' ? 'Delivery' : 'Доставка';
  String get payNow => lang == 'ru' ? 'Оплатить' : lang == 'en' ? 'Pay now' : 'Пардохт кардан';
  String get addAddress => lang == 'ru' ? 'Добавить адрес' : lang == 'en' ? 'Add address' : 'Суроға илова кунед';
  String get orderAccepted => lang == 'ru' ? 'Заказ принят!' : lang == 'en' ? 'Order accepted!' : 'Фармоиш қабул шуд!';
  String get orderReceiptSent => lang == 'ru' ? 'Чек отправлен продавцу. Подтверждение после проверки.' : lang == 'en' ? 'Receipt sent to seller. Confirmation after review.' : 'Чек ба фурӯшанда фиристода шуд. Тасдиқ баъд аз санҷиш.';
  String get myOrders => lang == 'ru' ? 'Мои заказы' : lang == 'en' ? 'My Orders' : 'Фармоишҳоям';
  String get confirmOrder => lang == 'ru' ? 'Подтверждение заказа' : lang == 'en' ? 'Confirm order' : 'Тасдиқи фармоиш';
  String get deliveryAddress => lang == 'ru' ? 'Адрес доставки' : lang == 'en' ? 'Delivery address' : 'Суроғаи расонидан';
  String get couponPromo => lang == 'ru' ? 'Купон / Промокод' : lang == 'en' ? 'Coupon / Promo' : 'Купон / Промокод';
  String get enterCode => lang == 'ru' ? 'Введите код' : lang == 'en' ? 'Enter code' : 'Кодро ворид кунед';
  String get apply => lang == 'ru' ? 'Применить' : lang == 'en' ? 'Apply' : 'Татбиқ';
  String get discountApplied => lang == 'ru' ? 'скидка применена' : lang == 'en' ? 'discount applied' : 'тахфиф татбиқ шуд';
  String get couponInvalid => lang == 'ru' ? '❌ Купон неверный или истёк' : lang == 'en' ? '❌ Coupon invalid or expired' : '❌ Купон нодуруст ё гузаштааст';
  String get paymentMethod => lang == 'ru' ? 'Способ оплаты' : lang == 'en' ? 'Payment method' : 'Усули пардохт';
  String get dcCard => lang == 'ru' ? 'Карта DC' : lang == 'en' ? 'DC Card' : 'Корти DC';
  String get dcCardDesc => lang == 'ru' ? 'Перевод + чек оплаты' : lang == 'en' ? 'Transfer + payment receipt' : 'Интиқол + чеки пардохт';
  String get codTitle => lang == 'ru' ? 'Оплата при доставке' : lang == 'en' ? 'Cash on delivery' : 'Пардохт ҳангоми расонидан';
  String get codDesc => lang == 'ru' ? 'Наличными курьеру' : lang == 'en' ? 'Cash to courier' : 'Накд ба курьер';
  String get wallet => lang == 'ru' ? 'Кошелёк' : lang == 'en' ? 'Wallet' : 'Ҳамён';
  String get balance => lang == 'ru' ? 'Баланс' : lang == 'en' ? 'Balance' : 'Тавозун';
  String get insufficient => lang == 'ru' ? 'недостаточно' : lang == 'en' ? 'insufficient' : 'нокифоя';
  String get sellerDcNumber => lang == 'ru' ? 'Номер DC продавца' : lang == 'en' ? "Seller's DC number" : 'Рақами DC-и фурӯшанда';
  String get dcInstructions => lang == 'ru' ? 'Переведите деньги на этот номер, затем загрузите чек' : lang == 'en' ? 'Transfer money to this number, then upload the receipt' : 'Пулро ба ин рақам интиқол диҳед, баъд чекро бор кунед';
  String get uploadReceipt => lang == 'ru' ? 'Загрузите чек оплаты' : lang == 'en' ? 'Upload payment receipt' : 'Чеки пардохтро бор кунед';
  String get uploadReceiptFirst => lang == 'ru' ? 'Сначала загрузите чек оплаты' : lang == 'en' ? 'Upload payment receipt first' : 'Аввал чеки пардохтро бор кунед';
  String get productsPlusDelivery => lang == 'ru' ? 'Товары + доставка' : lang == 'en' ? 'Products + delivery' : 'Маҳсулот + доставка';
  String get discountWord => lang == 'ru' ? 'Скидка' : lang == 'en' ? 'Discount' : 'Тахфиф';
  String get totalPayment => lang == 'ru' ? 'Итого к оплате' : lang == 'en' ? 'Total payment' : 'Ҷамъи пардохт';
  String get errorDuringPayment => lang == 'ru' ? 'Ошибка при оплате' : lang == 'en' ? 'Payment error' : 'Хато ҳангоми пардохт';
  String get payFromWallet => lang == 'ru' ? 'Оплатить с кошелька' : lang == 'en' ? 'Pay from wallet' : 'Пардохт аз ҳамён';

  // ── Upload ──
  String get becomeSellerFirst => lang == 'ru' ? 'Для публикации сначала станьте продавцом (паспорт)' : lang == 'en' ? 'To publish, become a seller first (passport)' : 'Барои нашр аввал фурӯшанда шавед (паспорт)';
  String get productPublished => lang == 'ru' ? 'Объявление опубликовано! 🎉' : lang == 'en' ? 'Listing published! 🎉' : 'Эълон нашр шуд! 🎉';
  String get unknownError => lang == 'ru' ? 'Неизвестная ошибка' : lang == 'en' ? 'Unknown error' : 'Хатои номаълум';
  String get postListing => lang == 'ru' ? 'Разместить объявление' : lang == 'en' ? 'Post listing' : 'Эълон додан';
  String get clearAll => lang == 'ru' ? 'Очистить' : lang == 'en' ? 'Clear' : 'Тоза кардан';
  String get photos => lang == 'ru' ? 'Фото' : lang == 'en' ? 'Photos' : 'Расмҳо';
  String get photosHint => lang == 'ru' ? 'Объявление с 3–5 фото привлекательнее' : lang == 'en' ? 'A listing with 3–5 photos is more attractive' : 'Беҳтар бо 3–5 расм эълон диққатҷалб мешавад';
  String get addPhoto => lang == 'ru' ? 'Добавьте фото' : lang == 'en' ? 'Add photo' : 'Расм илова кунед';
  String get photosSubHint => lang == 'ru' ? 'До 5 фото • размер уменьшается автоматически' : lang == 'en' ? 'Up to 5 photos • size auto-reduced' : 'То 5 расм • хаҷм автоматӣ кам мешавад';
  String get basicInfo => lang == 'ru' ? 'Основная информация' : lang == 'en' ? 'Basic info' : 'Маълумоти асосӣ';
  String get productName => lang == 'ru' ? 'Название товара' : lang == 'en' ? 'Product name' : 'Номи маҳсулот';
  String get productNameHint => lang == 'ru' ? 'Введите название товара' : lang == 'en' ? 'Enter product name' : 'Номи маҳсулотро ворид кунед';
  String get price => lang == 'ru' ? 'Цена' : lang == 'en' ? 'Price' : 'Нарх';
  String get category => lang == 'ru' ? 'Категория' : lang == 'en' ? 'Category' : 'Категория';
  String get selectHint => lang == 'ru' ? 'Выберите' : lang == 'en' ? 'Select' : 'Интихоб кунед';
  String get descriptionHint => lang == 'ru' ? 'Опишите товар подробно...' : lang == 'en' ? 'Describe the product in detail...' : 'Маҳсулотро муфассал тавсиф кунед...';
  String get details => lang == 'ru' ? 'Детали' : lang == 'en' ? 'Details' : 'Тафсилот';
  String get conditionLabel => lang == 'ru' ? 'Состояние товара' : lang == 'en' ? 'Product condition' : 'Ҳолати маҳсулот';
  String get city => lang == 'ru' ? 'Город' : lang == 'en' ? 'City' : 'Шаҳр';
  String get quantity => lang == 'ru' ? 'Количество' : lang == 'en' ? 'Quantity' : 'Миқдор';
  String get mustBeSeller => lang == 'ru' ? 'Для публикации нужно стать продавцом' : lang == 'en' ? 'You must become a seller to publish' : 'Барои нашр фурӯшанда шудан лозим';
  String get mustBeSellerDesc => lang == 'ru' ? 'Если вы ещё не продавец, "Опубликовать" автоматически сделает вас продавцом.' : lang == 'en' ? 'If you are not a seller yet, "Publish" will automatically make you one.' : 'Агар шумо ҳанӯз фурӯшанда набошед, "Нашр кардан" автоматӣ шуморо фурӯшанда мекунад.';
  String get becomingSeller => lang == 'ru' ? 'Становление продавцом...' : lang == 'en' ? 'Becoming a seller...' : 'Фурӯшанда шудан...';
  String get uploaded => lang == 'ru' ? 'загружено' : lang == 'en' ? 'uploaded' : 'бор шуд';
  String get back => lang == 'ru' ? 'Назад' : lang == 'en' ? 'Back' : 'Қафо';
  String get preview => lang == 'ru' ? 'Просмотр' : lang == 'en' ? 'Preview' : 'Пешнамоиш';
  String get processing => lang == 'ru' ? 'Обработка...' : lang == 'en' ? 'Processing...' : 'Кор карда истода...';
  String get continueWord => lang == 'ru' ? 'Продолжить' : lang == 'en' ? 'Continue' : 'Давом додан';
  String get publish => lang == 'ru' ? 'Опубликовать' : lang == 'en' ? 'Publish' : 'Нашр кардан';
  String get enterName => lang == 'ru' ? 'Введите название' : lang == 'en' ? 'Enter name' : 'Номро ворид кунед';
  String get enterPrice => lang == 'ru' ? 'Введите цену' : lang == 'en' ? 'Enter price' : 'Нархро ворид кунед';
  String get loginToPost => lang == 'ru' ? 'Войдите, чтобы разместить объявление' : lang == 'en' ? 'Login to post a listing' : 'Барои эълон додан ворид шавед';

  // ── Orders ──
  String get noOrders => lang == 'ru' ? 'Нет заказов' : lang == 'en' ? 'No orders' : 'Фармоише нест';
  String get statusPending => lang == 'ru' ? 'В ожидании' : lang == 'en' ? 'Pending' : 'Дар интизор';
  String get statusProcessing => lang == 'ru' ? 'В обработке' : lang == 'en' ? 'Processing' : 'Коркард';
  String get statusShipped => lang == 'ru' ? 'Отправлен' : lang == 'en' ? 'Shipped' : 'Фиристода шуд';
  String get statusDelivered => lang == 'ru' ? 'Доставлен' : lang == 'en' ? 'Delivered' : 'Расид';
  String get statusCancelled => lang == 'ru' ? 'Отменён' : lang == 'en' ? 'Cancelled' : 'Бекор';
  String get itemsWord => lang == 'ru' ? 'товаров' : lang == 'en' ? 'items' : 'маҳсулот';

  // ── Favorites ──
  String get noFavorites => lang == 'ru' ? 'Нет избранного' : lang == 'en' ? 'No favorites' : 'Дӯстдоштаҳо нест';

  // ── Categories ──
  String get selectCategory => lang == 'ru' ? 'Выберите категорию' : lang == 'en' ? 'Select a category' : 'Категорияро интихоб кунед';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppL10n> {
  const AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['tg', 'ru', 'en'].contains(locale.languageCode);
  @override
  Future<AppL10n> load(Locale locale) async => AppL10n(locale.languageCode);
  @override
  bool shouldReload(_) => false;
}
