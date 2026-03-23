import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../models/room_model.dart';

class PropertyViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<PropertyModel> _properties = [];
  List<RoomModel> _rooms = [];

  List<PropertyModel> get properties => _properties;
  List<RoomModel> get rooms => _rooms;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription? _propertiesSub;
  StreamSubscription? _roomsSub;

  PropertyViewModel() {
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

    _propertiesSub?.cancel();
    _propertiesSub = _firestore
        .collection('properties')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          _properties = snapshot.docs
              .map((doc) => PropertyModel.fromMap(doc.data(), doc.id))
              .toList();
          notifyListeners();
        });

    _roomsSub?.cancel();
    _roomsSub = _firestore
        .collection('rooms')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          _rooms = snapshot.docs
              .map((doc) => RoomModel.fromMap(doc.data(), doc.id))
              .toList();
          notifyListeners();
        });

    _isLoading = false;
    notifyListeners();
  }

  void _clearData() {
    _propertiesSub?.cancel();
    _roomsSub?.cancel();
    _properties = [];
    _rooms = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _propertiesSub?.cancel();
    _roomsSub?.cancel();
    super.dispose();
  }

  Future<void> addProperty(PropertyModel property) async {
    await _firestore
        .collection('properties')
        .doc(property.id)
        .set(property.toMap());
  }

  Future<void> addRoom(RoomModel room) async {
    await _firestore.collection('rooms').doc(room.id).set(room.toMap());
  }

  Future<void> updateRoom(RoomModel updatedRoom) async {
    await _firestore
        .collection('rooms')
        .doc(updatedRoom.id)
        .update(updatedRoom.toMap());
  }

  Future<void> updateProperty(PropertyModel updatedProperty) async {
    await _firestore
        .collection('properties')
        .doc(updatedProperty.id)
        .update(updatedProperty.toMap());
  }

  Future<void> deleteProperty(String propertyId) async {
    final WriteBatch batch = _firestore.batch();
    
    // Delete the property document
    batch.delete(_firestore.collection('properties').doc(propertyId));
    
    // Find and delete all rooms belonging to this property
    final roomsToDelete = _rooms.where((r) => r.propertyId == propertyId);
    for (var room in roomsToDelete) {
      batch.delete(_firestore.collection('rooms').doc(room.id));
    }
    
    await batch.commit();
  }

  Future<void> wipeAllUserData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final WriteBatch batch = _firestore.batch();

    // Delete properties
    final properties = await _firestore.collection('properties').where('userId', isEqualTo: userId).get();
    for (var doc in properties.docs) {
      batch.delete(doc.reference);
    }

    // Delete rooms
    final rooms = await _firestore.collection('rooms').where('userId', isEqualTo: userId).get();
    for (var doc in rooms.docs) {
      batch.delete(doc.reference);
    }

    // Delete tenants
    final tenants = await _firestore.collection('tenants').where('userId', isEqualTo: userId).get();
    for (var doc in tenants.docs) {
      batch.delete(doc.reference);
    }

    // Delete payments
    final payments = await _firestore.collection('payments').where('userId', isEqualTo: userId).get();
    for (var doc in payments.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  List<RoomModel> getRoomsForProperty(String propertyId) {
    return _rooms.where((room) => room.propertyId == propertyId).toList();
  }
}
