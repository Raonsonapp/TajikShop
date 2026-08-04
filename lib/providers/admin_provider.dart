import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

List<Map<String, dynamic>> _unwrapList(dynamic raw) {
  final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['users'] ?? raw['orders'] ?? []) : []);
  return (list as List).whereType<Map<String, dynamic>>().toList();
}

// ── Корбарон (GET /admin/users) ─────────────────────────────────────────────
final adminUsersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get('/admin/users');
  return _unwrapList(res.data);
});

// ── Фармоишҳо (GET /admin/orders) ───────────────────────────────────────────
final adminOrdersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get('/admin/orders');
  return _unwrapList(res.data);
});

// ── Купонҳо (GET /admin/coupons) ────────────────────────────────────────────
final adminCouponsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get('/admin/coupons');
  return _unwrapList(res.data);
});

// ── Дархостҳои пополненияи интизор (GET /admin/wallet/pending) ───────────────
final adminWalletPendingProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get('/admin/wallet/pending');
  return _unwrapList(res.data);
});

// ── Дархостҳои фурӯшанда (GET /admin/seller-requests) ────────────────────────
final adminSellerRequestsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get('/admin/seller-requests');
  return _unwrapList(res.data);
});

// ── Карго (GET /admin/cargo) ────────────────────────────────────────────────
final adminCargoProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get('/admin/cargo');
  return _unwrapList(res.data);
});

class AdminService {
  static Future<void> updateCargo(String id,
          {String? trackCode, double? weight, String? status, String? note}) =>
      ApiClient.instance.dio.patch('/admin/cargo/$id', data: {
        if (trackCode != null) 'track_code': trackCode,
        if (weight != null) 'weight': weight,
        if (status != null) 'status': status,
        if (note != null) 'note': note,
      });
  static Future<void> updateCargoSettings(
          {required String warehouse,
          required double rateTj,
          required double rateRu,
          required String phone}) =>
      ApiClient.instance.dio.post('/admin/cargo/settings', data: {
        'warehouse': warehouse,
        'rate_tj': rateTj,
        'rate_ru': rateRu,
        'phone': phone,
      });

  static Future<void> banUser(String id) =>
      ApiClient.instance.dio.post('/admin/users/$id/ban');
  static Future<void> unbanUser(String id) =>
      ApiClient.instance.dio.post('/admin/users/$id/unban');
  static Future<void> verifySeller(String id) =>
      ApiClient.instance.dio.post('/admin/users/$id/verify-seller');
  static Future<void> updateOrderStatus(String id, String status) =>
      ApiClient.instance.dio.patch('/admin/orders/$id/status', data: {'status': status});
  static Future<void> deleteProduct(String id) =>
      ApiClient.instance.dio.delete('/admin/products/$id');
  static Future<void> createCategory(String name, String slug) =>
      ApiClient.instance.dio.post('/admin/categories', data: {'name': name, 'slug': slug});
  static Future<void> createCoupon(String code, int discountPercent, int maxUses) =>
      ApiClient.instance.dio.post('/admin/coupons',
          data: {'code': code, 'discount_percent': discountPercent, 'max_uses': maxUses});
  static Future<void> approveWalletTx(String id) =>
      ApiClient.instance.dio.post('/admin/wallet/tx/$id/approve');
  static Future<void> rejectWalletTx(String id) =>
      ApiClient.instance.dio.post('/admin/wallet/tx/$id/reject');
}
