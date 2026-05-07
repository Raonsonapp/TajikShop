class CartItemModel {
  final String id;
  final String productId;
  final String title;
  final String? image;
  final double price;
  int quantity;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.title,
    this.image,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // Backend may return nested product object
    final product = json['product'] as Map<String, dynamic>?;
    final images = product?['images'] as List?;

    return CartItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? product?['id']?.toString() ?? '',
      title: product?['title'] ?? json['title'] ?? json['product_title'] ?? '',
      image: images != null && images.isNotEmpty
          ? images.first.toString()
          : (product?['image_url'] ?? json['image'] ?? json['product_image']),
      price: (json['price'] as num?)?.toDouble() ??
             (product?['price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
