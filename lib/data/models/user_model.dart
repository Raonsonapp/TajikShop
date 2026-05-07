class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatar;
  final String? phone;
  final String role;
  final bool isSeller;
  final bool isVerified;
  final bool isBanned;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatar,
    this.phone,
    required this.role,
    required this.isSeller,
    required this.isVerified,
    this.isBanned = false,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      // backend uses 'name', fallback to 'full_name'
      fullName: json['name'] ?? json['full_name'] ?? json['username'] ?? 'Корбар',
      avatar: json['avatar_url'] ?? json['avatar'],
      phone: json['phone'],
      role: json['role'] ?? 'buyer',
      isSeller: json['is_seller'] ?? false,
      isVerified: json['is_verified'] ?? false,
      isBanned: json['is_banned'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': fullName,
    'avatar_url': avatar,
    'phone': phone,
    'role': role,
    'is_seller': isSeller,
    'is_verified': isVerified,
    'created_at': createdAt.toIso8601String(),
  };
}
