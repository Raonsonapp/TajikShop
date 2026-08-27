class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;

  /// ID-и объекте, ки огоҳӣ ба он тааллуқ дорад (фармоиш, маҳсулот, корбар).
  /// Бе ин зеркунии огоҳӣ ҳеҷ ҷо намебарад.
  final String refId;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.refId = '',
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      type: json['type'] ?? 'general',
      isRead: json['is_read'] ?? false,
      refId: json['ref_id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
