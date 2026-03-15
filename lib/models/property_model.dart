class PropertyModel {
  final String id;
  final String name;
  final String address;

  PropertyModel({
    required this.id,
    required this.name,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
    };
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map, String id) {
    return PropertyModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
    );
  }

  PropertyModel copyWith({
    String? id,
    String? name,
    String? address,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
    );
  }
}
