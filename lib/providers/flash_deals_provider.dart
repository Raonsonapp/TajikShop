import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product_model.dart';
import '../data/repositories/product_repository.dart';

/// Тахфифҳои барқӣ (Flash Deals) — маҳсулоти тахфифдор бо мӯҳлати маҳдуд.
/// GET /products/flash. Ҳангоми хатогӣ рӯйхати холӣ то UI вайрон нашавад.
final flashDealsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  try {
    return await ProductRepository().getFlashDeals();
  } catch (_) {
    return const [];
  }
});

/// Ҳамаи маҳсулоти тахфифдор (GET /products/deals) — барои саҳифаи «Тахфифҳо».
final dealsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  try {
    return await ProductRepository().getDeals();
  } catch (_) {
    return const [];
  }
});
