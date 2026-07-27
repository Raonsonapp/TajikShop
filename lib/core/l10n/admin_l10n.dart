import 'package:flutter/widgets.dart';
import '../app_l10n.dart';

/// Localization strings for ADMIN + shared screens.
/// Reuses existing AppL10n keys where possible (error, orders, retry, save, cancel, etc.).
extension AdminL10n on AppL10n {
  // ── Dashboard ──
  String get adminPanel        => lang == 'ru' ? 'Панель админа'          : lang == 'en' ? 'Admin Panel'          : 'Панели Админ';
  String get adminPanelFull    => lang == 'ru' ? 'Панель администратора'  : lang == 'en' ? 'Administrator Panel'  : 'Панели Администратор';
  String get statistics        => lang == 'ru' ? 'Статистика'            : lang == 'en' ? 'Statistics'           : 'Оморҳо';
  String get noData            => lang == 'ru' ? 'Нет данных'            : lang == 'en' ? 'No data'              : 'Маълумот нест';
  String get usersLabel        => lang == 'ru' ? 'Пользователи'          : lang == 'en' ? 'Users'                : 'Корбарон';
  String get productsCountLabel=> lang == 'ru' ? 'Товары'               : lang == 'en' ? 'Products'             : 'Маҳсулот';
  String get sellersLabel      => lang == 'ru' ? 'Продавцы'             : lang == 'en' ? 'Sellers'              : 'Фурӯшандаҳо';
  String get systemManagement  => lang == 'ru' ? 'Управление системой'   : lang == 'en' ? 'System Management'    : 'Идораи системаи';
  String get manageUsersSub    => lang == 'ru' ? 'Управление и блокировка' : lang == 'en' ? 'Manage and block users' : 'Идораи корбарон ва блок';
  String get manageSellersSub  => lang == 'ru' ? 'Подтверждение и верификация' : lang == 'en' ? 'Approval and verification' : 'Тасдиқ ва верификация';
  String get allOrders         => lang == 'ru' ? 'Все заказы'           : lang == 'en' ? 'All Orders'           : 'Ҳамаи фармоишҳо';
  String get manageOrdersSub   => lang == 'ru' ? 'Управление статусами заказов' : lang == 'en' ? 'Manage order statuses' : 'Идораи статуси фармоишҳо';
  String get manageCategoriesSub => lang == 'ru' ? 'Добавление и редактирование' : lang == 'en' ? 'Add and edit categories' : 'Илова ва таҳрири категорияҳо';
  String get couponsTitle      => lang == 'ru' ? 'Купоны'               : lang == 'en' ? 'Coupons'              : 'Купонҳо';
  String get manageCouponsSub  => lang == 'ru' ? 'Создание и управление купонами' : lang == 'en' ? 'Create and manage coupons' : 'Сохтан ва идораи купонҳо';
  String get walletApproval    => lang == 'ru' ? 'Подтверждение кошелька' : lang == 'en' ? 'Wallet Approval'    : 'Тасдиқи ҳамён';
  String get walletRequestsSub => lang == 'ru' ? 'Запросы на пополнение'  : lang == 'en' ? 'Top-up requests'     : 'Дархостҳои пополнения';
  String get reportsTitle      => lang == 'ru' ? 'Жалобы'               : lang == 'en' ? 'Reports'              : 'Гузоришҳо';
  String get reportsSub        => lang == 'ru' ? 'Жалобы пользователей'   : lang == 'en' ? 'User complaints'      : 'Шикоятҳои корбарон';
  String get returnsExchange   => lang == 'ru' ? 'Возврат/Обмен'        : lang == 'en' ? 'Returns/Exchange'     : 'Бозгашт/Иваз';
  String get returnsSub        => lang == 'ru' ? 'Запросы на возврат'    : lang == 'en' ? 'Return requests'      : 'Дархостҳои бозгашт';

  // ── Users ──
  String get noUsers           => lang == 'ru' ? 'Нет пользователей'     : lang == 'en' ? 'No users'             : 'Корбар нест';
  String get bannedLabel       => lang == 'ru' ? 'Заблокирован'         : lang == 'en' ? 'Banned'               : 'Манъшуда';
  String get passportChip      => lang == 'ru' ? '📄 Паспорт'          : lang == 'en' ? '📄 Passport'          : '📄 Паспорт';
  String get executedDone      => lang == 'ru' ? 'Выполнено ✅'        : lang == 'en' ? 'Done ✅'              : 'Иҷро шуд ✅';
  String get verifySellerAction=> lang == 'ru' ? 'Подтвердить продавца'  : lang == 'en' ? 'Verify seller'        : 'Тасдиқи фурӯшанда';
  String get banUserAction     => lang == 'ru' ? 'Заблокировать'        : lang == 'en' ? 'Ban'                  : 'Манъ кардан';
  String get unbanAction       => lang == 'ru' ? 'Разблокировать'       : lang == 'en' ? 'Unban'                : 'Кушодан';
  String get userPassport      => lang == 'ru' ? 'Паспорт пользователя'  : lang == 'en' ? 'User passport'        : 'Паспорти корбар';

  // ── Orders ──
  String get paymentConfirmed  => lang == 'ru' ? 'Оплата подтверждена'   : lang == 'en' ? 'Payment confirmed'    : 'Пардохт тасдиқ';
  String get statusWord        => lang == 'ru' ? 'Статус'               : lang == 'en' ? 'Status'               : 'Статус';
  String get newStatus         => lang == 'ru' ? 'Новый статус'         : lang == 'en' ? 'New status'           : 'Статуси нав';
  String get statusUpdated     => lang == 'ru' ? 'Статус обновлён ✅'   : lang == 'en' ? 'Status updated ✅'    : 'Статус навсозӣ шуд ✅';

  // ── Categories ──
  String get addWord           => lang == 'ru' ? 'Добавить'             : lang == 'en' ? 'Add'                  : 'Илова';
  String get noCategories      => lang == 'ru' ? 'Нет категорий'        : lang == 'en' ? 'No categories'        : 'Категория нест';
  String get newCategory       => lang == 'ru' ? 'Новая категория'      : lang == 'en' ? 'New category'         : 'Категорияи нав';
  String get categoryNameHint  => lang == 'ru' ? 'Название категории'    : lang == 'en' ? 'Category name'        : 'Номи категория';
  String get cancelShort       => lang == 'ru' ? 'Отмена'               : lang == 'en' ? 'Cancel'               : 'Бекор';
  String get categoryAdded     => lang == 'ru' ? 'Категория добавлена ✅' : lang == 'en' ? 'Category added ✅'    : 'Категория илова шуд ✅';

  // ── Coupons ──
  String get couponFab         => lang == 'ru' ? 'Купон'               : lang == 'en' ? 'Coupon'               : 'Купон';
  String get noCoupons         => lang == 'ru' ? 'Нет купонов'          : lang == 'en' ? 'No coupons'           : 'Купон нест';
  String get discountSuffix    => lang == 'ru' ? 'скидка'               : lang == 'en' ? 'discount'             : 'тахфиф';
  String get usedLabel         => lang == 'ru' ? 'Использовано'         : lang == 'en' ? 'Used'                 : 'Истифода';
  String get unlimitedLabel    => lang == 'ru' ? '(без лимита)'         : lang == 'en' ? '(unlimited)'          : '(бемаҳдуд)';
  String get newCoupon         => lang == 'ru' ? 'Новый купон'          : lang == 'en' ? 'New coupon'           : 'Купони нав';
  String get codeExampleHint   => lang == 'ru' ? 'Код (напр. BAHOR50)'   : lang == 'en' ? 'Code (e.g. BAHOR50)'  : 'Код (мас. BAHOR50)';
  String get discountPercentHint => lang == 'ru' ? 'Скидка (%)'         : lang == 'en' ? 'Discount (%)'         : 'Тахфиф (%)';
  String get usageLimitHint    => lang == 'ru' ? 'Лимит использования (0 = без лимита)' : lang == 'en' ? 'Usage limit (0 = unlimited)' : 'Лимити истифода (0 = бемаҳдуд)';
  String get couponCreated     => lang == 'ru' ? 'Купон создан ✅'      : lang == 'en' ? 'Coupon created ✅'     : 'Купон сохта шуд ✅';
  String get couponDuplicateError => lang == 'ru' ? 'Ошибка (возможно код повторяется)' : lang == 'en' ? 'Error (code may be duplicate)' : 'Хато (шояд код такрорӣ аст)';
  String get createWord        => lang == 'ru' ? 'Создать'              : lang == 'en' ? 'Create'               : 'Сохтан';

  // ── Wallet top-up ──
  String get topUpApproval     => lang == 'ru' ? 'Подтверждение пополнения' : lang == 'en' ? 'Top-up approval'   : 'Тасдиқи пополнения';
  String get noPendingRequests => lang == 'ru' ? 'Нет ожидающих запросов'  : lang == 'en' ? 'No pending requests' : 'Дархости интизор нест';
  String get rejectShort       => lang == 'ru' ? 'Отклонить'            : lang == 'en' ? 'Reject'               : 'Рад';
  String get confirmShort      => lang == 'ru' ? 'Подтвердить'          : lang == 'en' ? 'Confirm'              : 'Тасдиқ';
  String get confirmedDone     => lang == 'ru' ? 'Подтверждено ✅'      : lang == 'en' ? 'Confirmed ✅'         : 'Тасдиқ шуд ✅';
  String get rejectedDone      => lang == 'ru' ? 'Отклонено'            : lang == 'en' ? 'Rejected'             : 'Рад шуд';

  // ── Reports ──
  String get noReports         => lang == 'ru' ? 'Нет жалоб'            : lang == 'en' ? 'No reports'           : 'Гузориш нест';
  String get resolvedLabel     => lang == 'ru' ? 'Решено ✓'            : lang == 'en' ? 'Resolved ✓'          : 'Ҳалшуда ✓';
  String get resolveAction     => lang == 'ru' ? 'Решить'               : lang == 'en' ? 'Resolve'              : 'Ҳал кардан';

  // ── Returns / exchange ──
  String get returnsAndExchange=> lang == 'ru' ? 'Возврат и обмен'      : lang == 'en' ? 'Returns and exchange' : 'Бозгашт ва иваз';
  String get noRequests        => lang == 'ru' ? 'Нет запросов'         : lang == 'en' ? 'No requests'          : 'Дархост нест';
  String get exchangeWord      => lang == 'ru' ? 'Обмен'                : lang == 'en' ? 'Exchange'             : 'Иваз';
  String get refundWord        => lang == 'ru' ? 'Возврат денег'        : lang == 'en' ? 'Refund'               : 'Бозгашти пул';
  String get orderPrefix       => lang == 'ru' ? 'Заказ'                : lang == 'en' ? 'Order'                : 'Фармоиш';
  String get acceptShort       => lang == 'ru' ? 'Принять'              : lang == 'en' ? 'Accept'               : 'Қабул';
  String get completeRefundAction => lang == 'ru' ? 'Завершить (возврат денег)' : lang == 'en' ? 'Complete (refund)' : 'Анҷом (бозгашти пул)';
  String get updatedDone       => lang == 'ru' ? 'Обновлено ✅'         : lang == 'en' ? 'Updated ✅'           : 'Навсозӣ шуд ✅';

  // ── Error screen ──
  String get noConnection      => lang == 'ru' ? 'Нет подключения'      : lang == 'en' ? 'No connection'        : 'Пайвастшавӣ мавҷуд нест';
  String get checkInternet     => lang == 'ru' ? 'Проверьте интернет и попробуйте снова' : lang == 'en' ? 'Check your internet and try again' : 'Интернетро санҷед ва дубора кӯшиш кунед';
  String get tryAgain          => lang == 'ru' ? 'Повторить'            : lang == 'en' ? 'Try again'            : 'Такрор кунед';
}
