import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../models/cart_model.dart';
import '../../models/order_model.dart';

class OrderRemote {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<CartItemModel>> getCart() async {
    final res = await _dio.get(ApiEndpoints.cart);
    final raw = res.data;
    // Backend wraps payload in {success, data:[...]}; fall back to legacy keys.
    final body = raw is List
        ? raw
        : (raw is Map ? (raw['data'] ?? raw['items'] ?? raw['cart'] ?? []) : []);
    final items = body is List ? body : const [];
    return items
        .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
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
    final raw = res.data;
    // Backend wraps payload in {success, data:[...]}; fall back to legacy keys.
    final body = raw is List
        ? raw
        : (raw is Map ? (raw['data'] ?? raw['orders'] ?? []) : []);
    final items = body is List ? body : const [];
    return items
        .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
