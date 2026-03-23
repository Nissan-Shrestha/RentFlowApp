import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/property_viewmodel.dart';
import '../viewmodels/payment_viewmodel.dart';
import '../viewmodels/tenant_viewmodel.dart';
import '../services/pdf_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedRange = 'This Month';

  @override
  Widget build(BuildContext context) {
    final propertyVM = context.watch<PropertyViewModel>();
    final paymentVM = context.watch<PaymentViewModel>();
    final tenantVM = context.watch<TenantViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const Text(
            'Select Time Period',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          
          // Date Range Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRange,
                isExpanded: true,
                icon: const Icon(Icons.calendar_today, size: 20),
                items: <String>['This Month', 'Last 6 Months', 'Last 1 Year']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedRange = newValue!;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 32),

          const Text(
            'PDF Reports',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          // Simplified Report Option Card
          _buildReportOption(
            title: 'Tenant Payment History',
            description: 'Download the complete list of payments for all tenants.',
            icon: Icons.people_outline,
            onTap: () {
              final now = DateTime.now();
              final filteredPayments = paymentVM.payments.where((p) {
                if (_selectedRange == 'This Month') {
                  return p.date.month == now.month && p.date.year == now.year;
                } else if (_selectedRange == 'Last 6 Months') {
                  final sixMonthsAgo = now.subtract(const Duration(days: 180));
                  return p.date.isAfter(sixMonthsAgo);
                } else if (_selectedRange == 'Last 1 Year') {
                  final oneYearAgo = now.subtract(const Duration(days: 365));
                  return p.date.isAfter(oneYearAgo);
                }
                return true;
              }).toList()
                ..sort((a, b) => b.date.compareTo(a.date));

              PdfService.generateTenantReport(
                payments: filteredPayments,
                rooms: propertyVM.rooms,
                tenants: tenantVM.tenants,
                properties: propertyVM.properties,
                range: _selectedRange,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportOption({
    required String title,
    required String description,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
            child: Row(
              children: [
                // Icon Background
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF1E3A8A), size: 28),
                ),
                const SizedBox(width: 16),
                
                // Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Export Button Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
