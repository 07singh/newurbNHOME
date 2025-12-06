import 'package:flutter/material.dart';
import '../model/totalBookingList_Model.dart';
import '../service/total_booking_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class TotalBookingListScreen extends StatefulWidget {
  const TotalBookingListScreen({super.key});

  @override
  State<TotalBookingListScreen> createState() => _TotalBookingListScreenState();
}

class _TotalBookingListScreenState extends State<TotalBookingListScreen> {
  TotalBookingListModel? bookingData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    final data = await TotalBookingService.getBookingHistory("9336938782");
    setState(() {
      bookingData = data;
      loading = false;
    });
  }

  // ------------------------------------
  // PDF Export for Single Booking
  // ------------------------------------
  Future<void> generateSinglePdf(BookingCommissionHistory b) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(children: [
          pw.Text("Booking Details",
              style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.deepPurple)),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ["Field", "Value"],
            data: [
              ["Project", b.projectName],
              ["Plot No", b.plotNumber],
              ["Booking Date", b.bookingDate ?? "N/A"],
              ["Area", b.bookingArea],
              ["Purchase Price", b.purchasePrice],
              ["Commission", "₹${b.commission}"],
            ],
          )
        ]),
      ),
    );

    await saveAndOpen(pdf, "${b.plotNumber}_Booking.pdf");
  }

  // ------------------------------------
  // PDF Export for All Bookings
  // ------------------------------------
  Future<void> generateAllPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Text("All Booking Report",
              style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.deepPurple)),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ["Project", "Plot", "Area", "Price", "Commission"],
            data: bookingData!.history.map((b) {
              return [
                b.projectName,
                b.plotNumber,
                b.bookingArea,
                b.purchasePrice,
                "₹${b.commission}"
              ];
            }).toList(),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
            headerStyle:
            pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          )
        ],
      ),
    );

    await saveAndOpen(pdf, "All_Bookings.pdf");
  }

  // ------------------------------------
  Future<void> saveAndOpen(pw.Document pdf, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/$name");
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);

    Share.shareXFiles([XFile(file.path)], text: "Booking Details PDF");
  }

  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Get Commission",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,   // ✅ Centered Title
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: bookingData == null ? null : () => generateAllPdf(),
          )
        ],
      ),


      body: loading
          ? const Center(child: CircularProgressIndicator())
          : bookingData == null || bookingData!.history.isEmpty
          ? const Center(child: Text("No bookings found"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookingData!.history.length,
        itemBuilder: (context, index) {
          return buildBookingCard(bookingData!.history[index]);
        },
      ),
    );
  }

  Widget buildBookingCard(BookingCommissionHistory b) {
    return GestureDetector(
      onTap: () => generateSinglePdf(b),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.list_alt, size: 40, color: Colors.deepPurple),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.projectName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("Plot: ${b.plotNumber}",
                        style: const TextStyle(color: Colors.grey)),
                    Text("Commission: ₹${b.commission}",
                        style: const TextStyle(
                            color: Colors.green,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ]),
            ),
            Text(b.bookingDate ?? "N/A",
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}