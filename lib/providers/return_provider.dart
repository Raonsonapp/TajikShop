import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

class ReturnService {
  static Future<void> request(String orderId, {required String type, required String reason}) async {
    await ApiClient.instance.dio.post('/orders/$orderId/return',
        data: {'type': type, 'reason': reason});
  }

  static Future<void> adminUpdate(String returnId, String status) async {
    await ApiClient.instance.dio.post('/admin/returns/$returnId/status', data: {'status': status});
  }
}

// Дархости бозгашти ин фармоиш (ё null)
final orderReturnProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, orderId) async {
  final res = await ApiClient.instance.dio.get('/orders/$orderId/return');
  final raw = res.data;
  final data = raw is Map ? raw['data'] : null;
  return data is Map ? Map<String, dynamic>.from(data) : null;
});

// Admin: рӯйхати дархостҳои бозгашт
final adminReturnsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get('/admin/returns');
  final raw = res.data;
  final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
  return (list as List).whereType<Map<String, dynamic>>().toList();
});
