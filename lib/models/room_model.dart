class RoomModel {
  final String id;
  final String propertyId;
  final String roomNumber;
  final double rentAmount;
  final bool isOccupied;
  final String? currentTenantId;

  RoomModel({
    required this.id,
    required this.propertyId,
    required this.roomNumber,
    required this.rentAmount,
    this.isOccupied = false,
    this.currentTenantId,
  });

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'roomNumber': roomNumber,
      'rentAmount': rentAmount,
      'isOccupied': isOccupied,
      'currentTenantId': currentTenantId,
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map, String id) {
    return RoomModel(
      id: id,
      propertyId: map['propertyId'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      rentAmount: (map['rentAmount'] ?? 0.0).toDouble(),
      isOccupied: map['isOccupied'] ?? false,
      currentTenantId: map['currentTenantId'],
    );
  }

  RoomModel copyWith({
    String? id,
    String? propertyId,
    String? roomNumber,
    double? rentAmount,
    bool? isOccupied,
    String? currentTenantId,
  }) {
    return RoomModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      roomNumber: roomNumber ?? this.roomNumber,
      rentAmount: rentAmount ?? this.rentAmount,
      isOccupied: isOccupied ?? this.isOccupied,
      currentTenantId: currentTenantId ?? this.currentTenantId,
    );
  }
}
