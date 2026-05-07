class OrderModel {
  final String id;
  final String status;
  final double total;
  final int itemCount;
  final String? address;
  final String? note;
  final String? paymentProof;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.status,
    required this.total,
    required this.itemCount,
    this.address,
    this.note,
    this.paymentProof,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List?;
    return OrderModel(
      id: json['id']?.toString() ?? '',
      status: json['status'] ?? 'pending',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      itemCount: items?.length ?? (json['item_count'] as num?)?.toInt() ?? 0,
      address: json['address']?.toString() ?? json['address_id']?.toString(),
      note: json['note'],
      paymentProof: json['payment_proof'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
