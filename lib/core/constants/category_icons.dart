import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/widgets.dart';

/// Барои ҳар категория аз рӯи ном як нишонаи Feather мувофиқ бармегардонад.
/// Ин боэътимодтар аз расмҳои шабакавӣ аст (баъзе хостҳо дар ТҶ баста'анд) ва
/// ба брендинги Feather-only мувофиқ аст.
IconData categoryIcon(String? name) {
  final n = (name ?? '').toLowerCase();

  bool has(List<String> keys) => keys.any(n.contains);

  // Техника / электроника
  if (has(['электрон', 'техник', 'смартфон', 'телефон', 'phone', 'electronic',
      'gadget', 'компьютер', 'ноутбук', 'laptop'])) {
    return FeatherIcons.smartphone;
  }
  // Либос / мода
  if (has(['одежд', 'либос', 'пӯшок', 'пушок', 'кийм', 'cloth', 'fashion',
      'мода', 'футболк'])) {
    return FeatherIcons.tag;
  }
  // Пойафзол
  if (has(['обувь', 'пойафзол', 'shoe', 'кроссовк'])) {
    return FeatherIcons.shoppingBag;
  }
  // Хона / мебел
  if (has(['дом', 'хона', 'мебел', 'home', 'furnitur', 'интерьер'])) {
    return FeatherIcons.home;
  }
  // Зебоӣ / косметика
  if (has(['красот', 'зебо', 'beauty', 'космет', 'парфюм', 'салон'])) {
    return FeatherIcons.scissors;
  }
  // Варзиш
  if (has(['спорт', 'варзиш', 'sport', 'фитнес', 'fitness'])) {
    return FeatherIcons.activity;
  }
  // Ғизо / озуқаворӣ
  if (has(['еда', 'ғизо', 'гизо', 'озуқ', 'озук', 'food', 'grocery',
      'продукт', 'нӯшок', 'нушок'])) {
    return FeatherIcons.shoppingCart;
  }
  // Тарабхона / кафе
  if (has(['ресторан', 'тарабхона', 'кафе', 'cafe', 'restaurant'])) {
    return FeatherIcons.coffee;
  }
  // Кӯдакон / бозича
  if (has(['детс', 'дети', 'бача', 'кӯдак', 'кудак', 'kid', 'child', 'toy',
      'бозича', 'игрушк'])) {
    return FeatherIcons.gift;
  }
  // Авто / нақлиёт
  if (has(['авто', 'мошин', 'car', 'auto', 'нақлиёт', 'транспорт'])) {
    return FeatherIcons.truck;
  }
  // Боғ / рӯзгор
  if (has(['сад', 'боғ', 'бог', 'garden', 'дача', 'рӯзгор', 'рузгор'])) {
    return FeatherIcons.sun;
  }
  // Китоб
  if (has(['книг', 'китоб', 'book', 'канцеляр'])) {
    return FeatherIcons.book;
  }
  // Саломатӣ / дорухона
  if (has(['здоров', 'саломат', 'health', 'аптек', 'дору', 'дорухона',
      'pharmac', 'медиц'])) {
    return FeatherIcons.plusCircle;
  }
  // Зевар / ҷавоҳирот
  if (has(['ювелир', 'украшен', 'jewelr', 'зевар', 'ҷавоҳир', 'часы', 'соат'])) {
    return FeatherIcons.star;
  }
  // Асбоб / таъмир
  if (has(['инструмент', 'асбоб', 'tool', 'таъмир', 'ремонт', 'строит',
      'сохтмон'])) {
    return FeatherIcons.tool;
  }
  // Кимётон / бренд
  if (has(['музык', 'мусиқ', 'music'])) {
    return FeatherIcons.music;
  }
  // Пешфарз
  return FeatherIcons.grid;
}
