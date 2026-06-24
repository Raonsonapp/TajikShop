import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../data/models/review_model.dart';
import '../data/models/product_model.dart';
import '../data/repositories/product_repository.dart';

// ── Шарҳҳои маҳсулот (GET /reviews/product/:id) ──────────────────────────────
final productReviewsProvider =
    FutureProvider.autoDispose.family<List<ReviewModel>, String>((ref, productId) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.productReviews(productId));
  final raw = res.data;
  final list = raw is List
      ? raw
      : (raw is Map ? (raw['data'] ?? raw['reviews'] ?? []) : []);
  return (list as List)
      .whereType<Map<String, dynamic>>()
      .map((e) => ReviewModel.fromJson({...e, 'product_id': productId}))
      .toList();
});

// ── Маҳсулоти монанд (ҳамон категория) ──────────────────────────────────────
final similarProductsProvider =
    FutureProvider.autoDispose.family<List<ProductModel>, String>((ref, categoryId) async {
  if (categoryId.isEmpty) return [];
  final list = await ProductRepository().getProducts(categoryId: categoryId);
  return list;
});

// ── Фиристодани шарҳ (POST /reviews) ─────────────────────────────────────────
class ReviewService {
  static Future<void> submit({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    await ApiClient.instance.dio.post(ApiEndpoints.reviews, data: {
      'product_id': productId,
      'rating': rating,
      'comment': comment,
    });
  }
}
