import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../data/models/story_model.dart';

// ── Feed-и stories (GET /stories/feed) ──────────────────────────────────────
final storiesFeedProvider = FutureProvider.autoDispose<List<StoryModel>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.stories);
  final raw = res.data;
  final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
  return (list as List)
      .whereType<Map<String, dynamic>>()
      .map(StoryModel.fromJson)
      .toList();
});

class StoryService {
  // POST /stories — media файл (multipart 'media')
  static Future<void> create(String filePath) async {
    final form = FormData.fromMap({
      'media': await MultipartFile.fromFile(filePath, filename: 'story.jpg'),
    });
    await ApiClient.instance.dio.post(ApiEndpoints.createStory, data: form);
  }
}
