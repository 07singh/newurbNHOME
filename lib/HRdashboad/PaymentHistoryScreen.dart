import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum PaymentView { summary, history }

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool loading = false;
  bool loadingSummary = false;
  List paymentList = [];
  List bookingSummary = [];
  PaymentView currentView = PaymentView.history;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  // ---------------------- GET PAYMENT HISTORY ----------------------
  Future<void> fetchHistory() async {
    setState(() {
      loading = true;
      errorMessage = null;
      currentView = PaymentView.history;
    });

    final url = "https://realapp.cheenu.in/Api/AddPaymentHistory";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          paymentList = data["data"] ?? [];
        });
      } else {
        showMessage("Failed to fetch history");
      }
    } catch (e) {
      showMessage("Failed to fetch history");
      errorMessage = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  // ---------------------- GET BOOKING SUMMARY ----------------------
  Future<void> fetchBookingSummary() async {
    setState(() {
      loadingSummary = true;
      errorMessage = null;
      currentView = PaymentView.summary;
    });

    const url = "https://realapp.cheenu.in/Api/GetBookingSummary";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          bookingSummary = data["data"] ?? [];
        });
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

    final response = await http.post(Uri.parse(url));

    if (response.statusCode == 200) {
      showMessage("Payment Accepted!");
      fetchHistory(); // refresh
    } else {
      showMessage("Accept Failed!");
    }
  }

  // ---------------------- REJECT PAYMENT ----------------------
  Future<void> rejectPayment(int id) async {
    final url = "https://realapp.cheenu.in/api/reject/payment?paymentId=$id";

    final response = await http.post(Uri.parse(url));

    if (response.statusCode == 200) {
      showMessage("Payment Rejected!");
      fetchHistory(); // refresh
    } else {
      showMessage("Reject Failed!");
    }
  }

  // Snackbar
  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

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
        title: Text("Payment History"),
        centerTitle: true,
      ),

      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ToggleButtons(
              isSelected: [
                currentView == PaymentView.summary,
                currentView == PaymentView.history,
              ],
              onPressed: (index) {
                if (index == 0) {
                  fetchBookingSummary();
                } else {
                  fetchHistory();
                }
              },
              borderRadius: BorderRadius.circular(12),
              selectedColor: Colors.white,
              fillColor: Colors.deepPurple,
              color: Colors.deepPurple,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text("Get Booking Summary"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text("Payment History"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildCurrentView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    if (currentView == PaymentView.summary) {
      if (loadingSummary) {
        return const Center(child: CircularProgressIndicator());
      }
      if (bookingSummary.isEmpty) {
        return const Center(child: Text("No Booking Summary Found"));
      }
      return ListView.builder(
        itemCount: bookingSummary.length,
        itemBuilder: (context, index) {
          final booking = bookingSummary[index];
          final payments = booking["Payment_History"] as List? ?? [];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "#${booking["Booking_Id"] ?? '-'} • ${booking["Project_Name"] ?? '-'}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text(booking["Booking_Status"] ?? "-"),
                        backgroundColor: Colors.deepPurple.withOpacity(0.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Plot: ${booking["Plot_Number"] ?? '-'}"),
                  Text("Customer: ${booking["Customer_Name"] ?? '-'} (${booking["Customer_Phn_Number"] ?? '-'})"),
                  Text("Dealer: ${booking["Booked_ByDealer"] ?? '-'} (${booking["Dealer_Phn_Number"] ?? '-'})"),
                  const SizedBox(height: 8),
                  Text(
                    "Amount: ₹${(booking["Total_Amount"] ?? 0).toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text("Received: ₹${(booking["Booking_ReceivingAmount"] ?? 0).toStringAsFixed(2)}"),
                  Text("Pending: ₹${(booking["Current_PendingAmount"] ?? 0).toStringAsFixed(2)}"),
                  const SizedBox(height: 10),
                  if (payments.isNotEmpty) ...[
                    const Text(
                      "Payment History",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      children: payments.map((payment) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.orange.shade100,
                                child: const Icon(Icons.payments, color: Colors.deepOrange),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "₹${(payment["Paid_Amount"] ?? 0).toStringAsFixed(2)} • ${payment["Paid_Through"] ?? '-'}",
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      "${payment["Payment_Status"] ?? '-'} • ${payment["Payment_Date"] ?? ''}",
                                    ),
                                  ],
                                ),
                              ),
                              _buildScreenshotIcon(payment["Screenshot"]),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ] else
                    const Text("No Payment History", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      );
    }

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (paymentList.isEmpty) {
      return const Center(child: Text("No Payment History Found"));
    }

    return ListView.builder(
      itemCount: paymentList.length,
      itemBuilder: (context, index) {
        final item = paymentList[index];

          final id = item["Payment_Id"];
          final amount = item["Paid_Amount"];
          final method = item["Paid_Through"];
          final status = item["Payment_Status"];
          final customer = item["Booking_Info"]["Customer_Name"];
          final plot = item["Booking_Info"]["Plot_Number"];
          final screenshot = item["Screenshot"];

        return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Payment ID: $id",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Amount: ₹$amount"),
                  Text("Method: $method"),
                  Text("Plot: $plot"),
                  Text("Customer: $customer"),
                  Text("Status: $status",
                      style: TextStyle(
                          color: status == "Approved"
                              ? Colors.green
                              : status == "Rejected"
                                  ? Colors.red
                                  : Colors.orange)),

                  const SizedBox(height: 10),

                  // ---------------- BUTTONS ----------------
                  // Only show buttons if payment is pending (not approved or rejected)
                  if (status != "Approved" && status != "Rejected" && status != "Accepted")
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => acceptPayment(id),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          child: const Text("ACCEPT",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => rejectPayment(id),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text("REJECT",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildScreenshotIcon(screenshot),
                    ],
                  )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: status == "Approved" || status == "Accepted"
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: status == "Approved" || status == "Accepted"
                              ? Colors.green
                              : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          status == "Approved" || status == "Accepted"
                              ? "✓ Payment Accepted"
                              : "✗ Payment Rejected",
                          style: TextStyle(
                            color: status == "Approved" || status == "Accepted"
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                ],
              ),
            ),
          );
        },
      );
  }
}