import 'package:flutter/material.dart';

class CommissionListScreen extends StatelessWidget {
  const CommissionListScreen({super.key});

  // Dummy data for now
  final List<Map<String, dynamic>> commissions = const [
    {
      "clientName": "Rohit Sharma",
      "projectName": "Green Regency Phase 2",
      "commissionAmount": 15000,
      "status": "Paid",
      "date": "05-11-2025",
    },
    {
      "clientName": "Priya Verma",
      "projectName": "Defence Enclave Phase 2",
      "commissionAmount": 20000,
      "status": "Pending",
      "date": "02-11-2025",
    },
    {
      "clientName": "Amit Singh",
      "projectName": "Sunshine Valley",
      "commissionAmount": 12000,
      "status": "Paid",
      "date": "30-10-2025",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Commission List",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFD700),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: commissions.length,
        itemBuilder: (context, index) {
          final item = commissions[index];
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRow("Client Name", item["clientName"]),
                  _buildRow("Project Name", item["projectName"]),
                  _buildRow("Commission Amount", "₹ ${item["commissionAmount"]}"),
                  _buildRow("Status", item["status"],
                      valueColor: item["status"] == "Paid" ? Colors.green : Colors.red),
                  _buildRow("Date", item["date"]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
