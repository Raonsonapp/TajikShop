import 'price_tier.dart';
export 'price_tier.dart';

class CartItemModel {
  final String id;
  final String productId;
  final String title;
  final String? image;

  /// Нархи ВОҚЕАН гирифташаванда — сервер зинаи яклухтро аллакай татбиқ
  /// кардааст. Пас сабад ва checkout ҳамеша як рақам медиҳанд.
  final double price;

  /// Нархи чакана — барои нишон додани «90 сом. ба ҷои 100».
  final double retailPrice;

  /// Оё ҳоло нархи яклухт амал мекунад?
  final bool wholesale;

  /// Зинаҳои фурӯшанда — то харидор бидонад, ки бо чанд дона арзонтар
  /// мешавад.
  final List<PriceTier> tiers;

  int quantity;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.title,
    this.image,
    required this.price,
    required this.quantity,
    double? retailPrice,
    this.wholesale = false,
    this.tiers = const [],
  }) : retailPrice = retailPrice ?? price;

  double get total => price * quantity;

  /// Чанд сомонӣ сарфа шуд (0 агар зина амал накунад).
  double get saved =>
      retailPrice > price ? (retailPrice - price) * quantity : 0;

  /// Зинаи НАВБАТӢ, агар шумораро зиёд кунад — «боз 4 дона гиред, 80 сом.
  /// мешавад». Ин маҳз он чизест, ки фармоиши калонтарро водор мекунад.
  PriceTier? get nextTier {
    PriceTier? best;
    for (final t in tiers) {
      if (t.minQty > quantity && (best == null || t.minQty < best.minQty)) {
        best = t;
      }
    }
    return best;
  }

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
      retailPrice: (json['retail_price'] as num?)?.toDouble(),
      wholesale: json['wholesale'] == true,
      tiers: (json['tiers'] is List)
          ? (json['tiers'] as List)
              .whereType<Map>()
              .map((m) => PriceTier.fromJson(m.cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }
}
