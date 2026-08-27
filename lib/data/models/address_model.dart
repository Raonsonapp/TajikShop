class AddressModel {
  final String id;
  final String title;
  final String city;
  final String street;
  final String house;
  final String entrance;
  final String floor;
  final String apartment;
  final String landmark;
  final String region;
  final String? zip;
  final bool isDefault;
  final double lat;
  final double lng;

  const AddressModel({
    required this.id,
    required this.title,
    required this.city,
    required this.street,
    this.house = '',
    this.entrance = '',
    this.floor = '',
    this.apartment = '',
    this.landmark = '',
    this.region = '',
    this.zip,
    this.isDefault = false,
    this.lat = 0,
    this.lng = 0,
  });

  /// Суроғаи пурра барои расонанда — рақами хона ҳатман ҳаст,
  /// чунки маҳз ҳамон гум шуданро пешгирӣ мекунад.
  String get full {
    final parts = <String>[
      if (street.isNotEmpty) street,
      if (house.isNotEmpty) 'хонаи $house',
      if (apartment.isNotEmpty) 'ҳуҷраи $apartment',
      if (entrance.isNotEmpty) 'вуруди $entrance',
      if (floor.isNotEmpty) 'ошёнаи $floor',
      if (city.isNotEmpty) city,
    ];
    return parts.join(', ');
  }

  /// Сатри кӯтоҳ барои корт: «кӯча, хонаи N».
  String get shortLine => [
        if (street.isNotEmpty) street,
        if (house.isNotEmpty) 'хонаи $house',
      ].join(', ');
  bool get hasLocation => lat != 0 || lng != 0;

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        street: json['street']?.toString() ?? '',
        house: json['house']?.toString() ?? '',
        entrance: json['entrance']?.toString() ?? '',
        floor: json['floor']?.toString() ?? '',
        apartment: json['apartment']?.toString() ?? '',
        landmark: json['landmark']?.toString() ?? '',
        region: json['region']?.toString() ?? '',
        zip: json['zip']?.toString(),
        isDefault: json['is_default'] as bool? ?? false,
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
      );
}
