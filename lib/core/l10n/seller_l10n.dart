import 'package:flutter/widgets.dart';
import '../app_l10n.dart';

/// Localization strings for SELLER / PROFILE screens.
/// Extends [AppL10n] so getters are available via `AppL10n.of(context)`.
/// Reuse existing [AppL10n] keys where they already fit; only new strings live here.
extension SellerL10n on AppL10n {
  // ── Profile screen ──────────────────────────────────────────────────────
  String get profileImageUpdated =>
      lang == 'ru' ? 'Фото обновлено ✅' : lang == 'en' ? 'Photo updated ✅' : 'Расм нав шуд ✅';
  String get profileImageFailed =>
      lang == 'ru' ? 'Не удалось загрузить фото' : lang == 'en' ? 'Failed to upload photo' : 'Расм бор нашуд';
  String get profileUserNameField =>
      lang == 'ru' ? 'Имя пользователя' : lang == 'en' ? 'Username' : 'Номи корбар';
  String get profileBioField =>
      lang == 'ru' ? 'Био (о себе)' : lang == 'en' ? 'Bio (about you)' : 'Био (дар бораи худ)';
  String get profileUpdated =>
      lang == 'ru' ? 'Профиль обновлён ✅' : lang == 'en' ? 'Profile updated ✅' : 'Профил нав шуд ✅';
  String get profileLocationSaved =>
      lang == 'ru' ? 'Локация магазина сохранена 📍' : lang == 'en' ? 'Store location saved 📍' : 'Ҷойгиршавии мағоза сабт шуд 📍';
  String get profileLocationFailed =>
      lang == 'ru' ? 'Не удалось сохранить локацию' : lang == 'en' ? 'Failed to save location' : 'Ҷойгиршавӣ сабт нашуд';
  String get profileAboutText =>
      lang == 'ru' ? 'Онлайн-рынок Таджикистана — лёгкие покупки и продажи.' : lang == 'en' ? 'Tajikistan online marketplace — easy buying and selling.' : 'Бозори онлайни Тоҷикистон — харид ва фурӯши осон.';

  // ── Seller dashboard ────────────────────────────────────────────────────
  String get sellerSectionSoon =>
      lang == 'ru' ? 'Этот раздел скоро появится' : lang == 'en' ? 'This section is coming soon' : 'Ин бахш ба зудӣ илова мешавад';
  String get sellerMyStore =>
      lang == 'ru' ? 'Мой магазин' : lang == 'en' ? 'My Store' : 'Дӯкони ман';
  String get sellerAddShort =>
      lang == 'ru' ? 'Добавить' : lang == 'en' ? 'Add' : 'Илова';
  String get sellerActiveSeller =>
      lang == 'ru' ? 'Активный продавец' : lang == 'en' ? 'Active seller' : 'Фурӯшандаи фаъол';
  String get sellerVerifiedBadge =>
      lang == 'ru' ? '✓ Проверен' : lang == 'en' ? '✓ Verified' : '✓ Тасдиқ';
  String get sellerStats =>
      lang == 'ru' ? 'Статистика' : lang == 'en' ? 'Statistics' : 'Оморҳо';
  String get sellerRevenue =>
      lang == 'ru' ? 'Доход' : lang == 'en' ? 'Revenue' : 'Даромад';
  String get sellerCustomers =>
      lang == 'ru' ? 'Клиенты' : lang == 'en' ? 'Customers' : 'Мизоҷон';
  String get sellerActions =>
      lang == 'ru' ? 'Действия' : lang == 'en' ? 'Actions' : 'Амалиётҳо';
  String get sellerAddProduct =>
      lang == 'ru' ? 'Добавить товар' : lang == 'en' ? 'Add product' : 'Маҳсулот илова кунед';
  String get sellerAddProductSub =>
      lang == 'ru' ? 'Разместите новый товар' : lang == 'en' ? 'Post a new product' : 'Маҳсулоти нав эълон кунед';
  String get sellerManageProductsSub =>
      lang == 'ru' ? 'Управление товарами' : lang == 'en' ? 'Manage products' : 'Идораи маҳсулотҳо';
  String get sellerNewOrders =>
      lang == 'ru' ? 'Новые заказы' : lang == 'en' ? 'New orders' : 'Фармоишҳои нав';
  String get sellerNewOrdersSub =>
      lang == 'ru' ? 'Смотрите ожидающие заказы' : lang == 'en' ? 'View pending orders' : 'Фармоишҳои интизорро бубинед';
  String get sellerSalesStats =>
      lang == 'ru' ? 'Статистика продаж' : lang == 'en' ? 'Sales stats' : 'Оморҳои фурӯш';
  String get sellerSalesStatsSub =>
      lang == 'ru' ? 'Отчёт о моих продажах' : lang == 'en' ? 'My sales report' : 'Гузориши фурӯши ман';

  // ── My products ─────────────────────────────────────────────────────────
  String get sellerNoProductsYet =>
      lang == 'ru' ? 'У вас пока нет товаров' : lang == 'en' ? 'You have no products yet' : 'Шумо ҳоло маҳсулот надоред';
  String get sellerActive =>
      lang == 'ru' ? 'Активен' : lang == 'en' ? 'Active' : 'Фаъол';
  String get sellerInactive =>
      lang == 'ru' ? 'Неактивен' : lang == 'en' ? 'Inactive' : 'Ғайрифаъол';
  String get sellerEditAction =>
      lang == 'ru' ? 'Изменить' : lang == 'en' ? 'Edit' : 'Таҳрир';
  String get sellerDeleteAction =>
      lang == 'ru' ? 'Удалить' : lang == 'en' ? 'Delete' : 'Нест';
  String get sellerDeleteTitle =>
      lang == 'ru' ? 'Удалить?' : lang == 'en' ? 'Delete?' : 'Нест кардан?';
  String get sellerDeleteQuestion =>
      lang == 'ru' ? 'удалить?' : lang == 'en' ? 'delete?' : 'нест карда шавад?';
  String get sellerNo =>
      lang == 'ru' ? 'Нет' : lang == 'en' ? 'No' : 'Не';
  String get sellerYesDelete =>
      lang == 'ru' ? 'Да, удалить' : lang == 'en' ? 'Yes, delete' : 'Бале, нест кун';
  String get sellerProductDeleted =>
      lang == 'ru' ? 'Товар удалён' : lang == 'en' ? 'Product deleted' : 'Маҳсулот нест карда шуд';
  String get sellerDeleteError =>
      lang == 'ru' ? 'Ошибка при удалении' : lang == 'en' ? 'Error while deleting' : 'Хато ҳангоми нест кардан';
  String get sellerEditProductTitle =>
      lang == 'ru' ? 'Редактировать товар' : lang == 'en' ? 'Edit product' : 'Таҳрири маҳсулот';
  String get sellerFieldName =>
      lang == 'ru' ? 'Название' : lang == 'en' ? 'Name' : 'Ном';
  String get sellerDiscountPercent =>
      lang == 'ru' ? 'Скидка (%)' : lang == 'en' ? 'Discount (%)' : 'Тахфиф (%)';
  String get sellerStock =>
      lang == 'ru' ? 'Склад' : lang == 'en' ? 'Stock' : 'Захира';
  String get sellerFlashSaleField =>
      lang == 'ru' ? '⚡ Flash sale (часы, пусто=без изменений, -1=отмена)' : lang == 'en' ? '⚡ Flash sale (hours, empty=no change, -1=cancel)' : '⚡ Flash sale (соат, холӣ=тағйир нест, -1=бекор)';
  String get sellerActiveInMarket =>
      lang == 'ru' ? 'Активен (показ на рынке)' : lang == 'en' ? 'Active (show in market)' : 'Фаъол (намоиш дар бозор)';
  String get sellerProductUpdated =>
      lang == 'ru' ? 'Товар обновлён ✅' : lang == 'en' ? 'Product updated ✅' : 'Маҳсулот навсозӣ шуд ✅';
  String get sellerUpdateError =>
      lang == 'ru' ? 'Ошибка при обновлении' : lang == 'en' ? 'Error while updating' : 'Хато ҳангоми навсозӣ';

  // ── Add product ─────────────────────────────────────────────────────────
  String get sellerProductPublished =>
      lang == 'ru' ? '✅ Товар опубликован!' : lang == 'en' ? '✅ Product published!' : '✅ Маҳсулот нашр шуд!';
  String get sellerPhotosUpTo5 =>
      lang == 'ru' ? 'Фото (до 5)' : lang == 'en' ? 'Photos (up to 5)' : 'Расмҳо (то 5)';
  String get sellerProductInfo =>
      lang == 'ru' ? 'Информация о товаре' : lang == 'en' ? 'Product information' : 'Маълумоти маҳсулот';
  String get sellerNameRequired =>
      lang == 'ru' ? 'Название обязательно' : lang == 'en' ? 'Name required' : 'Ном лозим аст';
  String get sellerPriceRequired =>
      lang == 'ru' ? 'Цена обязательна' : lang == 'en' ? 'Price required' : 'Нарх лозим';
  String get sellerStockRequired =>
      lang == 'ru' ? 'Склад обязателен' : lang == 'en' ? 'Stock required' : 'Захира лозим';
  String get sellerProductDescField =>
      lang == 'ru' ? 'Описание товара' : lang == 'en' ? 'Product description' : 'Тавсифи маҳсулот';
  String get sellerDescRequired =>
      lang == 'ru' ? 'Описание обязательно' : lang == 'en' ? 'Description required' : 'Тавсиф лозим аст';

  // ── Manage variants ─────────────────────────────────────────────────────
  String get sellerVariantsTitle =>
      lang == 'ru' ? 'Варианты (размер/цвет)' : lang == 'en' ? 'Variants (size/color)' : 'Вариантҳо (андоза/ранг)';
  String get sellerVariant =>
      lang == 'ru' ? 'Вариант' : lang == 'en' ? 'Variant' : 'Вариант';
  String get sellerNoVariants =>
      lang == 'ru' ? 'Нет вариантов.\nДобавьте размер/цвет.' : lang == 'en' ? 'No variants.\nAdd size/color.' : 'Вариант нест.\nАндоза/рангро илова кунед.';
  String get sellerNewVariant =>
      lang == 'ru' ? 'Новый вариант' : lang == 'en' ? 'New variant' : 'Варианти нав';
  String get sellerSizeHint =>
      lang == 'ru' ? 'Размер (S, M, 42...)' : lang == 'en' ? 'Size (S, M, 42...)' : 'Андоза (S, M, 42...)';
  String get sellerColor =>
      lang == 'ru' ? 'Цвет' : lang == 'en' ? 'Color' : 'Ранг';
  String get sellerPriceOptional =>
      lang == 'ru' ? 'Цена (необязательно)' : lang == 'en' ? 'Price (optional)' : 'Нарх (ихтиёрӣ)';
  String get sellerSkuOptional =>
      lang == 'ru' ? 'SKU (необязательно)' : lang == 'en' ? 'SKU (optional)' : 'SKU (ихтиёрӣ)';
  String get sellerAddAction =>
      lang == 'ru' ? 'Добавить' : lang == 'en' ? 'Add' : 'Илова кардан';
  String get sellerEnterSizeOrColor =>
      lang == 'ru' ? 'Введите размер или цвет' : lang == 'en' ? 'Enter size or color' : 'Андоза ё рангро ворид кунед';

  // ── Seller public profile ───────────────────────────────────────────────
  String get sellerFollowers =>
      lang == 'ru' ? 'Подписчики' : lang == 'en' ? 'Followers' : 'Пайравон';
  String get sellerRating =>
      lang == 'ru' ? 'Рейтинг' : lang == 'en' ? 'Rating' : 'Баҳо';
  String get sellerFollowAction =>
      lang == 'ru' ? 'Подписаться' : lang == 'en' ? 'Follow' : 'Пайгирӣ кардан';
  String get sellerStoreProducts =>
      lang == 'ru' ? 'Товары магазина' : lang == 'en' ? 'Store products' : 'Маҳсулоти дӯкон';

  // ── Seller verify (KYC) sheet ───────────────────────────────────────────
  String get sellerVerifyRequestSent =>
      lang == 'ru' ? 'Запрос отправлен. После одобрения администратором вы станете продавцом. ⏳' : lang == 'en' ? 'Request sent. You will become a seller after admin approval. ⏳' : 'Дархости шумо фиристода шуд. Баъди тасдиқи админ фурӯшанда мешавед. ⏳';
  String get sellerRequestPending =>
      lang == 'ru' ? 'Ваш запрос на становление продавцом рассматривается ⏳' : lang == 'en' ? 'Your seller request is under review ⏳' : 'Дархости фурӯшандашавии шумо баррасӣ мешавад ⏳';
  String get sellerRequestPendingUpload =>
      lang == 'ru' ? 'Ваш запрос на становление продавцом рассматривается. После одобрения администратором вы сможете размещать объявления.' : lang == 'en' ? 'Your seller request is under review. You can post listings after admin approval.' : 'Дархости фурӯшандашавии шумо баррасӣ мешавад. Баъди тасдиқи админ метавонед эълон гузоред.';
  String get sellerBecomeToPost =>
      lang == 'ru' ? 'Чтобы разместить объявление, сначала станьте продавцом' : lang == 'en' ? 'To post a listing, become a seller first' : 'Барои эълон гузоштан аввал фурӯшанда шавед';
  String get sellerVerifyError =>
      lang == 'ru' ? 'Ошибка. Попробуйте снова' : lang == 'en' ? 'Error. Try again' : 'Хато. Дубора кӯшиш кунед';
  String get sellerVerifyTitle =>
      lang == 'ru' ? 'Стать продавцом 🏪' : lang == 'en' ? 'Become a seller 🏪' : 'Фурӯшанда шудан 🏪';
  String get sellerVerifyDesc =>
      lang == 'ru' ? 'Для безопасности покупателей загрузите фото паспорта (или удостоверения). Админ проверит его и выдаст знак «проверено».' : lang == 'en' ? 'For buyers safety, upload a photo of your passport (or ID). Admin will verify it and grant a "verified" badge.' : 'Барои бехатарии харидорон, акси паспорт (ё шиноснома)-ро бор кунед. Админ онро месанҷад ва нишони «тасдиқшуда» медиҳад.';
  String get sellerUploadPassport =>
      lang == 'ru' ? 'Загрузите фото паспорта' : lang == 'en' ? 'Upload passport photo' : 'Акси паспортро бор кунед';
  String get sellerDataPrivate =>
      lang == 'ru' ? 'Ваши данные хранятся конфиденциально.' : lang == 'en' ? 'Your data is kept confidential.' : 'Маълумоти шумо махфӣ нигоҳ дошта мешавад.';
  String get sellerUploadPhotoFirst =>
      lang == 'ru' ? 'Сначала загрузите фото' : lang == 'en' ? 'Upload photo first' : 'Аввал акс бор кунед';
  String get sellerSubmitBecomeSeller =>
      lang == 'ru' ? 'Отправить и стать продавцом' : lang == 'en' ? 'Submit and become a seller' : 'Фиристодан ва фурӯшанда шудан';
}
