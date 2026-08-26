import '../app_l10n.dart';

/// Тарҷумаҳои экрани профил (tg/ru/en).
///
/// Қаблан бисёр сатрҳои профил бо тоҷикӣ hard-code шуда буданд, бинобар ин
/// ҳангоми иваз кардани забон онҳо тарҷума намешуданд. Ин extension ҳамаи
/// онҳоро ба се забон дастрас мекунад.
extension ProfileL10n on AppL10n {
  // ── Бизнес / мағоза ──
  String get businessMine =>
      lang == 'ru' ? 'Мой бизнес' : lang == 'en' ? 'My Business' : 'Бизнеси ман';
  String get shopNameField =>
      lang == 'ru' ? 'Название магазина' : lang == 'en' ? 'Shop name' : 'Номи мағоза';
  String get businessDescField => lang == 'ru'
      ? 'Описание бизнеса'
      : lang == 'en' ? 'Business description' : 'Тавсифи бизнес';
  String get phoneField =>
      lang == 'ru' ? 'Телефон' : lang == 'en' ? 'Phone' : 'Телефон';
  String get workingHoursField => lang == 'ru'
      ? 'Часы работы (9:00–20:00)'
      : lang == 'en' ? 'Working hours (9:00–20:00)' : 'Соатҳои корӣ (9:00–20:00)';
  String get businessTypeLabel =>
      lang == 'ru' ? 'Тип бизнеса' : lang == 'en' ? 'Business type' : 'Навъи бизнес';

  // ── Даъвати дӯстон / referral ──
  String get inviteFriendsTile => lang == 'ru'
      ? '🎁 Пригласить друзей'
      : lang == 'en' ? '🎁 Invite friends' : '🎁 Дӯстонро даъват кунед';
  String get couponsTile => lang == 'ru'
      ? '🎟 Купоны и промокоды'
      : lang == 'en' ? '🎟 Coupons & promo codes' : '🎟 Купонҳо ва промокодҳо';
  String inviteBonusLine(int bonus) => lang == 'ru'
      ? 'Пригласите — оба получите по $bonus сом.'
      : lang == 'en'
          ? 'Invite — you both get $bonus som.'
          : 'Даъват кунед — ҳарду $bonus сом мегиред';
  String get inviteButton => lang == 'ru'
      ? '🔗 Пригласить'
      : lang == 'en' ? '🔗 Invite' : '🔗 Даъват кардан';
  String inviteShareMsg(String code) => lang == 'ru'
      ? 'Присоединяйся к TajikShop 🛍️!\nПромокод: $code\nhttps://mahmadmurodov-tajikshop.hf.space'
      : lang == 'en'
          ? 'Join TajikShop 🛍️!\nInvite code: $code\nhttps://mahmadmurodov-tajikshop.hf.space'
          : 'Ба TajikShop 🛍️ ҳамроҳ шав!\nКоди даъват: $code\nhttps://mahmadmurodov-tajikshop.hf.space';
  String get copiedDone =>
      lang == 'ru' ? 'Скопировано ✅' : lang == 'en' ? 'Copied ✅' : 'Нусхабардорӣ шуд ✅';
  String referralsCount(int n) =>
      lang == 'ru' ? '$n друзей' : lang == 'en' ? '$n friends' : '$n дӯст';
  String earnedSom(String amount) => lang == 'ru'
      ? 'заработано $amount сом.'
      : lang == 'en' ? 'earned $amount som.' : '$amount сом кофтед';

  // ── Купонҳо ──
  String get activeCoupons =>
      lang == 'ru' ? 'Активные купоны' : lang == 'en' ? 'Active coupons' : 'Купонҳои фаъол';
  String get couponHint => lang == 'ru'
      ? 'Введите код в корзине при оплате'
      : lang == 'en' ? 'Enter the code at checkout' : 'Кодро дар сабад ҳангоми пардохт ворид кунед';
  String get noCouponsYet => lang == 'ru'
      ? 'Пока нет активных купонов'
      : lang == 'en' ? 'No active coupons yet' : 'Ҳоло купони фаъол нест';

  // ── Ҳуқуқӣ ва ҳисоб ──
  String get legalAndAccount => lang == 'ru'
      ? 'Правовое и аккаунт'
      : lang == 'en' ? 'Legal & account' : 'Ҳуқуқӣ ва ҳисоб';
  String get privacyPolicy => lang == 'ru'
      ? 'Политика конфиденциальности'
      : lang == 'en' ? 'Privacy Policy' : 'Сиёсати махфият';
  String get termsOfUse => lang == 'ru'
      ? 'Условия использования'
      : lang == 'en' ? 'Terms of Use' : 'Шартҳои истифода';

  // ── Ҳазфи ҳисоб ──
  String get deleteAccountTitle =>
      lang == 'ru' ? 'Удаление аккаунта' : lang == 'en' ? 'Delete account' : 'Ҳазфи ҳисоб';
  String get deleteAccountBody => lang == 'ru'
      ? 'Ваш аккаунт и личные данные (имя, телефон, почта, адреса, корзина, '
          'избранное, сообщения, отзывы, объявления и фото) будут удалены.\n\n'
          'Записи заказов и платежей хранятся анонимно по требованию закона.\n\n'
          'Это действие необратимо. Продолжить?'
      : lang == 'en'
          ? 'Your account and personal data (name, phone, email, addresses, cart, '
              'favorites, messages, reviews, listings and photos) will be deleted.\n\n'
              'Order and payment records are kept anonymized as required by law.\n\n'
              'This action is irreversible. Continue?'
          : 'Ҳисоб ва маълумоти шахсии шумо (ном, телефон, почта, суроғаҳо, сабад, '
              'дӯстдоштаҳо, паёмҳо, шарҳҳо, эълонҳо ва расмҳо) ҳазф мешавад.\n\n'
              'Сабтҳои фармоиш ва пардохт барои қонунгузорӣ беном (anonymized) нигоҳ дошта мешаванд.\n\n'
              'Ин амал бебозгашт аст. Идома медиҳед?';
  String get deleteAccountConfirm => lang == 'ru'
      ? 'Да, удалить' : lang == 'en' ? 'Yes, delete' : 'Ҳа, ҳазф кун';
  String get accountDeleted => lang == 'ru'
      ? 'Ваш аккаунт удалён' : lang == 'en' ? 'Your account was deleted' : 'Ҳисоби шумо ҳазф шуд';
  String get deleteAccountError => lang == 'ru'
      ? 'Ошибка при удалении. Попробуйте снова.'
      : lang == 'en' ? 'Delete failed. Please try again.' : 'Хатогӣ ҳангоми ҳазф. Дубора кӯшиш кунед.';

  // ── Loyalty ──
  String tierLevel(String label) =>
      lang == 'ru' ? 'Уровень $label' : lang == 'en' ? 'Tier $label' : 'Сатҳи $label';
  String cashbackPerPurchase(String pct) => lang == 'ru'
      ? 'Кэшбэк: $pct% с каждой покупки'
      : lang == 'en' ? 'Cashback: $pct% on every purchase' : 'Cashback: $pct% аз ҳар харид';
  String toNextTier(String amount) => lang == 'ru'
      ? 'До следующего уровня: потратьте $amount сом.'
      : lang == 'en' ? 'To next tier: spend $amount som.' : 'То сатҳи баъдӣ: $amount сом харид кунед';
  String get topTierMax => lang == 'ru'
      ? 'Высший уровень — максимальный кэшбэк!'
      : lang == 'en' ? 'Top tier — maximum cashback!' : 'Сатҳи болоӣ — cashback-и максималӣ!';
}

/// Тарҷумаҳои қисми расонидан/пардохт (checkout).
extension CheckoutL10n on AppL10n {
  String get deliveryMethod => lang == 'ru'
      ? 'Способ доставки' : lang == 'en' ? 'Delivery method' : 'Тарзи расонидан';
  String get deliveryOption => lang == 'ru'
      ? 'Доставка' : lang == 'en' ? 'Delivery' : 'Расонидан';
  String get pickupOption => lang == 'ru'
      ? 'Забрать из магазина' : lang == 'en' ? 'Pick up from store' : 'Аз мағоза гирифтан';
  String get deliveryTime => lang == 'ru'
      ? 'Время доставки' : lang == 'en' ? 'Delivery time' : 'Вақти расонидан';
  String get asSoonAsPossible => lang == 'ru'
      ? 'Как можно скорее' : lang == 'en' ? 'As soon as possible' : 'Ҳарчи зудтар';
  String get specificTime => lang == 'ru'
      ? 'Определённое время' : lang == 'en' ? 'Specific time' : 'Вақти муайян';
  String get pickupFree => lang == 'ru'
      ? 'Бесплатно — заберите сами'
      : lang == 'en' ? 'Free — collect it yourself' : 'Ройгон — худатон мегиред';
  String get pickupNoAddress => lang == 'ru'
      ? 'Адрес не нужен — заберёте из магазина продавца'
      : lang == 'en' ? 'No address needed — collect from the seller\'s store'
      : 'Суроға лозим нест — аз мағозаи фурӯшанда мегиред';
}
