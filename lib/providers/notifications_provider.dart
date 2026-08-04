import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

/// Шумораи огоҳиномаҳои хонданашуда (барои нишони зангӯла).
/// GET /notifications → шумориши is_read=false. Ҳангоми хатогӣ 0.
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final res = await ApiClient.instance.dio.get('/notifications');
    final raw = res.data;
    final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
    return (list as List)
        .whereType<Map>()
        .where((n) => n['is_read'] != true)
        .length;
  } catch (_) {
    return 0;
  }
});
