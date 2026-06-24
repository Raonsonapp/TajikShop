import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

// Маҷмӯи id-и корбароне, ки ман пайгирӣ мекунам (optimistic, дар сессия).
// Backend дар DB сабт мекунад; ин ҳолати UI барои тугмаи Follow аст.
class FollowNotifier extends StateNotifier<Set<String>> {
  FollowNotifier() : super({});

  Future<void> toggle(String userId) async {
    final following = state.contains(userId);
    // Optimistic
    if (following) {
      state = {...state}..remove(userId);
    } else {
      state = {...state, userId};
    }
    try {
      if (following) {
        await ApiClient.instance.dio.delete(ApiEndpoints.follow(userId));
      } else {
        await ApiClient.instance.dio.post(ApiEndpoints.follow(userId));
      }
    } catch (_) {
      // Rollback
      if (following) {
        state = {...state, userId};
      } else {
        state = {...state}..remove(userId);
      }
    }
  }
}

final followProvider =
    StateNotifierProvider<FollowNotifier, Set<String>>((ref) => FollowNotifier());
