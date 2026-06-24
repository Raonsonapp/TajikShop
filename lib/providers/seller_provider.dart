import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../data/models/product_model.dart';
import '../data/repositories/product_repository.dart';

// ── Маҳсулоти фурӯшанда (GET /products?seller_id=) ──────────────────────────
final sellerProductsProvider =
    FutureProvider.autoDispose.family<List<ProductModel>, String>((ref, sellerId) async {
  if (sellerId.isEmpty) return [];
  return ProductRepository().getProducts(sellerId: sellerId);
});

// ── Профили оммавии фурӯшанда (GET /users/:id/public) ───────────────────────
final sellerPublicProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final res = await ApiClient.instance.dio.get('/users/$id/public');
  final raw = res.data;
  final data = raw is Map ? (raw['data'] is Map ? raw['data'] as Map : raw) : {};
  return Map<String, dynamic>.from(data);
});

class SellerProductService {
  static Future<void> update(String id, {
    required String title,
    required String description,
    required double price,
    required int discountPercent,
    required int stock,
    required bool isActive,
  }) async {
    await ApiClient.instance.dio.put(ApiEndpoints.product(id), data: {
      'title': title,
      'description': description,
      'price': price,
      'discount_percent': discountPercent,
      'stock': stock,
      'is_active': isActive,
    });
  }

  static Future<void> delete(String id) async {
    await ApiClient.instance.dio.delete(ApiEndpoints.product(id));
  }
}
