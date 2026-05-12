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
  final int likeCount;
  final DateTime createdAt;

  const ProductModel({
    required this.id, required this.title, required this.description,
    required this.price, this.oldPrice, this.discountPercent = 0,
    this.categoryId, this.categoryName,
    required this.sellerId, this.sellerName,
    required this.images, required this.rating, required this.reviewCount,
    required this.stock, required this.inStock,
    this.views = 0, this.likeCount = 0, required this.createdAt,
  });

  String get mainImage => images.isNotEmpty ? images.first : '';

  int get computedDiscount {
    if (discountPercent > 0) return discountPercent;
    if (oldPrice == null || oldPrice! <= price) return 0;
    return (((oldPrice! - price) / oldPrice!) * 100).round();
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Images
    List<String> imgs = [];
    final rawImages = json['images'] ?? json['image_urls'];
    if (rawImages is List) {
      imgs = rawImages.where((e) => e != null && e.toString().isNotEmpty).map((e) {
        final s = e.toString();
        return s.startsWith('http') ? s : 'https://tajikshop.onrender.com$s';
      }).toList();
    } else if (json['image_url'] != null && json['image_url'].toString().isNotEmpty) {
      final s = json['image_url'].toString();
      imgs = [s.startsWith('http') ? s : 'https://tajikshop.onrender.com$s'];
    }

    final discPct  = (json['discount_percent'] as num?)?.toInt() ?? 0;
    final basePrice = (json['price'] as num?)?.toDouble() ?? 0;
    double? oldPrice;
    if (discPct > 0 && basePrice > 0) oldPrice = basePrice / (1 - discPct / 100);

    // inStock: агар stock > 0 ё is_active=true → дастрас
    // Агар stock field умуман нест → дастрас фарз мекунем
    final stock    = (json['stock'] as num?)?.toInt();
    final isActive = json['is_active'] as bool? ?? true;
    // stock=null → маълум нест, 999 фарз мекунем; stock=0 → тамом шуд
    final realStock = stock ?? 999;
    final inStock   = isActive && realStock > 0;

    return ProductModel(
      id:              json['id']?.toString() ?? '',
      title:           json['title']?.toString() ?? '',
      description:     json['description']?.toString() ?? '',
      price:           basePrice,
      oldPrice:        oldPrice,
      discountPercent: discPct,
      categoryId:      json['category_id']?.toString(),
      categoryName:    json['category_name']?.toString(),
      sellerId:        json['seller_id']?.toString() ?? '',
      sellerName:      json['seller_name']?.toString(),
      images:          imgs,
      rating:          (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount:     (json['review_count'] as num?)?.toInt() ?? 0,
      stock:           realStock,
      inStock:         inStock,
      views:           (json['views'] as num?)?.toInt() ?? 0,
      likeCount:       (json['like_count'] ?? json['favorites_count'] as num?)?.toInt() ?? 0,
      createdAt:       json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
