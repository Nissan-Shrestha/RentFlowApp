class PaymentModel {
  final String id;
  final String userId;
  final String tenantId;
  final String propertyId;
  final String roomId;
  final double amount;
  final DateTime date;
  final String method; // e.g., 'Cash' or 'Online'
  final String status; // e.g., 'Paid' or 'Pending'

  PaymentModel({
    required this.id,
    required this.userId,
    required this.tenantId,
    required this.propertyId,
    required this.roomId,
    required this.amount,
    required this.date,
    required this.method,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tenantId': tenantId,
      'propertyId': propertyId,
      'roomId': roomId,
      'amount': amount,
      'date': date.toIso8601String(),
      'method': method,
      'status': status,
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      userId: map['userId'] ?? '',
      tenantId: map['tenantId'] ?? '',
      propertyId: map['propertyId'] ?? '',
      roomId: map['roomId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: map['date'] != null 
          ? DateTime.parse(map['date']) 
          : DateTime.now(),
      method: map['method'] ?? 'Cash',
      status: map['status'] ?? 'Pending',
    );
  }

  PaymentModel copyWith({
    String? id,
    String? userId,
    String? tenantId,
    String? propertyId,
    String? roomId,
    double? amount,
    DateTime? date,
    String? method,
    String? status,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tenantId: tenantId ?? this.tenantId,
      propertyId: propertyId ?? this.propertyId,
      roomId: roomId ?? this.roomId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      method: method ?? this.method,
      status: status ?? this.status,
    );
  }
}

