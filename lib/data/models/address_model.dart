class AddressModel {
  final String id;
  final String title;
  final String city;
  final String street;
  final String? zip;
  final bool isDefault;
  final double lat;
  final double lng;

  const AddressModel({
    required this.id,
    required this.title,
    required this.city,
    required this.street,
    this.zip,
    this.isDefault = false,
    this.lat = 0,
    this.lng = 0,
  });

  String get full => '$street, $city${zip != null && zip!.isNotEmpty ? ', $zip' : ''}';
  bool get hasLocation => lat != 0 || lng != 0;

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        street: json['street']?.toString() ?? '',
        zip: json['zip']?.toString(),
        isDefault: json['is_default'] as bool? ?? false,
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
      );
}
