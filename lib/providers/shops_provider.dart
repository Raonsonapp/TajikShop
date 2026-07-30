import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

/// Рӯйхати дӯконҳо (бизнесҳои маҳаллӣ) барои харитаи «Дӯконҳои наздик».
/// GET /shops (оммавӣ) → {success, data:[{id,name,avatar_url,shop_desc,
/// store_lat,store_lng,is_verified,products}]}. Ҳангоми хатогӣ рӯйхати холӣ.
final shopsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ApiClient.instance.dio.get('/shops');
    final raw = res.data;
    final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
    return (list as List).whereType<Map<String, dynamic>>().toList();
  } catch (_) {
    return const [];
  }
});
