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

// ── Q&A (савол-ҷавоб) дар маҳсулот ───────────────────────────────────────────
final productQuestionsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, productId) async {
  final res = await ApiClient.instance.dio.get('/products/$productId/questions');
  final raw = res.data;
  final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
  return (list as List).whereType<Map<String, dynamic>>().toList();
});

// ── Фиристодани шарҳ + овоз + Q&A ────────────────────────────────────────────
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

  // Овози «фоиданок» → шумораи навро бармегардонад
  static Future<int> toggleHelpful(String reviewId) async {
    final res = await ApiClient.instance.dio.post('/reviews/$reviewId/helpful');
    final raw = res.data;
    final data = raw is Map ? (raw['data'] is Map ? raw['data'] as Map : raw) : {};
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  static Future<void> ask(String productId, String question) async {
    await ApiClient.instance.dio.post('/products/$productId/questions', data: {'question': question});
  }

  static Future<void> answer(String questionId, String answer) async {
    await ApiClient.instance.dio.post('/questions/$questionId/answer', data: {'answer': answer});
  }
}
