import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/Model/add_history_screen.dart';
import '/service/add_histroy_services.dart';
import '/DirectLogin/add_detail_screen.dart';

class DayBookHistoryScreen extends StatefulWidget {
  const DayBookHistoryScreen({super.key});

  @override
  State<DayBookHistoryScreen> createState() => _DayBookHistoryScreenState();
}

class _DayBookHistoryScreenState extends State<DayBookHistoryScreen> {
  late Future<List<DayBookHistory>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = DayBookHistoryService.fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String day = DateFormat('EEEE').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Day Book History',
          style: TextStyle(
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
        color: Colors.white,
        child: SafeArea(
          child: FutureBuilder<List<DayBookHistory>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.black));
              } else if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.black)));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('No history found', style: TextStyle(color: Colors.black)));
              }

              final history = snapshot.data!;

              return Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    "$day, $today",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final entry = history[index];
                        if (entry.employeeName == null && entry.dateTime == null) {
                          return const SizedBox.shrink();
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple.shade200,
                              child: Text(
                                entry.employeeName?.isNotEmpty == true
                                    ? entry.employeeName![0]
                                    : '?',
                              ),
                            ),
                            title: Text(
                              entry.employeeName ?? 'Unknown Employee',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                                'Amount: ₹${entry.amount?.toStringAsFixed(2) ?? '-'}\nPurpose: ${entry.purpose ?? '-'}'),
                            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.purple),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DayBookDetailScreen(
                                    entry: entry,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}