import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/Model/add_history_screen.dart';

class DayBookDetailScreen extends StatelessWidget {
  final DayBookHistory entry;

  const DayBookDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFormatted = entry.dateTime != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(entry.dateTime!)
        : 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${entry.employeeName ?? 'Employee'}'s Day Book",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFD700),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff7F00FF), Color(0xffE100FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(entry.employeeName ?? 'Unknown',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(dateFormatted,
                        style:
                        const TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Amount & Purpose
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.money, color: Colors.purple),
                  title: const Text('Amount'),
                  trailing: Text(
                    "₹ ${entry.amount?.toStringAsFixed(2) ?? '0'}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.description, color: Colors.purple),
                  title: const Text('Purpose'),
                  trailing: Text(entry.purpose ?? '-'),
                ),
              ),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.phone, color: Colors.purple),
                  title: const Text('Spent By'),
                  trailing: Text(entry.spendBy ?? '-'),
                ),
              ),

              const SizedBox(height: 20),

              // Approve / Reject Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle approve API call
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle reject API call
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text("Reject"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}