import 'package:flutter/material.dart';
import '../models/payment_model.dart';

class PaymentViewModel extends ChangeNotifier {
  List<PaymentModel> _payments = [];

  List<PaymentModel> get payments => _payments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  PaymentViewModel() {
    _loadMockData();
  }

  void _loadMockData() {
    _isLoading = true;
    notifyListeners();

    // Mock initial data
    _payments = [
      PaymentModel(
        id: 'pay1',
        tenantId: 't1',
        propertyId: 'p1',
        roomId: 'r1',
        amount: 15000,
        date: DateTime.now().subtract(const Duration(days: 2)),
        method: 'Cash',
        status: 'Paid',
      ),
      PaymentModel(
        id: 'pay2',
        tenantId: 't2',
        propertyId: 'p1',
        roomId: 'r2',
        amount: 12000,
        date: DateTime.now(),
        method: 'Online',
        status: 'Pending',
      ),
      PaymentModel(
        id: 'pay3',
        tenantId: 't3',
        propertyId: 'p2',
        roomId: 'r4',
        amount: 20000,
        date: DateTime.now().subtract(const Duration(days: 1)),
        method: 'Bank Transfer',
        status: 'Paid',
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  void addPayment(PaymentModel payment) {
    _payments.add(payment);
    notifyListeners();
  }

  double getTotalCollected() {
    return _payments
        .where((p) => p.status == 'Paid')
        .fold(0, (sum, item) => sum + item.amount);
  }

  double getTotalPending() {
    return _payments
        .where((p) => p.status == 'Pending')
        .fold(0, (sum, item) => sum + item.amount);
  }
}
