class ProductModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final double? oldPrice;
  final int discountPercent;
  final String? categoryId;
  final String? categoryName;
  final String sellerId;
  final String? sellerName;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final int stock;
  final bool inStock;
  final int views;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.oldPrice,
    this.discountPercent = 0,
    this.categoryId,
    this.categoryName,
    required this.sellerId,
    this.sellerName,
    required this.images,
    required this.rating,
    required this.reviewCount,
    required this.stock,
    required this.inStock,
    this.views = 0,
    required this.createdAt,
  });

  String get mainImage => images.isNotEmpty ? images.first : '';

  int get computedDiscount {
    if (discountPercent > 0) return discountPercent;
    if (oldPrice == null || oldPrice! <= price) return 0;
    return (((oldPrice! - price) / oldPrice!) * 100).round();
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<String> imgs = [];
    final rawImages = json['images'];
    if (rawImages is List) {
      imgs = rawImages.map((e) => e.toString()).toList();
    } else if (json['image_url'] != null) {
      imgs = [json['image_url'].toString()];
    }

    final discPct = (json['discount_percent'] as num?)?.toInt() ?? 0;
    final basePrice = (json['price'] as num?)?.toDouble() ?? 0;
    double? oldPrice;
    if (discPct > 0 && basePrice > 0) {
      oldPrice = basePrice / (1 - discPct / 100);
    }

    return ProductModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: basePrice,
      oldPrice: oldPrice,
      discountPercent: discPct,
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name'],
      sellerId: json['seller_id']?.toString() ?? '',
      sellerName: json['seller_name'],
      images: imgs,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      inStock: (json['is_active'] ?? json['in_stock'] ?? true) as bool,
      views: (json['views'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
