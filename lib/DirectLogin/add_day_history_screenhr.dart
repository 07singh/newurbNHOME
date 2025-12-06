import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/Model/add_history_screen.dart';
import '/service/add_histroy_services.dart';
import '/DirectLogin/add_detail_screen.dart';
import'/DirectLogin/add_detail_screenhr.dart';

class DayBookHistoryScreenhr extends StatefulWidget {
  const DayBookHistoryScreenhr({super.key});

  @override
  State<DayBookHistoryScreenhr> createState() => _DayBookHistoryScreenhrState();
}

class _DayBookHistoryScreenhrState extends State<DayBookHistoryScreenhr> {
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
        elevation: 0,
        backgroundColor: const Color(0xFF3371F4), // Gold Color
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Day Book History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: FutureBuilder<List<DayBookHistory>>(
            future: _historyFuture,
            builder: (context, snapshot) {

              // --- Loading State ---
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.black,
                  ),
                );
              }

              // --- Error State ---
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }

              // --- Empty State ---
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No history found',
                    style: TextStyle(color: Colors.black),
                  ),
                );
              }

              final history = snapshot.data!;

              return Column(
                children: [
                  const SizedBox(height: 16),

                  // DATE DISPLAY
                  Text(
                    "$day, $today",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // LIST VIEW
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: ListTile(
                            leading: _buildThumbnail(entry),

                            title: Text(
                              entry.employeeName ?? 'Unknown Employee',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            subtitle: Text(
                              'Amount: ₹${entry.amount?.toStringAsFixed(2) ?? '-'}\n'
                                  'Purpose: ${entry.purpose ?? '-'}\n'
                                  'Payment Given By: ${entry.paymentGivenBy ?? '-'}\n'
                                  'Mode: ${entry.paymentMode ?? '-'}',
                            ),

                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.purple,
                            ),

                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DayBookDetailScreenhr(entry: entry),
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
  Widget _buildThumbnail(DayBookHistory entry) {
    final imageUrl = entry.getScreenshotFullUrl();

    if (imageUrl == null) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: Colors.purple.shade200,
        child: Text(
          entry.employeeName?.isNotEmpty == true ? entry.employeeName![0] : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: 22,
          backgroundColor: Colors.purple.shade200,
          child: Text(
            entry.employeeName?.isNotEmpty == true ? entry.employeeName![0] : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
