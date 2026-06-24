class AddressModel {
  final String id;
  final String title;
  final String city;
  final String street;
  final String? zip;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.title,
    required this.city,
    required this.street,
    this.zip,
    this.isDefault = false,
  });

  String get full => '$street, $city${zip != null && zip!.isNotEmpty ? ', $zip' : ''}';

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        street: json['street']?.toString() ?? '',
        zip: json['zip']?.toString(),
        isDefault: json['is_default'] as bool? ?? false,
      );
}
