class ReviewModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String productId;
  final int rating;
  final String comment;
  final List<String> images;
  final int helpfulCount;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.productId,
    required this.rating,
    required this.comment,
    this.images = const [],
    this.helpfulCount = 0,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] ?? json['full_name'],
      userAvatar: json['user_avatar'] ?? json['avatar'],
      productId: json['product_id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] ?? '',
      images: (json['images'] is List)
          ? (json['images'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
      helpfulCount: (json['helpful_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
