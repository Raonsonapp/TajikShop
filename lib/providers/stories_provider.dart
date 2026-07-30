import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../data/models/story_model.dart';

const String _kMediaHost = 'https://mahmadmurodov-tajikshop.hf.space';

/// Ҳикояҳои кашф (discover) — аз ҳамаи фурӯшандагон, гурӯҳбандишуда аз рӯи корбар.
/// GET /stories/discover. Ҳангоми хатогӣ рӯйхати холӣ то UI вайрон нашавад.
final storiesProvider =
    FutureProvider.autoDispose<List<StoryUser>>((ref) async {
  try {
    final res = await ApiClient.instance.dio.get(ApiEndpoints.storiesDiscover);
    final raw = res.data;
    final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
    final maps = (list as List).whereType<Map<String, dynamic>>().toList();

    // Гурӯҳбандӣ аз рӯи user_id бо нигоҳ доштани тартиб
    final order = <String>[];
    final byUser = <String, List<StoryModel>>{};
    final names = <String, String>{};
    final avatars = <String, String>{};
    for (final m in maps) {
      final uid = m['user_id']?.toString() ?? '';
      if (uid.isEmpty) continue;
      if (!byUser.containsKey(uid)) {
        order.add(uid);
        byUser[uid] = [];
        names[uid] = m['user_name']?.toString() ?? 'Дӯкон';
        final av = m['avatar_url']?.toString() ?? '';
        avatars[uid] = av.isEmpty || av.startsWith('http') ? av : '$_kMediaHost$av';
      }
      byUser[uid]!.add(StoryModel.fromJson(m));
    }
    return order
        .map((uid) => StoryUser(
              userId: uid,
              userName: names[uid] ?? 'Дӯкон',
              avatarUrl: avatars[uid] ?? '',
              stories: byUser[uid]!,
            ))
        .toList();
  } catch (_) {
    return const [];
  }
});

/// Хидмати ҳикоя — бор кардани ҳикояи нав (фақат фурӯшандагон).
class StoryService {
  static Future<void> upload(MultipartFile media) async {
    final form = FormData();
    form.files.add(MapEntry('media', media));
    await ApiClient.instance.dio.post(ApiEndpoints.createStory, data: form);
  }
}
