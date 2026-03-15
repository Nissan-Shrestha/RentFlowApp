import 'package:flutter/material.dart';
import '../models/tenant_model.dart';

class TenantViewModel extends ChangeNotifier {
  List<TenantModel> _tenants = [];

  List<TenantModel> get tenants => _tenants;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  TenantViewModel() {
    _loadMockData();
  }

  void _loadMockData() {
    _isLoading = true;
    notifyListeners();

    // Mock initial data
    _tenants = [
      TenantModel(
        id: 't1',
        name: 'Ram Shrestha',
        phone: '+977 9801234567',
        roomId: 'r1',
        propertyId: 'p1',
        joinDate: DateTime.now().subtract(const Duration(days: 120)),
      ),
      TenantModel(
        id: 't2',
        name: 'Sita Gurung',
        phone: '+977 9811234567',
        roomId: 'r2',
        propertyId: 'p1',
        joinDate: DateTime.now().subtract(const Duration(days: 60)),
      ),
      TenantModel(
        id: 't3',
        name: 'Hari Bahadur',
        phone: '+977 9822334455',
        roomId: 'r4',
        propertyId: 'p2',
        joinDate: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  void addTenant(TenantModel tenant) {
    _tenants.add(tenant);
    // TODO: also update the room to be occupied
    notifyListeners();
  }

  void updateTenant(TenantModel updatedTenant) {
    final index = _tenants.indexWhere((t) => t.id == updatedTenant.id);
    if (index != -1) {
      _tenants[index] = updatedTenant;
      notifyListeners();
    }
  }
  
  TenantModel? getTenantById(String id) {
    try {
      return _tenants.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}
