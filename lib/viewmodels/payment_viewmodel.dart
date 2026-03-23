import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/payment_model.dart';

class PaymentViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<PaymentModel> _payments = [];

  List<PaymentModel> get payments => _payments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription? _paymentsSub;

  PaymentViewModel() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadData(user.uid);
      } else {
        _clearData();
      }
    });
  }

  void _loadData(String userId) {
    _isLoading = true;
    notifyListeners();

    _paymentsSub?.cancel();
    _paymentsSub = _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      _payments = snapshot.docs.map((doc) => PaymentModel.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    });

    _isLoading = false;
    notifyListeners();
  }

  void _clearData() {
    _paymentsSub?.cancel();
    _payments = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _paymentsSub?.cancel();
    super.dispose();
  }

  Future<void> addPayment(PaymentModel payment) async {
    await _firestore.collection('payments').doc(payment.id).set(payment.toMap());
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

