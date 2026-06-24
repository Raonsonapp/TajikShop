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

class AdminService {
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
}
