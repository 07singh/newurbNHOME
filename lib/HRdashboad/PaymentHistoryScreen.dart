import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool loading = false;
  List paymentList = [];

  // ---------------------- GET PAYMENT HISTORY ----------------------
  Future<void> fetchHistory() async {
    setState(() => loading = true);

    final url = "https://realapp.cheenu.in/Api/AddPaymentHistory";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        paymentList = data["data"] ?? [];
      });
    } else {
      showMessage("Failed to fetch history");
    }

    setState(() => loading = false);
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

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Payment History"),
        centerTitle: true,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : paymentList.isEmpty
          ? const Center(child: Text("No Payment History Found"))
          : ListView.builder(
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
                              : Colors.red)),

                  const SizedBox(height: 10),

                  // ---------------- BUTTONS ----------------
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
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}