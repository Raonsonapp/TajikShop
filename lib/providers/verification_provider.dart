import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

Map<String, dynamic> _unwrapMap(dynamic raw) {
  if (raw is Map && raw['data'] is Map) {
    return Map<String, dynamic>.from(raw['data'] as Map);
  }
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return {};
}

List<Map<String, dynamic>> _unwrapList(dynamic raw) {
  final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
  if (list is! List) return const [];
  return list.whereType<Map<String, dynamic>>().toList();
}

/// Ҳолати галочкаи корбари ҷорӣ.
/// GET /users/me/verification → {is_verified, price, card, card_holder, request?}
final myVerificationProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final res = await ApiClient.instance.dio.get('/users/me/verification');
    return _unwrapMap(res.data);
  } catch (_) {
    // Бе интернет ҳам экран бояд нархро нишон диҳад, на хатогии холӣ.
    return {'is_verified': false};
  }
});

/// Дархостҳои интизори галочка (админ).
final verificationRequestsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, status) async {
  try {
    final res = await ApiClient.instance.dio
        .get('/admin/verification-requests', queryParameters: {'status': status});
    return _unwrapList(res.data);
  } catch (_) {
    return const [];
  }
});

/// Баҳои миёнаи фурӯшанда (1–10) + шарҳҳои охирин.
/// GET /users/:id/rating → {average, count, reviews:[…]}
final sellerRatingProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, sellerId) async {
  if (sellerId.isEmpty) return {'average': 0, 'count': 0};
  try {
    final res = await ApiClient.instance.dio.get('/users/$sellerId/rating');
    return _unwrapMap(res.data);
  } catch (_) {
    return {'average': 0, 'count': 0};
  }
});
