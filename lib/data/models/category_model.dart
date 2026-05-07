class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String? image;
  final int productCount;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.image,
    required this.productCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      icon: json['icon'],
      image: json['image'],
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
    );
  }
}