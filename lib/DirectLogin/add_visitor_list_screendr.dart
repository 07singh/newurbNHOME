import 'package:flutter/material.dart';
import '/Model/add_visitor_list.dart';
import '/service/add_visitor_service_list.dart';
import 'package:intl/intl.dart'; // For formatting date

class VisitorListScreenddr extends StatefulWidget {
  const VisitorListScreenddr({super.key});

  @override
  State<VisitorListScreenddr> createState() => _VisitorListScreenddrState();
}

class _VisitorListScreenddrState extends State<VisitorListScreenddr> {
  final VisitorService _service = VisitorService();
  late Future<List<Visitor>> _futureVisitors;

  @override
  void initState() {
    super.initState();
    _futureVisitors = _fetchAndSortVisitors(); // ✅ Fetch + sort
  }

  /// Fetch visitors and sort so latest ones appear first
  Future<List<Visitor>> _fetchAndSortVisitors() async {
    final visitors = await _service.fetchVisitors();
    visitors.sort((a, b) {
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return b.date!.compareTo(a.date!); // ✅ latest first
    });
    return visitors;
  }

  String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Visitor List',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor:  Color(0xFFFFD700),
        centerTitle: true,
        elevation: 2,
      ),
      body: FutureBuilder<List<Visitor>>(
        future: _futureVisitors,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No visitors found'));
          } else {
            final visitors = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _futureVisitors = _fetchAndSortVisitors(); // 🔄 reload latest list
                });
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: visitors.length,
                itemBuilder: (context, index) {
                  final visitor = visitors[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:  Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        child: Text(
                          (visitor.name != null && visitor.name!.isNotEmpty)
                              ? visitor.name![0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(
                        visitor.name ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mobile: ${visitor.mobileNo ?? '-'}'),
                            Text('Purpose: ${visitor.purpose ?? '-'}'),
                            Text('Date: ${formatDate(visitor.date)}'),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}