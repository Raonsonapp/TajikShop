import '../datasources/remote/order_remote.dart';
import '../models/cart_model.dart';
import '../models/order_model.dart';

class CartRepository {
  final OrderRemote _remote = OrderRemote();

  Future<List<CartItemModel>> getCart() => _remote.getCart();
  Future<void> addToCart(String productId, int quantity) =>
      _remote.addToCart(productId, quantity);
  Future<void> removeFromCart(String itemId) => _remote.removeFromCart(itemId);
  Future<List<OrderModel>> getOrders() => _remote.getOrders();
  Future<void> checkout(String addressId) => _remote.checkout(addressId);
}
