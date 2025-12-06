import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class TotalBookingListScreen extends StatelessWidget {
  const TotalBookingListScreen({super.key});

  final List<Map<String, dynamic>> _bookings = const [
    {
      'plotNo': 'A-102',
      'clientName': 'Ravi Kumar',
      'amount': 850000,
      'status': 'Booked',
      'date': '05 Nov 2025',
      'color': Colors.blue,
    },
    {
      'plotNo': 'B-205',
      'clientName': 'Priya Sharma',
      'amount': 1200000,
      'status': 'Pending',
      'date': '04 Nov 2025',
      'color': Colors.orange,
    },
    {
      'plotNo': 'C-310',
      'clientName': 'Amit Patel',
      'amount': 950000,
      'status': 'Booked',
      'date': '02 Nov 2025',
      'color': Colors.blue,
    },
    {
      'plotNo': 'A-108',
      'clientName': 'Neha Singh',
      'amount': 780000,
      'status': 'Partially Paid',
      'date': '01 Nov 2025',
      'color': Colors.purple,
    },
  ];

  // Generate PDF for single booking
  // Generate PDF for single booking
  Future<void> _generateSinglePdf(Map<String, dynamic> booking, BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.deepPurple,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Center(
                  child: pw.Text(
                    "Booking Details",
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 30),

              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Plot No
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          "Plot No",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(booking['plotNo'] as String),
                      ),
                    ],
                  ),
                  // Client Name
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          "Client Name",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(booking['clientName'] as String),
                      ),
                    ],
                  ),
                  // Amount
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          "Amount",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text("₹${_formatAmount(booking['amount'] as int)}"),
                      ),
                    ],
                  ),
                  // Status
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          "Status",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: _getPdfColor(booking['color'] as Color),
                            borderRadius: pw.BorderRadius.circular(20),
                          ),
                          child: pw.Text(
                            booking['status'] as String,
                            style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Date
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          "Date",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(booking['date'] as String),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await _saveAndSharePdf(pdf, "${booking['plotNo']}_booking.pdf", context);
  }

  // Generate PDF for all bookings
  Future<void> _generateAllBookingsPdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text("All Bookings Report", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple))),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Plot No', 'Client', 'Amount', 'Status', 'Date'],
            data: _bookings.map((b) => [
              b['plotNo'],
              b['clientName'],
              "₹${_formatAmount(b['amount'])}",
              b['status'],
              b['date'],
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.center,
              4: pw.Alignment.centerRight,
            },
          ),
        ],
      ),
    );

    await _saveAndSharePdf(pdf, "All_Bookings_${DateTime.now().toIso8601String().split('T')[0]}.pdf", context);
  }

  Future<void> _saveAndSharePdf(pw.Document pdf, String fileName, BuildContext context) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/$fileName");
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("PDF Saved: $fileName"),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: "Share",
            textColor: Colors.white,
            onPressed: () {
              Share.shareXFiles([XFile(file.path)], text: "Booking PDF");
            },
          ),
        ),
      );

      OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error generating PDF"), backgroundColor: Colors.red),
      );
    }
  }

  PdfColor _getPdfColor(Color color) {
    if (color == Colors.blue) return PdfColors.blue;
    if (color == Colors.orange) return PdfColors.orange;
    if (color == Colors.purple) return PdfColors.purple;
    return PdfColors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("My Bookings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generateAllBookingsPdf(context),
            tooltip: "Export All to PDF",
          ),
        ],
      ),
      body: _bookings.isEmpty
          ? const Center(child: Text("No bookings yet", style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return _buildBookingCard(context, booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> booking) {
    return GestureDetector(
      onTap: () => _generateSinglePdf(booking, context),
      onLongPress: () => _generateAllBookingsPdf(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (booking['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.home_work, color: booking['color'], size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking['plotNo'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(booking['clientName'], style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text("₹${_formatAmount(booking['amount'])}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.green)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (booking['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(booking['status'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: booking['color'])),
                ),
                const SizedBox(height: 8),
                Text(booking['date'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toString();
  }
}