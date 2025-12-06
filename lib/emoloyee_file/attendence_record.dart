import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _selectedSection = 0;
  final List<String> _sections = ['Today', 'Yesterday', 'Month'];

  // Static data for demonstration
  final List<AttendanceRecord> _todayRecords = [
    AttendanceRecord(
      employeeName: 'Akhand pratap singh',
      timeIn: DateTime(2024, 1, 15, 9, 0),
      timeOut: DateTime(2024, 1, 15, 17, 0),
      statement: 'Approved',
    ),
    AttendanceRecord(
      employeeName: 'Amit',
      timeIn: DateTime(2024, 1, 15, 8, 45),
      timeOut: DateTime(2024, 1, 15, 17, 30),
      statement: 'Pending',
    ),
    AttendanceRecord(
      employeeName: 'Salim Ansari',
      timeIn: DateTime(2024, 1, 15, 9, 15),
      timeOut: null, // Still working
      statement: 'Approved',
    ),
  ];

  final List<AttendanceRecord> _yesterdayRecords = [
    AttendanceRecord(
      employeeName: 'Bhanu singh',
      timeIn: DateTime(2024, 1, 14, 9, 5),
      timeOut: DateTime(2024, 1, 14, 17, 10),
      statement: 'Approved',
    ),
    AttendanceRecord(
      employeeName: 'Mohan',
      timeIn: DateTime(2024, 1, 14, 8, 50),
      timeOut: DateTime(2024, 1, 14, 17, 20),
      statement: 'Rejected',
    ),
  ];

  final List<AttendanceRecord> _monthRecords = [
    AttendanceRecord(
      employeeName: 'raja ',
      timeIn: DateTime(2024, 1, 1, 9, 0),
      timeOut: DateTime(2024, 1, 1, 17, 0),
      statement: 'Approved',
    ),
    AttendanceRecord(
      employeeName: 'aslam ',
      timeIn: DateTime(2024, 1, 2, 8, 55),
      timeOut: DateTime(2024, 1, 2, 17, 5),
      statement: 'Approved',
    ),
    // Add more monthly records as needed
  ];

  List<AttendanceRecord> get _currentRecords {
    switch (_selectedSection) {
      case 0:
        return _todayRecords;
      case 1:
        return _yesterdayRecords;
      case 2:
        return _monthRecords;
      default:
        return _todayRecords;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance Records',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header Section
          _buildHeaderSection(),

          // List Section
          Expanded(
            child: _buildAttendanceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_sections.length, (index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSection = index;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _selectedSection == index
                    ? Colors.yellow
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                _sections[index],
                style: TextStyle(
                  color: _selectedSection == index
                      ? Colors.black
                      : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAttendanceList() {
    return ListView.builder(
      itemCount: _currentRecords.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final record = _currentRecords[index];
        return _buildAttendanceCard(record);
      },
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee Name
            Text(
              record.employeeName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),

            // Time In and Time Out
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeInfo(
                  'Time In',
                  DateFormat('hh:mm a').format(record.timeIn),
                ),
                _buildTimeInfo(
                  'Time Out',
                  record.timeOut != null
                      ? DateFormat('hh:mm a').format(record.timeOut!)
                      : '--:--',
                ),
              ],
            ),
            SizedBox(height: 12),

            // Statement
            Row(
              children: [
                Text(
                  'Status: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                _buildStatementChip(record.statement),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildStatementChip(String statement) {
    Color backgroundColor;
    Color textColor;

    switch (statement.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[800]!;
        break;
      case 'pending':
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[800]!;
        break;
      case 'rejected':
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[800]!;
        break;
      default:
        backgroundColor = Colors.grey[50]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statement,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class AttendanceRecord {
  final String employeeName;
  final DateTime timeIn;
  final DateTime? timeOut;
  final String statement;

  AttendanceRecord({
    required this.employeeName,
    required this.timeIn,
    this.timeOut,
    required this.statement,
  });
}