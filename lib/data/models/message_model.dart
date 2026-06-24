class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id']?.toString() ?? '',
        senderId: json['sender_id']?.toString() ?? '',
        receiverId: json['receiver_id']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        isRead: json['is_read'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
            : DateTime.now(),
      );
}
