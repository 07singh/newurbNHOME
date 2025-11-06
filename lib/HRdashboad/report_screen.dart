import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  // Sample report data
  final List<Map<String, String>> reports = const [
    {
      "title": "Monthly Employee Performance",
      "description": "View performance metrics of employees for this month.",
    },
    {
      "title": "Leave Summary",
      "description": "Summary of leaves taken by employees.",
    },
    {
      "title": "Interview Schedule Report",
      "description": "Overview of scheduled interviews and status.",
    },
    {
      "title": "Booking Requests Report",
      "description": "All booking requests submitted by clients.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        backgroundColor: Colors.red,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                report["title"]!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  report["description"]!,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
              onTap: () {
                // Navigate to detailed report screen if needed
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected: ${report["title"]}')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
