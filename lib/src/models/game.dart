part of '../../main.dart';

class Game {
  final String name, sub, logoText, domain;
  final Color color;
  final List<String> packs;
  const Game(this.name, this.sub, this.logoText, this.color, this.packs, this.domain);
}

const games = [
  Game('Free Fire', 'Алмос • Ваучер • Membership', 'FF', Color(0xFFFFA52B), ['110 алмаз','341 алмаз','572 алмаз','1166 алмаз','2398 алмаз','6160 алмаз','Ваучер Lite 90 алмаз','Ваучери ҳафтагӣ 450 алмаз','Ваучери моҳона 2600 алмаз','Level Up Package 6','Level Up Package 10','Level Up Package 15','Level Up Package 20','Level Up Package 25','Level Up Package 30'], 'ff.garena.com'),
  Game('PUBG Mobile', 'UC • Royale Pass', 'PUBG', Color(0xFFFFD15C), ['60 UC','325 UC','660 UC','1800 UC','3850 UC','8100 UC','First Purchase Pack','Prime (1 Month)','Weekly Deal Pack 1','60 WOW Coins','Upgradable Firearm Materials Pack','Prime (3 Months)','Weekly Mythic Emblem Value Pack','Weekly Deal Pack 2','Mythic Emblem Pack','325 WOW Coins','Prime (6 Months)','Elite Pass LV1-50','Prime Plus (1 Month)','660 WOW Coins','Prime (12 Months)','Elite Pass LV1-100','1800 WOW Coins','Elite Pass Plus LV1-100','Prime Plus (3 Months)','3850 WOW Coins','Prime Plus (6 Months)','8100 WOW Coins','Prime Plus (12 Months)'], 'pubgmobile.com'),
  Game('Mobile Legends', 'Diamonds • Pass', 'MLBB', Color(0xFF5B9BFF), ['Нархнома дастрас нест'], 'mobilelegends.com'),
  Game('Standoff 2', 'Gold • Бастаҳо', 'S2', Color(0xFFE34B55), ['Нархнома дастрас нест'], 'standoff2.com'),
  Game('Telegram', 'Premium • Stars', 'TG', Color(0xFF36AEEA), ['Telegram Premium','Stars'], 'telegram.org'),
  Game('IMO', 'Coins • хизматрасонӣ', 'imo', Color(0xFF2D9BEA), ['Нархнома дастрас нест'], 'imo.im'),
];

const Map<String, String> almazCatalogPrices = {
  '110 алмаз':'8.71 с','341 алмаз':'26.95 с','572 алмаз':'40.70 с','1166 алмаз':'81.58 с','2398 алмаз':'155.90 с','6160 алмаз':'449.00 с',
  'Ваучер Lite 90 алмаз':'4.44 с','Ваучери ҳафтагӣ 450 алмаз':'15.95 с','Ваучери моҳона 2600 алмаз':'59.90 с',
  'Level Up Package 6':'5.95 с','Level Up Package 10':'8.92 с','Level Up Package 15':'8.92 с','Level Up Package 20':'8.92 с','Level Up Package 25':'8.92 с','Level Up Package 30':'10.90 с',
  '60 UC':'9.71 с','325 UC':'45.45 с','660 UC':'90.64 с','1800 UC':'223.55 с','3850 UC':'424.23 с','8100 UC':'872.20 с',
  'First Purchase Pack':'10.90 с','Prime (1 Month)':'10.90 с','Weekly Deal Pack 1':'10.90 с','60 WOW Coins':'11.40 с','Upgradable Firearm Materials Pack':'30.21 с','Prime (3 Months)':'30.21 с','Weekly Mythic Emblem Value Pack':'30.21 с','Weekly Deal Pack 2':'30.21 с','Mythic Emblem Pack':'49.02 с','325 WOW Coins':'51.99 с','Prime (6 Months)':'58.92 с','Elite Pass LV1-50':'58.92 с','Prime Plus (1 Month)':'97.03 с','660 WOW Coins':'102.97 с','Prime (12 Months)':'116.34 с','Elite Pass LV1-100':'118.81 с','1800 WOW Coins':'256.42 с','Elite Pass Plus LV1-100':'289.09 с','Prime Plus (3 Months)':'289.59 с','3850 WOW Coins':'511.35 с','Prime Plus (6 Months)':'577.68 с','8100 WOW Coins':'1021.69 с','Prime Plus (12 Months)':'1153.86 с',
};

const String _almazAssetsBase = String.fromEnvironment('ALMAZ_ASSETS_BASE_URL', defaultValue: '');
