import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../models/room_model.dart';

class PropertyViewModel extends ChangeNotifier {
  List<PropertyModel> _properties = [];
  List<RoomModel> _rooms = [];

  List<PropertyModel> get properties => _properties;
  List<RoomModel> get rooms => _rooms;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  PropertyViewModel() {
    _loadMockData();
  }

  void _loadMockData() {
    _isLoading = true;
    notifyListeners();

    // Mock initial data
    _properties = [
      PropertyModel(id: 'p1', name: 'House A - Jawalakhel', address: 'Jawalakhel, Lalitpur'),
      PropertyModel(id: 'p2', name: 'House B - Baneshwor', address: 'Old Baneshwor, Kathmandu'),
    ];
    
    _rooms = [
      RoomModel(id: 'r1', propertyId: 'p1', roomNumber: '1', rentAmount: 15000, isOccupied: true, currentTenantId: 't1'),
      RoomModel(id: 'r2', propertyId: 'p1', roomNumber: '2', rentAmount: 12000, isOccupied: true, currentTenantId: 't2'),
      RoomModel(id: 'r3', propertyId: 'p1', roomNumber: '3', rentAmount: 15000, isOccupied: false),
      RoomModel(id: 'r4', propertyId: 'p2', roomNumber: '1', rentAmount: 20000, isOccupied: true, currentTenantId: 't3'),
      RoomModel(id: 'r5', propertyId: 'p2', roomNumber: '2', rentAmount: 20000, isOccupied: false),
    ];

    _isLoading = false;
    notifyListeners();
  }

  void addProperty(PropertyModel property) {
    _properties.add(property);
    notifyListeners();
  }

  void addRoom(RoomModel room) {
    _rooms.add(room);
    notifyListeners();
  }

  void updateRoom(RoomModel updatedRoom) {
    final index = _rooms.indexWhere((r) => r.id == updatedRoom.id);
    if (index != -1) {
      _rooms[index] = updatedRoom;
      notifyListeners();
    }
  }

  void updateProperty(PropertyModel updatedProperty) {
    final index = _properties.indexWhere((p) => p.id == updatedProperty.id);
    if (index != -1) {
      _properties[index] = updatedProperty;
      notifyListeners();
    }
  }

  List<RoomModel> getRoomsForProperty(String propertyId) {
    return _rooms.where((room) => room.propertyId == propertyId).toList();
  }
}
