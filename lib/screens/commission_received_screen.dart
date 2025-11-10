import 'package:flutter/material.dart';

class CommissionListScreen extends StatelessWidget {
  const CommissionListScreen({super.key});

  final List<Map<String, dynamic>> sampleCommissions = const [
    {
      'clientName': 'John Doe',
      'projectName': 'Sunshine Residency',
      'plotNo': 'A-101',
      'area': '1200 sqft',
      'amount': 500000,
      'date': '2025-11-07',
      'receivedPayment': 250000,
    },
    {
      'clientName': 'Jane Smith',
      'projectName': 'Green Meadows',
      'plotNo': 'B-205',
      'area': '900 sqft',
      'amount': 350000,
      'date': '2025-11-06',
      'receivedPayment': 350000,
    },
    {
      'clientName': 'Alex Johnson',
      'projectName': 'River View',
      'plotNo': 'C-12',
      'area': '1500 sqft',
      'amount': 750000,
      'date': '2025-11-05',
      'receivedPayment': 500000,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Commission List"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sampleCommissions.length,
        itemBuilder: (context, index) {
          final c = sampleCommissions[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRow("Client Name", c['clientName']),
                  _buildRow("Project Name", c['projectName']),
                  _buildRow("Plot No", c['plotNo']),
                  _buildRow("Area", c['area']),
                  _buildRow("Amount", "₹${c['amount']}"),
                  _buildRow("Date", c['date']),
                  _buildRow("Received Payment", "₹${c['receivedPayment']}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.deepPurple),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}