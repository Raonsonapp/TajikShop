import 'package:flutter/widgets.dart';
import '../app_l10n.dart';

/// Extra localization strings for remaining hardcoded UI text.
/// Reuses existing AppL10n base keys where one already fits; these are the
/// leftover strings that had no matching base key.
extension ExtraL10n on AppL10n {
  // ── Countdown / misc ──
  String get ended =>
      lang == 'ru' ? 'Завершено' : lang == 'en' ? 'Ended' : 'Тамом шуд';

  // ── Splash ──
  String get marketplaceTagline => lang == 'ru'
      ? 'Рынок Таджикистана'
      : lang == 'en'
          ? 'Marketplace of Tajikistan'
          : 'Бозори Тоҷикистон';

  // ── Favorites ──
  String get goSearch =>
      lang == 'ru' ? 'К поиску' : lang == 'en' ? 'To search' : 'Ба ҷустуҷӯ';

  // ── Admin: seller requests ──
  String get sellerRequestsTitle => lang == 'ru'
      ? 'Заявки продавцов'
      : lang == 'en'
          ? 'Seller requests'
          : 'Дархостҳои фурӯшанда';
  String get noNewRequests => lang == 'ru'
      ? 'Нет новых заявок'
      : lang == 'en'
          ? 'No new requests'
          : 'Дархости нав нест';
  String get viewPassport => lang == 'ru'
      ? 'Посмотреть паспорт'
      : lang == 'en'
          ? 'View passport'
          : 'Дидани шиноснома';
  String get rejectAction =>
      lang == 'ru' ? 'Отклонить' : lang == 'en' ? 'Reject' : 'Рад кардан';
  String get approveAction =>
      lang == 'ru' ? 'Подтвердить' : lang == 'en' ? 'Approve' : 'Тасдиқ';
  String get sellerApproved => lang == 'ru'
      ? 'Продавец подтверждён'
      : lang == 'en'
          ? 'Seller approved'
          : 'Фурӯшанда тасдиқ шуд';
  String get requestRejected => lang == 'ru'
      ? 'Заявка отклонена'
      : lang == 'en'
          ? 'Request rejected'
          : 'Дархост рад шуд';
  String get passportTitle =>
      lang == 'ru' ? 'Паспорт' : lang == 'en' ? 'Passport' : 'Шиноснома';

  // ── Upload: discount field ──
  String get discountPercentLabel =>
      lang == 'ru' ? 'Скидка (%)' : lang == 'en' ? 'Discount (%)' : 'Тахфиф (%)';
  String get discountOptionalHint => lang == 'ru'
      ? 'Необязательно — процент скидки на этот товар'
      : lang == 'en'
          ? 'Optional — discount percent for this product'
          : 'Ихтиёрӣ — фоизи тахфиф барои ин маҳсулот';
}
