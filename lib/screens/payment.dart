import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentReceivedScreen extends StatefulWidget {
  const PaymentReceivedScreen({super.key});

  @override
  State<PaymentReceivedScreen> createState() => _PaymentReceivedScreenState();
}

class _PaymentReceivedScreenState extends State<PaymentReceivedScreen> {
  final List<Map<String, dynamic>> _payments = [
    {
      "date": "2025-11-06",
      "amount": 1500,
      "paymentThrough": "Online",
      "invoiceUrl": "https://realapp.cheenu.in/invoices/inv001.pdf"
    },
    {
      "date": "2025-11-03",
      "amount": 2000,
      "paymentThrough": "Cash",
      "invoiceUrl": null
    },
    {
      "date": "2025-10-30",
      "amount": 3200,
      "paymentThrough": "Online",
      "invoiceUrl": "https://realapp.cheenu.in/invoices/inv002.pdf"
    },
    {
      "date": "2025-10-25",
      "amount": 2500,
      "paymentThrough": "Cheque",
      "invoiceUrl": null
    },
  ];

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Payments Received",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.95,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _payments.length,
          itemBuilder: (context, index) {
            final payment = _payments[index];
            return _buildPaymentCard(payment);
          },
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final isOnline =
        payment["paymentThrough"].toString().toLowerCase() == "online";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.payment, color: Colors.black54, size: 26),
          const SizedBox(height: 6),
          Text(
            _formatDate(payment["date"]),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "₹${payment["amount"]}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.grey, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  payment["paymentThrough"],
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          isOnline
              ? ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              minimumSize: const Size(double.infinity, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.download, size: 18, color: Colors.white),
            label: const Text(
              "Invoice",
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            onPressed: () => _downloadInvoice(payment["invoiceUrl"]),
          )
              : Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                "No Invoice",
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadInvoice(String? url) {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No invoice available for this payment.")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Downloading invoice from $url")),
    );

    // 👉 TODO: Integrate dio or url_launcher for actual file download
  }
}
