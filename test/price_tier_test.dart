import 'package:flutter_test/flutter_test.dart';
import 'package:tajikshop/data/models/cart_model.dart';

/// Зинаҳои нархи яклухт дар сабад.
///
/// Нархро СЕРВЕР ҳисоб мекунад (`price_tiers.go`) — барнома онро аз нав
/// ҳисоб намекунад. Маҳз ҳамин муҳим аст: агар барнома ҳисоби худашро
/// медошт, рӯзе ду ҳисоб аз ҳам фарқ мекард ва харидор дар экран як
/// рақам, дар ҳисобнома рақами дигар мебинад.
///
/// Пас ин ҷо ХОНДАНИ ҷавоби сервер санҷида мешавад, на ҳисоб.
void main() {
  Map<String, dynamic> cartJson({
    double price = 90,
    double retail = 100,
    bool wholesale = true,
    int qty = 20,
    List<Map<String, dynamic>>? tiers,
  }) =>
      {
        'id': 'c1',
        'product_id': 'p1',
        'title': 'Моли тестӣ',
        'price': price,
        'retail_price': retail,
        'wholesale': wholesale,
        'quantity': qty,
        'tiers': tiers ??
            [
              {'min_qty': 10, 'price': 90},
              {'min_qty': 50, 'price': 80},
            ],
      };

  test('нархи зина аз сервер хонда мешавад', () {
    final it = CartItemModel.fromJson(cartJson());
    expect(it.price, 90);
    expect(it.retailPrice, 100);
    expect(it.wholesale, isTrue);
    expect(it.total, 1800); // 20 × 90
  });

  test('сарфа ҳисоб мешавад', () {
    final it = CartItemModel.fromJson(cartJson());
    // (100 − 90) × 20 = 200 сом.
    expect(it.saved, 200);
  });

  test('бе зина сарфа нест', () {
    final it = CartItemModel.fromJson(
        cartJson(price: 100, retail: 100, wholesale: false, tiers: []));
    expect(it.saved, 0);
    expect(it.wholesale, isFalse);
    expect(it.tiers, isEmpty);
  });

  // Ин маҳз он чизест, ки фармоиши калонтарро водор мекунад:
  // «боз 30 дона гиред — 80 сом. мешавад».
  test('зинаи навбатӣ ёфт мешавад', () {
    final it = CartItemModel.fromJson(cartJson(qty: 20));
    expect(it.nextTier?.minQty, 50);
    expect(it.nextTier?.price, 80);
  });

  test('дар зинаи охирин зинаи навбатӣ нест', () {
    final it = CartItemModel.fromJson(cartJson(qty: 60));
    expect(it.nextTier, isNull);
  });

  test('зинаи навбатӣ ҳамеша НАЗДИКТАРИН аст', () {
    final it = CartItemModel.fromJson(cartJson(qty: 5, tiers: [
      {'min_qty': 100, 'price': 70},
      {'min_qty': 10, 'price': 90},
      {'min_qty': 50, 'price': 80},
    ]));
    expect(it.nextTier?.minQty, 10,
        reason: 'бояд наздиктарин зина бошад, на аввалин дар рӯйхат');
  });

  // Ҷавоби сервери кӯҳна (бе майдонҳои нав) набояд барномаро шиканад.
  test('ҷавоби кӯҳна бе майдонҳои нав', () {
    final it = CartItemModel.fromJson({
      'id': 'c1',
      'product_id': 'p1',
      'title': 'Кӯҳна',
      'price': 50,
      'quantity': 2,
    });
    expect(it.price, 50);
    expect(it.retailPrice, 50, reason: 'бе `retail_price` бояд ба нарх баробар');
    expect(it.wholesale, isFalse);
    expect(it.tiers, isEmpty);
    expect(it.saved, 0);
    expect(it.nextTier, isNull);
    expect(it.total, 100);
  });

  // Майдонҳои вайрон (null, матн, рақами манфӣ) набояд барномаро шиканад.
  test('майдонҳои вайрон', () {
    final it = CartItemModel.fromJson({
      'id': 'c1',
      'product_id': 'p1',
      'price': null,
      'quantity': null,
      'retail_price': null,
      'tiers': 'ин рӯйхат нест',
    });
    expect(it.price, 0);
    expect(it.quantity, 1);
    expect(it.tiers, isEmpty);
  });
}
