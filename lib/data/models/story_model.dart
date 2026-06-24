class StoryModel {
  final String id;
  final String userId;
  final String mediaUrl;
  final String mediaType;
  final String userName;
  final String? avatarUrl;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    required this.userName,
    this.avatarUrl,
  });

  bool get isVideo => mediaType == 'video';

  static String _abs(String s) =>
      s.isEmpty || s.startsWith('http') ? s : 'https://mahmadmurodov-tajikshop.hf.space$s';

  factory StoryModel.fromJson(Map<String, dynamic> j) => StoryModel(
        id: j['id']?.toString() ?? '',
        userId: j['user_id']?.toString() ?? '',
        mediaUrl: _abs(j['media_url']?.toString() ?? ''),
        mediaType: j['media_type']?.toString() ?? 'image',
        userName: j['user_name']?.toString() ?? j['name']?.toString() ?? 'Корбар',
        avatarUrl: () {
          final a = j['avatar_url']?.toString() ?? j['avatar']?.toString();
          return (a == null || a.isEmpty) ? null : _abs(a);
        }(),
      );
}
