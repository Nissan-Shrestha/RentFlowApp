import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/tenant_model.dart';
import '../models/payment_model.dart';
import '../viewmodels/payment_viewmodel.dart';
import '../viewmodels/property_viewmodel.dart';
import '../viewmodels/tenant_viewmodel.dart';

class TenantDetailsScreen extends StatelessWidget {
  final String tenantId;

  const TenantDetailsScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    final tenantVM = context.watch<TenantViewModel>();
    final paymentVM = context.watch<PaymentViewModel>();
    final propertyVM = context.watch<PropertyViewModel>();

    final tenant = tenantVM.getTenantById(tenantId);

    if (tenant == null) {
      return const Scaffold(body: Center(child: Text('Tenant not found')));
    }

    final tenantPayments = paymentVM.payments.where((p) => p.tenantId == tenant.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final property = propertyVM.properties.where((p) => p.id == tenant.propertyId).firstOrNull;
    final room = propertyVM.rooms.where((r) => r.id == tenant.roomId).firstOrNull;

    if (property == null || room == null) {
      return const Scaffold(body: Center(child: Text('Loading Details...')));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tenant Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF1E3A8A)),
            onPressed: () => _showEditTenantSheet(context, tenantVM, tenant),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _showDeleteConfirmation(context, tenant),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.blue[50],
                    child: Text(
                      tenant.name[0],
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenant.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tenant.phone,
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Room Info
            const Text('Property & Room', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.home_work_outlined, 'Property', property.name),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.meeting_room_outlined, 'Room', 'Room ${room.roomNumber}'),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.payments_outlined, 'Rent Amount', 'Rs ${room.rentAmount.toInt()} / Month'),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.calendar_month_outlined, 'Joined On', DateFormat('dd MMM yyyy').format(tenant.joinDate)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Payment History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text('${tenantPayments.length} entries', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            if (tenantPayments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('No payment records found.'),
                ),
              )
            else
              ...tenantPayments.map((payment) => _buildPaymentTile(payment)),
          ],
        ),
      ),
    );
  }

  void _showEditTenantSheet(BuildContext context, TenantViewModel tenantVM, TenantModel tenant) {
    final nameController = TextEditingController(text: tenant.name);
    final phoneController = TextEditingController(text: tenant.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Edit Tenant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
                
                final updatedTenant = tenant.copyWith(
                  name: nameController.text,
                  phone: phoneController.text,
                );
                
                tenantVM.updateTenant(updatedTenant);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tenant updated successfully')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TenantModel tenant) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Tenant?'),
        content: Text('Are you sure you want to remove ${tenant.name}? The room will be marked as vacant.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final tenantVM = context.read<TenantViewModel>();
              tenantVM.removeTenant(tenant.id, tenant.roomId);
              
              // Close dialog
              Navigator.pop(dialogContext);
              // Go back to tenants list
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${tenant.name} removed successfully')),
              );
            },
            child: const Text('REMOVE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildPaymentTile(PaymentModel payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.green, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rent Paid - ${DateFormat('MMMM yyyy').format(payment.date)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'via ${payment.method}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            'Rs ${payment.amount.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
