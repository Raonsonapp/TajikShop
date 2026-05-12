import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _load();
  }

  Dio get _dio => ApiClient.instance.dio;

  Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw['data'] as Map<String, dynamic>? ?? raw;
    return {};
  }

  Future<void> _load() async {
    try {
      final res = await _dio.get(ApiEndpoints.favorites);
      final data = _unwrap(res.data);
      final list = data['favorites'] as List? ?? data['items'] as List? ?? (res.data is List ? res.data as List : []);
      final ids = list.map((e) {
        final m = e as Map<String, dynamic>;
        return (m['product_id'] ?? m['id'])?.toString() ?? '';
      }).where((s) => s.isNotEmpty).toSet();
      state = ids;
    } catch (_) {}
  }

  Future<void> toggle(String productId) async {
    final wasFav = state.contains(productId);
    if (wasFav) {
      final next = Set<String>.from(state);
      next.remove(productId);
      state = next;
    } else {
      state = Set<String>.from(state)..add(productId);
    }
    try {
      if (wasFav) {
        await _dio.delete('${ApiEndpoints.favorites}/$productId');
      } else {
        await _dio.post(ApiEndpoints.favorites, data: {'product_id': productId});
      }
    } catch (_) {
      if (wasFav) {
        state = Set<String>.from(state)..add(productId);
      } else {
        final next = Set<String>.from(state);
        next.remove(productId);
        state = next;
      }
    }
  }

  Future<void> reload() => _load();
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
    (ref) => FavoritesNotifier());
