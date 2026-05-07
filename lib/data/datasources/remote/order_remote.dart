import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../models/cart_model.dart';
import '../../models/order_model.dart';

class OrderRemote {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<CartItemModel>> getCart() async {
    final res = await _dio.get(ApiEndpoints.cart);
    final data = res.data;
    List items = data is List ? data : (data['items'] ?? data['cart'] ?? []);
    return items.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addToCart(String productId, int quantity) async {
    await _dio.post(ApiEndpoints.cart, data: {
      'product_id': productId,
      'quantity': quantity,
    });
  }

  Future<void> removeFromCart(String itemId) async {
    await _dio.delete(ApiEndpoints.cartItem(itemId));
  }

  Future<List<OrderModel>> getOrders() async {
    final res = await _dio.get(ApiEndpoints.orders);
    final data = res.data;
    List items = data is List ? data : (data['orders'] ?? []);
    return items.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> checkout(String addressId) async {
    await _dio.post(ApiEndpoints.checkout, data: {
      if (addressId.isNotEmpty) 'address_id': addressId,
    });
  }
}
