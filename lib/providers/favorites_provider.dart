import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _load();
  }

  Dio get _dio => ApiClient.instance.dio;

  Future<void> _load() async {
    try {
      final res = await _dio.get(ApiEndpoints.favorites);
      final raw = res.data;
      // Backend wraps payloads as {success, data: [...]}; favorites `data` is a list.
      final inner = raw is Map ? raw['data'] : raw;
      final list = inner is List
          ? inner
          : (inner is Map
              ? (inner['favorites'] as List? ?? inner['items'] as List? ?? [])
              : []);
      final ids = list.map((e) {
        final m = e as Map<String, dynamic>;
        return (m['product_id'] ?? m['id'])?.toString() ?? '';
      }).where((s) => s.isNotEmpty).toSet();
      state = ids;
    } catch (_) {}
  }

  Future<void> toggle(String productId) async {
    final wasFav = state.contains(productId);
    // Optimistic update
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
      // Rollback
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
