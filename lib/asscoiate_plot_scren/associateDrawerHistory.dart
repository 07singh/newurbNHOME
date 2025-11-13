import 'package:flutter/material.dart';

class AttendanceHistoryAssociatePage extends StatelessWidget {
  const AttendanceHistoryAssociatePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔹 Static sample data
    final List<Map<String, dynamic>> attendanceData = [
      {
        "EmpId": "EMP001",
        "EmployeeName": "Jyoti Sharma",
        "EmployeeType": "Full-Time",
        "EmpMob": "9876543210",
        "CheckInTime": "2025-11-10 09:30 AM",
        "CheckOutTime": "2025-11-10 06:15 PM",
        "CheckInLocation": "Office Reception",
        "CheckOutLocation": "Main Gate",
        "HoursWorked": "8h 45m",
        "Status": "Present",
        "Action": "Completed",
      },
      {
        "EmpId": "EMP002",
        "EmployeeName": "Rahul Verma",
        "EmployeeType": "Part-Time",
        "EmpMob": "9876501234",
        "CheckInTime": "2025-11-10 10:00 AM",
        "CheckOutTime": "2025-11-10 02:00 PM",
        "CheckInLocation": "Remote",
        "CheckOutLocation": "Remote",
        "HoursWorked": "4h 00m",
        "Status": "Present",
        "Action": "Completed",
      },
      {
        "EmpId": "EMP003",
        "EmployeeName": "Aditi Singh",
        "EmployeeType": "Intern",
        "EmpMob": "9988776655",
        "CheckInTime": "2025-11-10 09:45 AM",
        "CheckOutTime": "2025-11-10 05:00 PM",
        "CheckInLocation": "Office Reception",
        "CheckOutLocation": "Main Gate",
        "HoursWorked": "7h 15m",
        "Status": "Present",
        "Action": "Completed",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance History"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // horizontal scroll for wide table
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.blueAccent.shade100),
            border: TableBorder.all(color: Colors.grey.shade300),
            columns: const [
              DataColumn(label: Text('EmpId')),
              DataColumn(label: Text('Employee Name')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Mobile')),
              DataColumn(label: Text('Check-In')),
              DataColumn(label: Text('Check-Out')),
              DataColumn(label: Text('In Location')),
              DataColumn(label: Text('Out Location')),
              DataColumn(label: Text('Hours')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Action')),
            ],
            rows: attendanceData.map((data) {
              return DataRow(
                cells: [
                  DataCell(Text(data["EmpId"] ?? '')),
                  DataCell(Text(data["EmployeeName"] ?? '')),
                  DataCell(Text(data["EmployeeType"] ?? '')),
                  DataCell(Text(data["EmpMob"] ?? '')),
                  DataCell(Text(data["CheckInTime"] ?? '')),
                  DataCell(Text(data["CheckOutTime"] ?? '')),
                  DataCell(Text(data["CheckInLocation"] ?? '')),
                  DataCell(Text(data["CheckOutLocation"] ?? '')),
                  DataCell(Text(data["HoursWorked"] ?? '')),
                  DataCell(
                    Text(
                      data["Status"] ?? '',
                      style: TextStyle(
                        color: data["Status"] == "Present" ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      data["Action"] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
