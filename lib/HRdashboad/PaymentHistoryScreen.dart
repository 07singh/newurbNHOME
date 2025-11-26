import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool loadingSummary = false;

  List<Map<String, dynamic>> bookingSummaryList = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchBookingSummary(switchTab: false);
  }

  // ---------------------- FETCH BOOKING SUMMARY ----------------------
  Future<void> fetchBookingSummary({bool switchTab = true}) async {
    setState(() {
      loadingSummary = true;
      errorMessage = null;
    });

    const url = "https://realapp.cheenu.in/Api/GetBookingSummary";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        List<Map<String, dynamic>> list = [];

        if (body is Map && body["data"] is List) {
          list = (body["data"] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        setState(() => bookingSummaryList = list);
      } else {
        showMessage("Failed to fetch booking summary");
      }
    } catch (e) {
      showMessage("Failed to fetch booking summary");
      errorMessage = e.toString();
    } finally {
      setState(() => loadingSummary = false);
    }
  }

  // ---------------------- ACCEPT PAYMENT ----------------------
  Future<void> acceptPayment(int id) async {
    final url = "https://realapp.cheenu.in/api/accept/payment?paymentId=$id";
    try {
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        showMessage("Payment Accepted!");
        await fetchBookingSummary(switchTab: false);
      } else {
        showMessage("Accept Failed!");
      }
    } catch (e) {
      showMessage("Accept Failed!");
    }
  }

  // ---------------------- REJECT PAYMENT ----------------------
  Future<void> rejectPayment(int id) async {
    final url = "https://realapp.cheenu.in/api/reject/payment?paymentId=$id";
    try {
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        showMessage("Payment Rejected!");
        await fetchBookingSummary(switchTab: false);
      } else {
        showMessage("Reject Failed!");
      }
    } catch (e) {
      showMessage("Reject Failed!");
    }
  }

  // ---------------------- SHOW SNACKBAR ----------------------
  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ---------------------- SCREENSHOT PREVIEW ----------------------
  void _showScreenshot(String? screenshot) {
    if (screenshot == null || screenshot.trim().isEmpty) {
      showMessage("No screenshot available");
      return;
    }

    final cleaned = screenshot.trim();
    late Widget imageWidget;

    if (cleaned.startsWith('http')) {
      imageWidget = Image.network(cleaned, fit: BoxFit.contain);
    } else if (cleaned.startsWith('/')) {
      imageWidget = Image.network('https://realapp.cheenu.in$cleaned', fit: BoxFit.contain);
    } else {
      try {
        final base64Data = cleaned.contains(',') ? cleaned.split(',').last : cleaned;
        final Uint8List bytes = base64Decode(base64Data);
        imageWidget = Image.memory(bytes, fit: BoxFit.contain);
      } catch (e) {
        showMessage("Invalid screenshot data");
        return;
      }
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SizedBox(
              height: 300,
              width: double.infinity,
              child: InteractiveViewer(child: imageWidget),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenshotIcon(String? screenshot) {
    final hasScreenshot = screenshot != null && screenshot.trim().isNotEmpty;
    return InkWell(
      onTap: hasScreenshot ? () => _showScreenshot(screenshot) : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: hasScreenshot ? Colors.deepPurple.withOpacity(0.1) : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.image_rounded,
          color: hasScreenshot ? Colors.deepPurple : Colors.grey,
          size: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Summary"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => fetchBookingSummary(switchTab: false),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(child: _buildCurrentView()),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    if (loadingSummary) {
      return const Center(child: CircularProgressIndicator());
    }
    if (bookingSummaryList.isEmpty) {
      return const Center(child: Text("No booking summary found"));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: bookingSummaryList.map(_buildBookingCard).toList(),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final number = booking["booking_id"] ?? booking["Booking_Id"] ?? "-";
    final project = booking["project_name"] ?? booking["Project_Name"] ?? "-";
    final total = double.tryParse((booking["total_amount"] ?? booking["Total_Amount"] ?? 0).toString()) ?? 0;
    final paid = double.tryParse((booking["total_paid"] ?? booking["Total_Approved_Payments"] ?? booking["Booking_ReceivingAmount"] ?? 0).toString()) ?? 0;
    final pending = double.tryParse((booking["pending_amount"] ?? booking["Current_PendingAmount"] ?? 0).toString()) ?? 0;
    final plot = booking["plot_number"] ?? booking["Plot_Number"] ?? "-";
    final payments = booking["payment_history"] ?? booking["Payment_History"] ?? [];
    final initialPaid = double.tryParse((booking["Booking_ReceivingAmount"] ?? booking["Initial_Paid"] ?? 0).toString()) ?? 0;
    final initialRemark = booking["Booking_Remark"] ?? booking["Initial_Remark"] ?? "";
    final initialDate = booking["Booking_PaymentDate"] ?? booking["Initial_Paid_On"] ?? "";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("#$number • $project", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Plot: $plot"),
            Text("Total Amount: ₹${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w600)),
            Text("Total Paid: ₹${paid.toStringAsFixed(2)}"),
            Text("Pending: ₹${pending.toStringAsFixed(2)}"),
            const SizedBox(height: 12),
            if (initialPaid > 0) ...[
              const Text("Booking Time Payment", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("₹${initialPaid.toStringAsFixed(2)}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    if (initialRemark.toString().trim().isNotEmpty)
                      Text(initialRemark, style: const TextStyle(color: Colors.black87)),
                    if (initialDate.toString().trim().isNotEmpty)
                      Text(initialDate, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text("Payment History", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (payments.isEmpty)
              const Text("No payments found", style: TextStyle(color: Colors.grey))
            else
              Column(
                children: (payments as List)
                    .whereType<Map>()
                    .map<Widget>((payment) {
                  final amount = double.tryParse((payment["Paid_Amount"] ?? 0).toString()) ?? 0;
                  final method = payment["Paid_Through"] ?? "-";
                  final status = payment["Payment_Status"] ?? "-";
                  final date = payment["Payment_Date"] ?? "";
                  final screenshot = payment["Screenshot"];
                  final isPending = !(status == "Approved" || status == "Rejected" || status == "Accepted");
                  final paymentId = payment["Payment_Id"];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(backgroundColor: Colors.deepPurple.shade100, child: const Icon(Icons.payments, color: Colors.deepPurple)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("₹${amount.toStringAsFixed(2)} • $method", style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text("$status • $date"),
                            ],
                          ),
                        ),
                        if (isPending && paymentId != null)
                          Row(
                            children: [
                              ElevatedButton(onPressed: () => acceptPayment(paymentId), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("ACCEPT")),
                              const SizedBox(width: 4),
                              ElevatedButton(onPressed: () => rejectPayment(paymentId), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("REJECT")),
                            ],
                          ),
                        _buildScreenshotIcon(screenshot),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
