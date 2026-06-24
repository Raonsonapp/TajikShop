import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

class ReportService {
  static Future<void> send({
    required String targetType, // product | user
    required String targetId,
    required String reason,
  }) async {
    await ApiClient.instance.dio.post('/reports', data: {
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
    });
  }
}

// Admin: рӯйхати гузоришҳо
final adminReportsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get('/admin/reports');
  final raw = res.data;
  final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
  return (list as List).whereType<Map<String, dynamic>>().toList();
});
