import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/tenant_model.dart';

class TenantViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TenantModel> _tenants = [];

  List<TenantModel> get tenants => _tenants;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription? _tenantsSub;

  TenantViewModel() {
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

    _tenantsSub?.cancel();
    _tenantsSub = _firestore
        .collection('tenants')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      _tenants = snapshot.docs.map((doc) => TenantModel.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    });

    _isLoading = false;
    notifyListeners();
  }

  void _clearData() {
    _tenantsSub?.cancel();
    _tenants = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _tenantsSub?.cancel();
    super.dispose();
  }

  Future<void> addTenant(TenantModel tenant) async {
    await _firestore.collection('tenants').doc(tenant.id).set(tenant.toMap());
  }

  Future<void> updateTenant(TenantModel updatedTenant) async {
    await _firestore.collection('tenants').doc(updatedTenant.id).update(updatedTenant.toMap());
  }

  Future<void> removeTenant(String id, String roomId) async {
    final batch = _firestore.batch();
    
    // Delete tenant
    batch.delete(_firestore.collection('tenants').doc(id));
    
    // Update room status to vacant
    batch.update(_firestore.collection('rooms').doc(roomId), {
      'isOccupied': false,
    });
    
    await batch.commit();
  }

  TenantModel? getTenantById(String id) {
    try {
      return _tenants.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}

