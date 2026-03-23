import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/property_model.dart';
import '../models/room_model.dart';
import '../viewmodels/property_viewmodel.dart';
import '../screens/property_details_screen.dart';

class PropertiesScreen extends StatelessWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final propertyVM = context.watch<PropertyViewModel>();
    final properties = propertyVM.properties;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Very light grey background
      appBar: AppBar(
        title: const Text(
          'My Properties',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            onPressed: () {
              _showAddPropertySheet(context, propertyVM);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: properties.isEmpty
                ? const Center(child: Text("No properties added yet."))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      final property = properties[index];
                      final rooms = propertyVM.getRoomsForProperty(property.id);

                      final totalRooms = rooms.length;
                      final occupiedRooms = rooms
                          .where((r) => r.isOccupied)
                          .length;
                      final totalRentExpected = rooms.fold(
                        0.0,
                        (sum, room) => sum + room.rentAmount,
                      );

                      String status = totalRooms == 0
                          ? 'No Rooms'
                          : occupiedRooms == totalRooms
                          ? 'Fully Occupied'
                          : '${totalRooms - occupiedRooms} Rooms Vacant';
                      Color statusColor =
                          (totalRooms > 0 && occupiedRooms == totalRooms)
                          ? Colors.green
                          : Colors.orange;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PropertyDetailsScreen(propertyId: property.id),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              _buildPropertyCard(
                                context,
                                name: property.name,
                                address: property.address,
                                totalRooms: totalRooms,
                                occupiedRooms: occupiedRooms,
                                monthlyExpected: 'Rs ${totalRentExpected.toInt()}',
                                status: status,
                                statusColor: statusColor,
                              ),
                              Positioned(
                                top: 8,
                                right: 35, // Near the chevron
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    _showDeleteConfirmation(context, propertyVM, property, occupiedRooms);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PropertyViewModel propertyVM, PropertyModel property, int occupiedRooms) {
    if (occupiedRooms > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('Action Blocked'),
            ],
          ),
          content: Text('You cannot delete "${property.name}" because it still has $occupiedRooms active tenants. Please remove all tenants from this property before deleting it.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property?'),
        content: Text('This will permanently delete "${property.name}" and all its rooms. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              propertyVM.deleteProperty(property.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${property.name}" deleted')),
              );
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddPropertySheet(
    BuildContext context,
    PropertyViewModel propertyVM,
  ) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final roomsController = TextEditingController();
    final rentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Add New Property',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 32),

                // Property Name Input
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Property Name/Title',
                    hintText: 'e.g., House A - Baneshwor',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),

                // Address Input
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    hintText: 'e.g., Old Baneshwor, Kathmandu',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),

                // Rooms Input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: roomsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Number of Rooms',
                          hintText: 'e.g., 10',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: rentController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Rent per Room',
                          hintText: 'e.g., 15000',
                          prefixText: 'Rs ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isEmpty ||
                        addressController.text.isEmpty) {
                      return;
                    }

                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    final newProperty = PropertyModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: user.uid,
                      name: nameController.text,
                      address: addressController.text,
                    );

                    propertyVM.addProperty(newProperty);

                    int numRooms = int.tryParse(roomsController.text) ?? 0;
                    double rentAmt =
                        double.tryParse(rentController.text) ?? 15000.0;

                    for (int i = 1; i <= numRooms; i++) {
                      final newRoom = RoomModel(
                        id: '${newProperty.id}_room_$i',
                        userId: user.uid,
                        propertyId: newProperty.id,
                        roomNumber: i.toString(),
                        rentAmount: rentAmt,
                        isOccupied: false,
                      );
                      propertyVM.addRoom(newRoom);
                    }

                    Navigator.pop(sheetContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Property added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Property',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPropertyCard(
    BuildContext context, {
    required String name,
    required String address,
    required int totalRooms,
    required int occupiedRooms,
    required String monthlyExpected,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Type Icon & Name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home_work, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1),
          ),

          // Details Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn('Occupancy', '$occupiedRooms/$totalRooms Rooms'),
              _buildInfoColumn('Total Rent Value', monthlyExpected),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
