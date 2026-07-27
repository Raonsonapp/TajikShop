import 'package:flutter/widgets.dart';
import '../app_l10n.dart';

/// Additional localization strings for auth / upload / favorites / chat
/// screens. Kept in an extension to avoid touching the base [AppL10n] class.
extension MiscL10n on AppL10n {
  // ── Login screen ──
  String get loginWelcomeTitle => lang == 'ru'
      ? 'Добро пожаловать 👋'
      : lang == 'en'
          ? 'Welcome 👋'
          : 'Хуш омадед 👋';
  String get loginWelcomeSubtitle => lang == 'ru'
      ? 'Войдите в свой аккаунт\nи продолжите покупки'
      : lang == 'en'
          ? 'Sign in to your account\nand continue shopping'
          : 'Ба ҳисоби худ ворид шавед\nва хариди худро идома диҳед';
  String get loginPrompt => lang == 'ru'
      ? 'Введите email и пароль для продолжения'
      : lang == 'en'
          ? 'Enter email and password to continue'
          : 'Барои идома email ва паролро ворид кунед';
  String get enterEmailPassword => lang == 'ru'
      ? 'Введите email и пароль'
      : lang == 'en'
          ? 'Enter email and password'
          : 'Email ва паролро ворид кунед';
  String get noAccountPrefix => lang == 'ru'
      ? 'Нет аккаунта? '
      : lang == 'en'
          ? "Don't have an account? "
          : 'Ҳисоб надоред? ';

  // ── Register screen ──
  String get registerWelcomeTitle => lang == 'ru'
      ? 'Создайте аккаунт 🚀'
      : lang == 'en'
          ? 'Create account 🚀'
          : 'Ҳисоб созед 🚀';
  String get registerWelcomeSubtitle => lang == 'ru'
      ? 'Добро пожаловать на рынок Таджикистана —\nсоздайте аккаунт за минуту'
      : lang == 'en'
          ? 'Welcome to the marketplace of Tajikistan —\ncreate an account in a minute'
          : 'Ба бозори Тоҷикистон хуш омадед —\nдар як дақиқа ҳисоб созед';
  String get registerPrompt => lang == 'ru'
      ? 'Введите свои данные для создания аккаунта'
      : lang == 'en'
          ? 'Enter your details to create an account'
          : 'Маълумоти худро барои сохтани ҳисоб ворид кунед';
  String get usernameHint => lang == 'ru'
      ? 'Имя пользователя'
      : lang == 'en'
          ? 'Username'
          : 'Номи корбар';
  String get usernameRule => lang == 'ru'
      ? 'Только строчные буквы, цифры и _'
      : lang == 'en'
          ? 'Only lowercase letters, numbers and _'
          : 'Танҳо ҳарфҳои хурд, рақам ва _';
  String get passwordMin6Hint => lang == 'ru'
      ? 'Пароль (минимум 6)'
      : lang == 'en'
          ? 'Password (min 6)'
          : 'Парол (ҳадди ақал 6)';
  String get fillAllFields => lang == 'ru'
      ? 'Заполните все поля'
      : lang == 'en'
          ? 'Fill in all fields'
          : 'Ҳамаи майдонҳоро пур кунед';
  String get passwordMin6Error => lang == 'ru'
      ? 'Пароль минимум 6 символов'
      : lang == 'en'
          ? 'Password at least 6 characters'
          : 'Парол ҳадди ақал 6 аломат';
  String get haveAccountPrefix => lang == 'ru'
      ? 'Уже есть аккаунт? '
      : lang == 'en'
          ? 'Already have an account? '
          : 'Ҳисоб доред? ';

  // ── Phone auth screen ──
  String get smsVerification => lang == 'ru'
      ? 'SMS верификация'
      : lang == 'en'
          ? 'SMS Verification'
          : 'SMS верификация';
  String get smsComingSoon => lang == 'ru'
      ? 'Эта функция скоро появится.\nСейчас войдите через Email.'
      : lang == 'en'
          ? 'This feature is coming soon.\nFor now, sign in with Email.'
          : 'Ин функсия тез фаъол мешавад.\nҲозир бо Email ворид шавед.';

  // ── Upload screen ──
  String get currencySomoni => lang == 'ru'
      ? 'сомони'
      : lang == 'en'
          ? 'somoni'
          : 'сомонӣ';
  String get conditionNew => lang == 'ru'
      ? 'Новый'
      : lang == 'en'
          ? 'New'
          : 'Нав';
  String get conditionGood => lang == 'ru'
      ? 'Хорошее'
      : lang == 'en'
          ? 'Good'
          : 'Хуб';
  String get conditionAcceptable => lang == 'ru'
      ? 'Приемлемое'
      : lang == 'en'
          ? 'Acceptable'
          : 'Қабулшуда';
  String get conditionOld => lang == 'ru'
      ? 'Старое'
      : lang == 'en'
          ? 'Old'
          : 'Кӯҳна';

  // ── Chat screen ──
  String get messageNotSent => lang == 'ru'
      ? 'Сообщение не отправлено'
      : lang == 'en'
          ? 'Message not sent'
          : 'Паём фиристода нашуд';
  String get messagesLoadFailed => lang == 'ru'
      ? 'Не удалось загрузить сообщения'
      : lang == 'en'
          ? 'Failed to load messages'
          : 'Паёмҳо бор нашуд';
  String get noMessagesYet => lang == 'ru'
      ? 'Пока нет сообщений.\nНапишите первым!'
      : lang == 'en'
          ? 'No messages yet.\nBe the first to write!'
          : 'Ҳоло паёме нест.\nАввалин шуда паём нависед!';
  String get writeMessageHint => lang == 'ru'
      ? 'Напишите сообщение...'
      : lang == 'en'
          ? 'Write a message...'
          : 'Паём нависед...';
}
