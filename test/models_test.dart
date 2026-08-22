import 'package:flutter_test/flutter_test.dart';
import 'package:tajikshop/data/models/product_model.dart';
import 'package:tajikshop/data/models/user_model.dart';

void main() {
  group('ProductModel.fromJson', () {
    test('parses core fields and sensible defaults', () {
      final p = ProductModel.fromJson({
        'id': 'p1',
        'title': 'Кроссовка',
        'price': 250,
        'seller_id': 's1',
      });
      expect(p.id, 'p1');
      expect(p.title, 'Кроссовка');
      expect(p.price, 250);
      expect(p.inStock, isTrue); // stock unknown → assumed available
      expect(p.deliveryDays, 0);
      expect(p.sizeInfo, '');
    });

    test('computes oldPrice from discount', () {
      final p = ProductModel.fromJson({
        'id': 'p2',
        'title': 'X',
        'price': 80,
        'discount_percent': 20,
      });
      expect(p.discountPercent, 20);
      expect(p.oldPrice, isNotNull);
      expect(p.oldPrice! > p.price, isTrue);
    });
  });

  group('UserModel.fromJson', () {
    test('defaults businessType to shop and seller flags', () {
      final u = UserModel.fromJson({'id': 'u1', 'email': 'a@b.co'});
      expect(u.id, 'u1');
      expect(u.businessType, 'shop');
      expect(u.isSeller, isFalse);
    });

    test('seller role implies isSeller', () {
      final u = UserModel.fromJson({'id': 'u2', 'role': 'seller'});
      expect(u.isSeller, isTrue);
    });
  });
}
