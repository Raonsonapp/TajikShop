import 'package:flutter/widgets.dart';
import '../app_l10n.dart';

/// Localization keys for Orders / Wallet / Address / Notifications screens.
/// Extends [AppL10n] so existing keys (orders, total, save, cancel, som, …)
/// stay reusable while these screen-specific strings live here.
extension OrdersL10n on AppL10n {
  // ── Order detail ──────────────────────────────────────────────────────────
  String get orderTitle => lang == 'ru' ? 'Заказ' : lang == 'en' ? 'Order' : 'Фармоиш';
  String get stepAccepted => lang == 'ru' ? 'Принят' : lang == 'en' ? 'Accepted' : 'Қабул шуд';
  String get stepPaymentConfirmed => lang == 'ru' ? 'Оплата подтверждена' : lang == 'en' ? 'Payment confirmed' : 'Пардохт тасдиқ';
  String get stepProcessingStage => lang == 'ru' ? 'В обработке' : lang == 'en' ? 'Processing' : 'Дар коркард';
  String get stepShippedStage => lang == 'ru' ? 'Отправлен' : lang == 'en' ? 'Shipped' : 'Фиристода шуд';
  String get stepDeliveredStage => lang == 'ru' ? 'Доставлен' : lang == 'en' ? 'Delivered' : 'Расонида шуд';
  String get cancelQuestion => lang == 'ru' ? 'Отменить?' : lang == 'en' ? 'Cancel?' : 'Бекор кардан?';
  String get cancelOrderConfirmBody => lang == 'ru'
      ? 'Отменить заказ? Если оплачено с кошелька, деньги вернутся.'
      : lang == 'en'
          ? 'Cancel the order? If paid from wallet, the money will be refunded.'
          : 'Фармоиш бекор карда шавад? Агар бо ҳамён пардохт шуда бошад, пул бармегардад.';
  String get noWord => lang == 'ru' ? 'Нет' : lang == 'en' ? 'No' : 'Не';
  String get yesCancel => lang == 'ru' ? 'Да, отменить' : lang == 'en' ? 'Yes, cancel' : 'Бале, бекор кун';
  String get cancelledRefunded => lang == 'ru'
      ? 'Отменён — деньги возвращены на кошелёк ✅'
      : lang == 'en'
          ? 'Cancelled — money refunded to wallet ✅'
          : 'Бекор шуд — пул ба ҳамён баргашт ✅';
  String get orderCancelledMsg => lang == 'ru' ? 'Заказ отменён' : lang == 'en' ? 'Order cancelled' : 'Фармоиш бекор шуд';
  String get cancelFailed => lang == 'ru' ? 'Не удалось отменить' : lang == 'en' ? 'Could not cancel' : 'Бекор кардан мумкин нашуд';
  String get confirmReceiptQuestion => lang == 'ru'
      ? 'Подтвердить получение товара?'
      : lang == 'en'
          ? 'Confirm you received the item?'
          : 'Расидани молро тасдиқ мекунед?';
  String get confirmReceiptBody => lang == 'ru'
      ? 'Подтверждайте только когда получили товар. После подтверждения деньги переводятся продавцу.'
      : lang == 'en'
          ? 'Confirm only when you have received the item. After confirmation the money is released to the seller.'
          : 'Танҳо вақте молро гирифтед тасдиқ кунед. Баъд аз тасдиқ, маблағ ба фурӯшанда дода мешавад.';
  String get notNow => lang == 'ru' ? 'Не сейчас' : lang == 'en' ? 'Not now' : 'Ҳоло не';
  String get yesReceived => lang == 'ru' ? 'Да, получил' : lang == 'en' ? 'Yes, received' : 'Бале, гирифтам';
  String get thanksOrderCompleted => lang == 'ru'
      ? 'Спасибо! Заказ завершён ✅'
      : lang == 'en'
          ? 'Thank you! Order completed ✅'
          : 'Раҳмат! Фармоиш анҷом ёфт ✅';
  String get exchangeWord => lang == 'ru' ? 'Обмен' : lang == 'en' ? 'Exchange' : 'Иваз';
  String get returnWord => lang == 'ru' ? 'Возврат' : lang == 'en' ? 'Return' : 'Бозгашт';
  String get retStatusPending => lang == 'ru' ? 'в ожидании' : lang == 'en' ? 'pending' : 'дар интизор';
  String get retStatusApproved => lang == 'ru' ? 'принято' : lang == 'en' ? 'approved' : 'қабул шуд';
  String get retStatusRejected => lang == 'ru' ? 'отклонено' : lang == 'en' ? 'rejected' : 'рад шуд';
  String get retStatusCompleted => lang == 'ru' ? 'завершено' : lang == 'en' ? 'completed' : 'анҷом ёфт';
  String get returnOrExchange => lang == 'ru' ? 'Возврат или обмен' : lang == 'en' ? 'Return or exchange' : 'Бозгашт ё иваз кардан';
  String get returnExchangeTitle => lang == 'ru' ? 'Возврат / Обмен' : lang == 'en' ? 'Return / Exchange' : 'Бозгашт / Иваз';
  String get refundMoney => lang == 'ru' ? 'Возврат денег' : lang == 'en' ? 'Refund' : 'Бозгашти пул';
  String get exchangeAction => lang == 'ru' ? 'Обменять' : lang == 'en' ? 'Exchange' : 'Иваз кардан';
  String get writeReasonHint => lang == 'ru' ? 'Напишите причину...' : lang == 'en' ? 'Write the reason...' : 'Сабабро нависед...';
  String get sendRequest => lang == 'ru' ? 'Отправить запрос' : lang == 'en' ? 'Send request' : 'Фиристодани дархост';
  String get requestSent => lang == 'ru' ? 'Запрос отправлен ✅' : lang == 'en' ? 'Request sent ✅' : 'Дархост фиристода шуд ✅';
  String get deliveryStatus => lang == 'ru' ? 'Статус доставки' : lang == 'en' ? 'Delivery status' : 'Ҳолати расонидан';
  String get orderWasCancelled => lang == 'ru' ? 'Заказ отменён' : lang == 'en' ? 'Order was cancelled' : 'Фармоиш бекор карда шуд';
  String get paymentReceipt => lang == 'ru' ? 'Чек оплаты' : lang == 'en' ? 'Payment receipt' : 'Чеки пардохт';
  String get orderTotalLabel => lang == 'ru' ? 'Сумма заказа' : lang == 'en' ? 'Order total' : 'Ҷамъи фармоиш';
  String get noteWord => lang == 'ru' ? 'Примечание' : lang == 'en' ? 'Note' : 'Эзоҳ';
  String get orderCompletedNote => lang == 'ru'
      ? 'Заказ завершён, деньги переведены продавцу.'
      : lang == 'en'
          ? 'Order completed and money released to the seller.'
          : 'Фармоиш анҷом ёфт ва маблағ ба фурӯшанда дода шуд.';
  String get escrowProtection => lang == 'ru'
      ? 'Защита: ваши деньги удерживаются до подтверждения получения товара.'
      : lang == 'en'
          ? 'Protection: your money is held until you confirm receipt of the item.'
          : 'Ҳимоя: пули шумо то тасдиқи расидани мол нигоҳ дошта мешавад.';
  String get confirmReceiptButton => lang == 'ru'
      ? 'Подтверждаю получение товара'
      : lang == 'en'
          ? 'I confirm receipt of the item'
          : 'Расидани молро тасдиқ мекунам';
  String get cancelOrderButton => lang == 'ru' ? 'Отменить заказ' : lang == 'en' ? 'Cancel order' : 'Фармоишро бекор кардан';

  // ── Wallet ────────────────────────────────────────────────────────────────
  String get topUpAction => lang == 'ru' ? 'Пополнить' : lang == 'en' ? 'Top up' : 'Пополнение кардан';
  String get transactionHistory => lang == 'ru' ? 'История операций' : lang == 'en' ? 'Transaction history' : 'Таърихи амалиётҳо';
  String get noTransactions => lang == 'ru' ? 'Пока нет операций' : lang == 'en' ? 'No transactions yet' : 'Ҳоло амалиёте нест';
  String get walletCardTag => lang == 'ru' ? 'TajikShop • Кошелёк' : lang == 'en' ? 'TajikShop • Wallet' : 'TajikShop • Ҳамён';
  String get txTopup => lang == 'ru' ? 'Пополнение' : lang == 'en' ? 'Top-up' : 'Пополнение';
  String get txPurchase => lang == 'ru' ? 'Покупка' : lang == 'en' ? 'Purchase' : 'Харид';
  String get txRefund => lang == 'ru' ? 'Возврат' : lang == 'en' ? 'Refund' : 'Бозгашт';
  String get txPending => lang == 'ru' ? 'Ожидание' : lang == 'en' ? 'Pending' : 'Интизор';
  String get txCompleted => lang == 'ru' ? 'Выполнено' : lang == 'en' ? 'Completed' : 'Иҷрошуда';
  String get txRejected => lang == 'ru' ? 'Отклонено' : lang == 'en' ? 'Rejected' : 'Радшуда';
  String get topUpTitle => lang == 'ru' ? 'Пополнение' : lang == 'en' ? 'Top-up' : 'Пополнение';
  String get topUpHintText => lang == 'ru'
      ? 'Введите сумму. После подтверждения админом она добавится в кошелёк.'
      : lang == 'en'
          ? 'Enter the amount. It is added to your wallet after admin approval.'
          : 'Маблағро ворид кунед. Баъди тасдиқи админ ба ҳамён илова мешавад.';
  String get amountSomHint => lang == 'ru' ? 'Сумма (сом.)' : lang == 'en' ? 'Amount (som.)' : 'Маблағ (сом.)';
  String get topUpRequestSent => lang == 'ru'
      ? 'Запрос отправлен. Ожидайте подтверждения админа.'
      : lang == 'en'
          ? 'Request sent. Awaiting admin approval.'
          : 'Дархост фиристода шуд. Интизори тасдиқи админ.';

  // ── Addresses ─────────────────────────────────────────────────────────────
  String get noAddresses => lang == 'ru' ? 'Нет адресов' : lang == 'en' ? 'No addresses' : 'Суроға нест';
  String get addNewAddressHint => lang == 'ru' ? 'Добавьте новый адрес' : lang == 'en' ? 'Add a new address' : 'Суроғаи навро илова кунед';
  String get defaultBadge => lang == 'ru' ? 'По умолчанию' : lang == 'en' ? 'Default' : 'Пешфарз';
  String get setDefaultAction => lang == 'ru' ? 'Сделать основным' : lang == 'en' ? 'Set as default' : 'Пешфарз кардан';
  String get deleteAction => lang == 'ru' ? 'Удалить' : lang == 'en' ? 'Delete' : 'Нест кардан';

  // ── Add address sheet ─────────────────────────────────────────────────────
  String get fillCityStreet => lang == 'ru' ? 'Заполните город и улицу' : lang == 'en' ? 'Fill in city and street' : 'Шаҳр ва кӯчаро пур кунед';
  String get addressSaveFailed => lang == 'ru' ? 'Адрес не сохранён' : lang == 'en' ? 'Address not saved' : 'Суроға захира нашуд';
  String get newAddress => lang == 'ru' ? 'Новый адрес' : lang == 'en' ? 'New address' : 'Суроғаи нав';
  String get addressNameLabel => lang == 'ru' ? 'Название адреса' : lang == 'en' ? 'Address name' : 'Номи суроға';
  String get addressNameHint => lang == 'ru' ? 'Дом, Работа, Офис...' : lang == 'en' ? 'Home, Work, Office...' : 'Хона, Кор, Офис...';
  String get cityHint => lang == 'ru' ? 'Город *' : lang == 'en' ? 'City *' : 'Шаҳр *';
  String get fullAddressLabel => lang == 'ru' ? 'Полный адрес' : lang == 'en' ? 'Full address' : 'Суроғаи пурра';
  String get streetHint => lang == 'ru' ? 'Улица, дом, квартира *' : lang == 'en' ? 'Street, house, apartment *' : 'Кӯча, хона, манзил *';
  String get indexLabel => lang == 'ru' ? 'Индекс' : lang == 'en' ? 'Postal code' : 'Индекс';
  String get indexHint => lang == 'ru' ? 'Индекс (необязательно)' : lang == 'en' ? 'Postal code (optional)' : 'Индекс (ихтиёрӣ)';
  String get locationOnMap => lang == 'ru' ? 'Расположение на карте' : lang == 'en' ? 'Location on map' : 'Ҷойгиршавӣ дар харита';
  String get locationPicked => lang == 'ru' ? 'Место выбрано' : lang == 'en' ? 'Location picked' : 'Ҷой интихоб шуд';
  String get pickLocationOnMap => lang == 'ru' ? 'Выберите место на карте' : lang == 'en' ? 'Pick a location on the map' : 'Ҷойро дар харита интихоб кунед';

  // ── Map picker ────────────────────────────────────────────────────────────
  String get gpsOff => lang == 'ru' ? 'GPS выключен' : lang == 'en' ? 'GPS is off' : 'GPS хомӯш аст';
  String get locationPermissionDenied => lang == 'ru' ? 'Доступ к геолокации не разрешён' : lang == 'en' ? 'Location permission denied' : 'Иҷозати ҷойгиршавӣ дода нашуд';
  String get pickStoreLocationTitle => lang == 'ru' ? 'Выберите место магазина' : lang == 'en' ? 'Pick the store location' : 'Ҷойи мағозаро интихоб кунед';
  String get findingYourLocation => lang == 'ru' ? 'Определяем ваше местоположение…' : lang == 'en' ? 'Finding your location…' : 'Ҷойгиршавии шумо ёфта мешавад…';
  String get moveMapHint => lang == 'ru'
      ? 'Двигайте карту, чтобы маркер указывал на ваш магазин'
      : lang == 'en'
          ? 'Move the map so the marker points to your store'
          : 'Харитаро ҳаракат диҳед, то маркер ба мағозаи шумо ишора кунад';
  String get pickThisLocation => lang == 'ru' ? 'Выбрать это место' : lang == 'en' ? 'Pick this location' : 'Ин ҷойро интихоб мекунам';
}
