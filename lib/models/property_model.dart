class PropertyModel {
  final String id;
  final String userId;
  final String name;
  final String address;

  PropertyModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'address': address,
    };
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map, String id) {
    return PropertyModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
    );
  }

  PropertyModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? address,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      address: address ?? this.address,
    );
  }
}

