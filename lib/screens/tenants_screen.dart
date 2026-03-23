import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:rent_flow_app/screens/tenant_details_screen.dart';
import '../models/tenant_model.dart';
import '../viewmodels/tenant_viewmodel.dart';
import '../viewmodels/payment_viewmodel.dart';
import '../viewmodels/property_viewmodel.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  String _selectedFilter = 'All'; // All, Paid, Pending

  @override
  Widget build(BuildContext context) {
    final tenantVM = context.watch<TenantViewModel>();
    final paymentVM = context.watch<PaymentViewModel>();
    final propertyVM = context.watch<PropertyViewModel>();

    // Filter logic
    final now = DateTime.now();
    List<TenantModel> displayTenants = tenantVM.tenants;
    
    // Status and Filter Logic based on current month's payments
    bool checkIsPending(TenantModel tenant) {
      // It is NOT pending if there is a 'Paid' payment for THIS month/year
      bool hasPaidThisMonth = paymentVM.payments.any((p) =>
          p.tenantId == tenant.id &&
          p.status == 'Paid' &&
          p.date.month == now.month &&
          p.date.year == now.year);
      return !hasPaidThisMonth;
    }

    if (_selectedFilter == 'Paid' || _selectedFilter == 'Pending') {
      displayTenants = tenantVM.tenants.where((t) {
        bool isPending = checkIsPending(t);
        if (_selectedFilter == 'Pending') return isPending;
        if (_selectedFilter == 'Paid') return !isPending;
        return true;
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Tenants Directory',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () {
              _showAddTenantSheet(context, tenantVM, propertyVM);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', Icons.people_outline),
                      const SizedBox(width: 8),
                      _buildFilterChip('Paid', Icons.check_circle_outline),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', Icons.error_outline),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dynamic Tenants List
          Expanded(
            child: displayTenants.isEmpty
                ? const Center(child: Text("No tenants match the filter."))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayTenants.length,
                    itemBuilder: (context, index) {
                      final tenant = displayTenants[index];

                      // Status relying on current month's payments
                      bool isPending = checkIsPending(tenant);

                      final propertyList = propertyVM.properties.where(
                        (p) => p.id == tenant.propertyId,
                      );
                      String propertyName = propertyList.isNotEmpty
                          ? propertyList.first.name
                          : 'Unknown Property';

                      final roomList = propertyVM.rooms.where(
                        (r) => r.id == tenant.roomId,
                      );
                      String roomName = roomList.isNotEmpty
                          ? roomList.first.roomNumber
                          : tenant.roomId;
                      String rentPrice = roomList.isNotEmpty
                          ? 'Rs ${roomList.first.rentAmount.toInt()}'
                          : 'Rs 0';

                      return _buildTenantCard(
                        name: tenant.name,
                        location: '$propertyName • Room $roomName',
                        phone: tenant.phone,
                        rentAmount: rentPrice,
                        status: isPending ? 'Pending' : 'Paid',
                        statusColor: isPending
                            ? Colors.redAccent
                            : Colors.green,
                        daysOverdue: isPending 
                            ? now.difference(tenant.joinDate.isBefore(DateTime(now.year, now.month, 1)) 
                                ? DateTime(now.year, now.month, 1) 
                                : tenant.joinDate).inDays 
                            : null,
                        onSendReminder: () async {
                          final currentMonth = DateFormat('MMMM').format(now);
                          final message = 'Hi ${tenant.name}, just a friendly reminder that your rent for $currentMonth is currently pending. Please log your payment when you can. Thanks!';
                          final Uri smsLaunchUri = Uri(
                            scheme: 'sms',
                            path: tenant.phone,
                            queryParameters: <String, String>{
                              'body': message,
                            },
                          );
                          if (await canLaunchUrl(smsLaunchUri)) {
                            await launchUrl(smsLaunchUri);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not launch SMS app.'))
                              );
                            }
                          }
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TenantDetailsScreen(tenantId: tenant.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddTenantSheet(
    BuildContext context,
    TenantViewModel tenantVM,
    PropertyViewModel propertyVM,
  ) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedPropertyId;
    String? selectedRoomId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                      'Add New Tenant',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Property Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPropertyId,
                          hint: const Text('Select Property'),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey,
                          ),
                          items: propertyVM.properties.map((property) {
                            return DropdownMenuItem<String>(
                              value: property.id,
                              child: Text(
                                property.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setModalState(() {
                              selectedPropertyId = newValue;
                              selectedRoomId = null; // Reset room selection
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name Input
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'e.g., Ram Shrestha',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Input
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'e.g., +977 98XXXXXXX',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Room Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRoomId,
                          hint: const Text('Select a Vacant Room'),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey,
                          ),
                          items: selectedPropertyId == null
                              ? []
                              : propertyVM
                                    .getRoomsForProperty(selectedPropertyId!)
                                    .where(
                                      (room) =>
                                          !room.isOccupied ||
                                          room.id == selectedRoomId,
                                    )
                                    .map((room) {
                                      return DropdownMenuItem<String>(
                                        value: room.id,
                                        child: Text(
                                          'Room ${room.roomNumber}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(),
                          onChanged: selectedPropertyId == null
                              ? null
                              : (String? newValue) {
                                  setModalState(() {
                                    selectedRoomId = newValue;
                                  });
                                },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isEmpty ||
                            phoneController.text.isEmpty ||
                            selectedPropertyId == null ||
                            selectedRoomId == null) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please fill all fields and select a property & room.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        final newTenant = TenantModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          userId: user.uid,
                          name: nameController.text,
                          phone: phoneController.text,
                          roomId: selectedRoomId!,
                          propertyId: selectedPropertyId!,
                          joinDate: DateTime.now(),
                        );

                        tenantVM.addTenant(newTenant);

                        // Update the room in the property to occupied
                        final selectedRoom = propertyVM.rooms.firstWhere(
                          (r) => r.id == selectedRoomId,
                        );
                        propertyVM.updateRoom(
                          selectedRoom.copyWith(
                            isOccupied: true,
                            currentTenantId: newTenant.id,
                          ),
                        );

                        Navigator.pop(sheetContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tenant successfully added!'),
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
                        'Save Tenant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Filter Chip builder
  Widget _buildFilterChip(String label, IconData icon) {
    bool isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tenant Card Builder
  Widget _buildTenantCard({
    required String name,
    required String location,
    required String phone,
    required String rentAmount,
    required String status,
    required Color statusColor,
    int? daysOverdue,
    VoidCallback? onSendReminder,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue[50],
                      child: Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Specific Room String
                          Row(
                            children: [
                              Icon(
                                Icons.door_front_door_outlined,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Phone String
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                phone,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          rentAmount,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
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

                // Contextual Overdue Warning message
                if (status == 'Pending' && (daysOverdue ?? 0) > 0) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$daysOverdue days overdue',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      // Quick SMS trigger for overdue accounts!
                      TextButton.icon(
                        onPressed: onSendReminder,
                        icon: const Icon(Icons.sms_outlined, size: 16),
                        label: const Text('Send Reminder'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
