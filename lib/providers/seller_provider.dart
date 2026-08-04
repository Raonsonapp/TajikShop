import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../data/models/product_model.dart';
import '../data/models/variant_model.dart';
import '../data/repositories/product_repository.dart';

// ── Вариантҳои маҳсулот ─────────────────────────────────────────────────────
final productVariantsProvider =
    FutureProvider.autoDispose.family<List<VariantModel>, String>((ref, productId) async {
  final res = await ApiClient.instance.dio.get('/products/$productId/variants');
  final raw = res.data;
  final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
  return (list as List).whereType<Map<String, dynamic>>().map(VariantModel.fromJson).toList();
});

// ── Брендҳо ─────────────────────────────────────────────────────────────────
final brandsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get('/brands');
  final raw = res.data;
  final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
  return (list as List).whereType<Map<String, dynamic>>().toList();
});

class VariantService {
  static Future<void> add(String productId,
      {String size = '', String color = '', String sku = '', double price = 0, int stock = 0}) async {
    await ApiClient.instance.dio.post('/products/$productId/variants',
        data: {'size': size, 'color': color, 'sku': sku, 'price': price, 'stock': stock});
  }

  static Future<void> remove(String variantId) async {
    await ApiClient.instance.dio.delete('/variants/$variantId');
  }
}

// ── Маҳсулоти фурӯшанда (GET /products?seller_id=) ──────────────────────────
final sellerProductsProvider =
    FutureProvider.autoDispose.family<List<ProductModel>, String>((ref, sellerId) async {
  if (sellerId.isEmpty) return [];
  return ProductRepository().getProducts(sellerId: sellerId);
});

// ── Фармоишҳои фурӯш (GET /seller/orders) ───────────────────────────────────
final sellerOrdersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ApiClient.instance.dio.get('/seller/orders');
    final raw = res.data;
    final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
    return (list as List).whereType<Map<String, dynamic>>().toList();
  } catch (_) {
    return const [];
  }
});

// ── Графики фурӯши 7 рӯз (GET /seller/sales-chart) ──────────────────────────
final sellerSalesChartProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ApiClient.instance.dio.get('/seller/sales-chart');
    final raw = res.data;
    final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
    return (list as List).whereType<Map<String, dynamic>>().toList();
  } catch (_) {
    return const [];
  }
});

// ── Оморҳои фурӯшанда (GET /seller/stats) ───────────────────────────────────
final sellerStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  const fallback = <String, dynamic>{
    'products': 0,
    'active_products': 0,
    'orders': 0,
    'sold': 0,
    'revenue': 0,
  };
  try {
    final res = await ApiClient.instance.dio.get('/seller/stats');
    final raw = res.data;
    final data = raw is Map
        ? (raw['data'] is Map ? raw['data'] as Map : raw)
        : <String, dynamic>{};
    return {...fallback, ...Map<String, dynamic>.from(data)};
  } catch (_) {
    return fallback;
  }
});

// ── Комиссияи платформа (GET /settings) ─────────────────────────────────────
final platformCommissionProvider = FutureProvider.autoDispose<double>((ref) async {
  try {
    final res = await ApiClient.instance.dio.get('/settings');
    final raw = res.data;
    final data = raw is Map
        ? (raw['data'] is Map ? raw['data'] as Map : raw)
        : <String, dynamic>{};
    final v = data['commission_percent'];
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 10;
  } catch (_) {
    return 10;
  }
});

// ── Cashback платформа (GET /settings) ──────────────────────────────────────
final cashbackProvider = FutureProvider.autoDispose<double>((ref) async {
  try {
    final res = await ApiClient.instance.dio.get('/settings');
    final raw = res.data;
    final data = raw is Map
        ? (raw['data'] is Map ? raw['data'] as Map : raw)
        : <String, dynamic>{};
    final v = data['cashback_percent'];
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 2;
  } catch (_) {
    return 2;
  }
});

// ── Профили оммавии фурӯшанда (GET /users/:id/public) ───────────────────────
final sellerPublicProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final res = await ApiClient.instance.dio.get('/users/$id/public');
  final raw = res.data;
  final data = raw is Map ? (raw['data'] is Map ? raw['data'] as Map : raw) : {};
  return Map<String, dynamic>.from(data);
});

// ── Даъвати дӯстон / Referral (GET /users/me/referral) ──────────────────────
final referralProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  const fallback = <String, dynamic>{
    'code': '',
    'referrals': 0,
    'earned': 0,
    'bonus': 10,
  };
  try {
    final res = await ApiClient.instance.dio.get('/users/me/referral');
    final raw = res.data;
    final data = raw is Map
        ? (raw['data'] is Map ? raw['data'] as Map : raw)
        : <String, dynamic>{};
    return {...fallback, ...Map<String, dynamic>.from(data)};
  } catch (_) {
    return fallback;
  }
});

// ── Купонҳои фаъол (GET /coupons/active) ────────────────────────────────────
final activeCouponsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ApiClient.instance.dio.get('/coupons/active');
    final raw = res.data;
    final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
    return (list as List).whereType<Map<String, dynamic>>().toList();
  } catch (_) {
    return const [];
  }
});

// ── Барномаи вафодорӣ (GET /users/me/loyalty) ───────────────────────────────
final loyaltyProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  const fallback = <String, dynamic>{
    'tier': 'bronze',
    'total_spent': 0,
    'bonus_percent': 0,
    'cashback_percent': 2,
    'next_tier_at': 500,
  };
  try {
    final res = await ApiClient.instance.dio.get('/users/me/loyalty');
    final raw = res.data;
    final data = raw is Map
        ? (raw['data'] is Map ? raw['data'] as Map : raw)
        : <String, dynamic>{};
    return {...fallback, ...Map<String, dynamic>.from(data)};
  } catch (_) {
    return fallback;
  }
});

class SellerProductService {
  static Future<void> update(String id, {
    required String title,
    required String description,
    required double price,
    required int discountPercent,
    required int stock,
    required bool isActive,
    int saleHours = 0, // >0 = flash sale то N соат; <0 = бекор
    int deliveryDays = 0,
    double deliveryPrice = 0,
    String sizeInfo = '',
  }) async {
    await ApiClient.instance.dio.put(ApiEndpoints.product(id), data: {
      'title': title,
      'description': description,
      'price': price,
      'discount_percent': discountPercent,
      'stock': stock,
      'is_active': isActive,
      'sale_hours': saleHours,
      'delivery_days': deliveryDays,
      'delivery_price': deliveryPrice,
      'size_info': sizeInfo,
    });
  }

  static Future<void> delete(String id) async {
    await ApiClient.instance.dio.delete(ApiEndpoints.product(id));
  }
}
