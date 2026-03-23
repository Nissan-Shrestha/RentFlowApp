import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/property_model.dart';
import '../models/payment_model.dart';
import '../models/room_model.dart';
import '../models/tenant_model.dart';

class PdfService {
  static Future<void> generateCollectionReport({
    required List<PropertyModel> properties,
    required List<RoomModel> rooms,
    required List<PaymentModel> payments,
    required String range,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Rent Flow - Collection Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: $dateStr'),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Report Period: $range', style: pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 20),
          
          pw.TableHelper.fromTextArray(
            headers: ['Property Name', 'Total Rooms', 'Occupied', 'Expected Rent', 'Collected', 'Pending'],
            data: properties.map((property) {
              final propertyRooms = rooms.where((r) => r.propertyId == property.id).toList();
              final occupied = propertyRooms.where((r) => r.isOccupied).toList();
              
              final expected = occupied.fold(0.0, (sum, r) => sum + r.rentAmount);
              final collected = payments
                  .where((p) => p.propertyId == property.id && p.status == 'Paid')
                  .fold(0.0, (sum, p) => sum + p.amount);
              final pending = expected - collected;

              return [
                property.name,
                propertyRooms.length.toString(),
                occupied.length.toString(),
                'Rs ${expected.toInt()}',
                'Rs ${collected.toInt()}',
                'Rs ${pending.toInt()}',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
          ),
          
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 20),
            child: pw.Divider(),
          ),
          
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Grand Total Collected: Rs ${payments.where((p) => p.status == 'Paid').fold(0.0, (sum, p) => sum + p.amount).toInt()}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                  ),
                  pw.Text(
                    'Total Outstanding: Rs ${(properties.fold(0.0, (sum, p) {
                      final pRooms = rooms.where((r) => r.propertyId == p.id && r.isOccupied);
                      return sum + pRooms.fold(0.0, (s, r) => s + r.rentAmount);
                    }) - payments.where((p) => p.status == 'Paid').fold(0.0, (sum, p) => sum + p.amount)).toInt()}',
                    style: pw.TextStyle(color: PdfColors.red, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> generateTenantReport({
    required List<PaymentModel> payments,
    required List<RoomModel> rooms,
    required List<TenantModel> tenants,
    required List<PropertyModel> properties,
    required String range,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Rent Flow', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('Tenant Payment History Report', style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text('Generated: $dateStr'),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Reference Period: $range', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 24),
          
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Tenant Name', 'Property', 'Room', 'Amount', 'Method'],
            data: payments.map((payment) {
              final roomName = rooms.any((r) => r.id == payment.roomId)
                  ? rooms.firstWhere((r) => r.id == payment.roomId).roomNumber
                  : 'N/A';
              
              final tenantName = tenants.any((t) => t.id == payment.tenantId)
                  ? tenants.firstWhere((t) => t.id == payment.tenantId).name
                  : 'Unknown Tenant';

              final propertyName = properties.any((p) => p.id == payment.propertyId)
                  ? properties.firstWhere((p) => p.id == payment.propertyId).name
                  : 'N/A';
              
              return [
                DateFormat('dd MMM yyyy').format(payment.date),
                tenantName,
                propertyName,
                'Room $roomName',
                'Rs ${payment.amount.toInt()}',
                payment.method,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.center,
            },
          ),
          
          pw.SizedBox(height: 32),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue900, width: 2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  'Total Collected: Rs ${payments.where((p) => p.status == 'Paid').fold(0.0, (sum, p) => sum + p.amount).toInt()}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.blue900),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
