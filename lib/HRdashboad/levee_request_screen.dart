import 'package:flutter/material.dart';

class LeaveRequestsScreen extends StatefulWidget {
  const LeaveRequestsScreen({Key? key}) : super(key: key);

  @override
  _LeaveRequestsScreenState createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> {
  // Sample leave requests
  List<Map<String, String>> leaveRequests = [
    {
      "name": "John Doe",
      "type": "Sick Leave",
      "date": "2025-10-17",
      "status": "Pending"
    },
    {
      "name": "Jane Smith",
      "type": "Casual Leave",
      "date": "2025-10-20",
      "status": "Approved"
    },
    {
      "name": "Alex Johnson",
      "type": "Annual Leave",
      "date": "2025-11-01",
      "status": "Rejected"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leave Requests"),
        backgroundColor: Colors.orange,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaveRequests.length,
        itemBuilder: (context, index) {
          final request = leaveRequests[index];
          Color statusColor;

          switch (request["status"]) {
            case "Approved":
              statusColor = Colors.green;
              break;
            case "Rejected":
              statusColor = Colors.red;
              break;
            default:
              statusColor = Colors.orange;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
            child: ListTile(
              title: Text(request["name"]!),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Type: ${request["type"]}"),
                  Text("Date: ${request["date"]}"),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  request["status"]!,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
