import '../app_l10n.dart';

/// Галочкаи тасдиқ + рейтинги фурӯшанда (tg/ru/en).
extension VerificationL10n on AppL10n {
  // ── Галочка ──
  String get verifyTile => lang == 'ru'
      ? 'Синяя галочка'
      : lang == 'en'
          ? 'Verified badge'
          : 'Галочкаи тасдиқ';
  String get verifyTitle => lang == 'ru'
      ? 'Галочка подтверждения'
      : lang == 'en'
          ? 'Verification badge'
          : 'Галочкаи тасдиқ';
  String get verifySubtitle => lang == 'ru'
      ? 'Зелёная галочка рядом с вашим именем — покупатели доверяют больше'
      : lang == 'en'
          ? 'A green badge next to your name — buyers trust you more'
          : 'Галочкаи сабз дар паҳлӯи номи шумо — харидорон бештар бовар мекунанд';

  String get verifyBenefit1 => lang == 'ru'
      ? 'Галочка в профиле и на каждом товаре'
      : lang == 'en'
          ? 'Badge in your profile and on every product'
          : 'Галочка дар профил ва дар ҳар маҳсулот';
  String get verifyBenefit2 => lang == 'ru'
      ? 'Выше в поиске и в списке магазинов'
      : lang == 'en'
          ? 'Higher in search and in the shop list'
          : 'Дар ҷустуҷӯ ва рӯйхати мағозаҳо болотар';
  String get verifyBenefit3 => lang == 'ru'
      ? 'Знак того, что вы настоящий продавец'
      : lang == 'en'
          ? 'Proof that you are a real seller'
          : 'Нишони он, ки шумо фурӯшандаи ҳақиқӣ ҳастед';

  String get verifyPriceLabel => lang == 'ru'
      ? 'Стоимость'
      : lang == 'en'
          ? 'Price'
          : 'Нарх';
  String get verifyCardLabel => lang == 'ru'
      ? 'Переведите на карту'
      : lang == 'en'
          ? 'Transfer to card'
          : 'Ба ин корт гузаронед';
  String get verifyCopyCard => lang == 'ru'
      ? 'Скопировать номер'
      : lang == 'en'
          ? 'Copy number'
          : 'Нусхабардорӣ';
  String get verifyCardCopied => lang == 'ru'
      ? 'Номер карты скопирован'
      : lang == 'en'
          ? 'Card number copied'
          : 'Рақами корт нусха шуд';

  String get verifyStep1 => lang == 'ru'
      ? 'Переведите сумму на карту выше'
      : lang == 'en'
          ? 'Transfer the amount to the card above'
          : 'Маблағро ба корти боло гузаронед';
  String get verifyStep2 => lang == 'ru'
      ? 'Прикрепите фото чека'
      : lang == 'en'
          ? 'Attach a photo of the receipt'
          : 'Расми чекро замима кунед';
  String get verifyStep3 => lang == 'ru'
      ? 'Мы проверим и включим галочку'
      : lang == 'en'
          ? 'We check it and turn the badge on'
          : 'Мо месанҷем ва галочкаро фаъол мекунем';

  String get verifyAttachReceipt => lang == 'ru'
      ? 'Фото чека'
      : lang == 'en'
          ? 'Receipt photo'
          : 'Расми чек';
  String get verifyChangePhoto => lang == 'ru'
      ? 'Заменить фото'
      : lang == 'en'
          ? 'Change photo'
          : 'Расмро иваз кунед';
  String get verifySend => lang == 'ru'
      ? 'Отправить на проверку'
      : lang == 'en'
          ? 'Send for review'
          : 'Ба санҷиш фиристодан';
  String get verifyNeedReceipt => lang == 'ru'
      ? 'Сначала прикрепите фото чека'
      : lang == 'en'
          ? 'Attach the receipt photo first'
          : 'Аввал расми чекро замима кунед';
  String get verifySent => lang == 'ru'
      ? 'Заявка отправлена'
      : lang == 'en'
          ? 'Request sent'
          : 'Дархост фиристода шуд';
  String get verifyFailed => lang == 'ru'
      ? 'Не удалось отправить. Попробуйте ещё раз.'
      : lang == 'en'
          ? 'Could not send. Try again.'
          : 'Фиристода нашуд. Дубора кӯшиш кунед.';

  String get verifyPending => lang == 'ru'
      ? 'Заявка на проверке'
      : lang == 'en'
          ? 'Request under review'
          : 'Дархост дар санҷиш аст';
  String get verifyPendingHint => lang == 'ru'
      ? 'Обычно занимает несколько часов. Мы пришлём уведомление.'
      : lang == 'en'
          ? 'Usually takes a few hours. We will send a notification.'
          : 'Одатан якчанд соат мегирад. Мо огоҳӣ мефиристем.';
  String get verifyRejected => lang == 'ru'
      ? 'Заявка отклонена'
      : lang == 'en'
          ? 'Request rejected'
          : 'Дархост рад шуд';
  String get verifyRetry => lang == 'ru'
      ? 'Отправить заново'
      : lang == 'en'
          ? 'Send again'
          : 'Аз нав фиристодан';
  String get verifyApproved => lang == 'ru'
      ? 'Ваш профиль подтверждён'
      : lang == 'en'
          ? 'Your profile is verified'
          : 'Профили шумо тасдиқ шудааст';
  String get verifyApprovedHint => lang == 'ru'
      ? 'Зелёная галочка видна всем покупателям.'
      : lang == 'en'
          ? 'The green badge is visible to every buyer.'
          : 'Галочкаи сабзро ҳамаи харидорон мебинанд.';

  // ── Админ ──
  String get verifyAdminTitle => lang == 'ru'
      ? 'Заявки на галочку'
      : lang == 'en'
          ? 'Badge requests'
          : 'Дархостҳои галочка';
  String get verifyAdminEmpty => lang == 'ru'
      ? 'Новых заявок нет'
      : lang == 'en'
          ? 'No new requests'
          : 'Дархости нав нест';
  String get verifyApprove => lang == 'ru'
      ? 'Одобрить'
      : lang == 'en'
          ? 'Approve'
          : 'Тасдиқ';
  String get verifyReject => lang == 'ru'
      ? 'Отклонить'
      : lang == 'en'
          ? 'Reject'
          : 'Рад кардан';
  String get verifyRejectReason => lang == 'ru'
      ? 'Причина отказа'
      : lang == 'en'
          ? 'Reason for rejection'
          : 'Сабаби рад';

  // ── Рейтинги фурӯшанда ──
  String get ratingTitle => lang == 'ru'
      ? 'Мой рейтинг'
      : lang == 'en'
          ? 'My rating'
          : 'Рейтинги ман';
  String get ratingNone => lang == 'ru'
      ? 'Оценок пока нет'
      : lang == 'en'
          ? 'No ratings yet'
          : 'Ҳанӯз баҳо нест';
  String get ratingNoneHint => lang == 'ru'
      ? 'Покупатели оценят вас от 1 до 10 после доставки'
      : lang == 'en'
          ? 'Buyers rate you from 1 to 10 after delivery'
          : 'Харидорон пас аз расонидан аз 1 то 10 баҳо медиҳанд';
  String ratingCount(int n) => lang == 'ru'
      ? '$n оценок'
      : lang == 'en'
          ? '$n ratings'
          : '$n баҳо';
  String get ratingReviews => lang == 'ru'
      ? 'Отзывы'
      : lang == 'en'
          ? 'Reviews'
          : 'Шарҳҳо';
  String get ratingOutOf10 => lang == 'ru'
      ? 'из 10'
      : lang == 'en'
          ? 'out of 10'
          : 'аз 10';
}
