class VariantModel {
  final String id;
  final String size;
  final String color;
  final String sku;
  final double price;
  final int stock;

  const VariantModel({
    required this.id,
    this.size = '',
    this.color = '',
    this.sku = '',
    this.price = 0,
    this.stock = 0,
  });

  String get label {
    final parts = [if (size.isNotEmpty) size, if (color.isNotEmpty) color];
    return parts.isEmpty ? (sku.isNotEmpty ? sku : 'Вариант') : parts.join(' • ');
  }

  bool get inStock => stock > 0;

  factory VariantModel.fromJson(Map<String, dynamic> j) => VariantModel(
        id: j['id']?.toString() ?? '',
        size: j['size']?.toString() ?? '',
        color: j['color']?.toString() ?? '',
        sku: j['sku']?.toString() ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        stock: (j['stock'] as num?)?.toInt() ?? 0,
      );
}
