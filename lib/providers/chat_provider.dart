import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../data/models/message_model.dart';

// ── Сӯҳбат бо корбар (GET /messages/:user_id) ───────────────────────────────
final conversationProvider =
    FutureProvider.autoDispose.family<List<MessageModel>, String>((ref, userId) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.conversation(userId));
  final raw = res.data;
  final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
  return (list as List)
      .whereType<Map<String, dynamic>>()
      .map(MessageModel.fromJson)
      .toList();
});

// ── Рӯйхати сӯҳбатҳо / Inbox (GET /messages) ────────────────────────────────
final inboxProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ApiClient.instance.dio.get(ApiEndpoints.messages);
    final raw = res.data;
    final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
    return (list as List).whereType<Map<String, dynamic>>().toList();
  } catch (_) {
    return const [];
  }
});

// ── Фиристодани паём (POST /messages) ────────────────────────────────────────
class ChatService {
  static Future<void> send(String receiverId, String content) async {
    await ApiClient.instance.dio.post(ApiEndpoints.messages,
        data: {'receiver_id': receiverId, 'content': content});
  }
}
