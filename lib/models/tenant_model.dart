class TenantModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String roomId;
  final String propertyId;
  final DateTime joinDate;
  final bool isActive;

  TenantModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.roomId,
    required this.propertyId,
    required this.joinDate,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'roomId': roomId,
      'propertyId': propertyId,
      'joinDate': joinDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory TenantModel.fromMap(Map<String, dynamic> map, String id) {
    return TenantModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      roomId: map['roomId'] ?? '',
      propertyId: map['propertyId'] ?? '',
      joinDate: map['joinDate'] != null 
          ? DateTime.parse(map['joinDate']) 
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  TenantModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? roomId,
    String? propertyId,
    DateTime? joinDate,
    bool? isActive,
  }) {
    return TenantModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      roomId: roomId ?? this.roomId,
      propertyId: propertyId ?? this.propertyId,
      joinDate: joinDate ?? this.joinDate,
      isActive: isActive ?? this.isActive,
    );
  }
}

