class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatar;
  final String role;
  final bool isSeller;
  final bool isVerified;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatar,
    required this.role,
    required this.isSeller,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) {
    // ✅ Сервер "name" ё "full_name" ё "username" мефиристад
    final name = j['full_name']?.toString() ??
        j['name']?.toString() ??
        j['username']?.toString() ??
        j['email']?.toString().split('@').first ??
        'Корбар';
    final role = j['role']?.toString() ?? 'buyer';
    return UserModel(
      id: j['id']?.toString() ?? '',
      email: j['email']?.toString() ?? '',
      fullName: name,
      avatar: j['avatar_url']?.toString() ?? j['avatar']?.toString(),
      role: role,
      isSeller: j['is_seller'] == true || role == 'seller' || role == 'admin',
      isVerified: j['is_verified'] == true,
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'avatar_url': avatar,
    'role': role,
    'is_seller': isSeller,
    'is_verified': isVerified,
    'created_at': createdAt.toIso8601String(),
  };
}
