const String _kMediaHost = 'https://mahmadmurodov-tajikshop.hf.space';

String _fullUrl(String path) =>
    path.startsWith('http') ? path : '$_kMediaHost$path';

/// Як ҳикоя (story) — расм ё видеои муваққатии як фурӯшанда.
class StoryModel {
  final String id;
  final String userId;
  final String mediaUrl;
  final String mediaType; // 'image' | 'video'
  final DateTime? createdAt;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    this.createdAt,
  });

  bool get isVideo => mediaType == 'video';

  factory StoryModel.fromJson(Map<String, dynamic> j) => StoryModel(
        id: j['id']?.toString() ?? '',
        userId: j['user_id']?.toString() ?? '',
        mediaUrl: _fullUrl(j['media_url']?.toString() ?? ''),
        mediaType: j['media_type']?.toString() ?? 'image',
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
      );
}

/// Ҳикояҳои як корбар (гурӯҳбандишуда барои rail-и доиравӣ).
class StoryUser {
  final String userId;
  final String userName;
  final String avatarUrl;
  final List<StoryModel> stories;

  const StoryUser({
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.stories,
  });
}
