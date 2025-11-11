import 'package:flutter/material.dart';
import '/Model/add_visitor_list.dart';
import '/service/add_visitor_service_list.dart';
import 'package:intl/intl.dart'; // For formatting date

class VisitorListScreenem extends StatefulWidget {
  const VisitorListScreenem({super.key});

  @override
  State<VisitorListScreenem> createState() => _VisitorListScreenState();
}

class _VisitorListScreenState extends State<VisitorListScreenem> {
  final VisitorService _service = VisitorService();
  late Future<List<Visitor>> _futureVisitors;

  @override
  void initState() {
    super.initState();
    _futureVisitors = _service.fetchVisitors();
  }

  String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy-MM-dd – HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Visitor List',
          style: TextStyle(color: Colors.white), // White text
        ),
        backgroundColor: Colors.deepPurple, // Blue background
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
            return ListView.builder(
              itemCount: visitors.length,
              itemBuilder: (context, index) {
                final visitor = visitors[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(visitor.name != null && visitor.name!.isNotEmpty
                          ? visitor.name![0]
                          : '?'),
                    ),
                    title: Text(visitor.name ?? '-'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mobile: ${visitor.mobileNo ?? '-'}'),
                        Text('Purpose: ${visitor.purpose ?? '-'}'),
                        Text('Date: ${formatDate(visitor.date)}'),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
