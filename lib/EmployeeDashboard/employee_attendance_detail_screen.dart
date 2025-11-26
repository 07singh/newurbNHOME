import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/Model/AttendanceRecord.dart';
import '/Model/attendance_summary.dart';

class EmployeeAttendanceDetailScreen extends StatefulWidget {
  final String employeeName;
  final String empId;
  final String employeeType;
  final List<AttendanceRecord> allAttendanceRecords;
  final DateTime startDate;
  final DateTime endDate;
  final String tabType; // 'Today', 'Weeks', 'Months', 'All'

  const EmployeeAttendanceDetailScreen({
    Key? key,
    required this.employeeName,
    required this.empId,
    required this.employeeType,
    required this.allAttendanceRecords,
    required this.startDate,
    required this.endDate,
    required this.tabType,
  }) : super(key: key);

  @override
  State<EmployeeAttendanceDetailScreen> createState() => _EmployeeAttendanceDetailScreenState();
}

class _EmployeeAttendanceDetailScreenState extends State<EmployeeAttendanceDetailScreen> {
  List<DateAttendance> _dateWiseAttendance = [];

  @override
  void initState() {
    super.initState();
    _generateDateWiseAttendance();
  }

  void _generateDateWiseAttendance() {
    final List<DateAttendance> dateList = [];
    final employeeRecords = widget.allAttendanceRecords
        .where((record) => record.empId == widget.empId)
        .toList();

    // Create a map of dates to attendance records
    final Map<String, AttendanceRecord> dateToRecord = {};
    for (var record in employeeRecords) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.checkInTime);
      // Keep the most recent record if multiple records exist for same date
      if (!dateToRecord.containsKey(dateKey) || 
          record.checkInTime.isAfter(dateToRecord[dateKey]!.checkInTime)) {
        dateToRecord[dateKey] = record;
      }
    }

    // Generate all dates in the range
    DateTime currentDate = DateTime(
      widget.startDate.year,
      widget.startDate.month,
      widget.startDate.day,
    );
    final endDate = DateTime(
      widget.endDate.year,
      widget.endDate.month,
      widget.endDate.day,
    );

    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
      final record = dateToRecord[dateKey];
      
      dateList.add(DateAttendance(
        date: DateTime(currentDate.year, currentDate.month, currentDate.day),
        isPresent: record != null,
        attendanceRecord: record,
      ));

      currentDate = currentDate.add(const Duration(days: 1));
    }

    setState(() {
      _dateWiseAttendance = dateList.reversed.toList(); // Most recent first
    });
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _dateWiseAttendance.where((d) => d.isPresent).length;
    final absentCount = _dateWiseAttendance.length - presentCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.employeeName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Days', _dateWiseAttendance.length.toString(), Colors.white),
                _buildStatItem('Present', presentCount.toString(), Colors.green.shade200),
                _buildStatItem('Absent', absentCount.toString(), Colors.red.shade200),
              ],
            ),
          ),
          // Date-wise List
          Expanded(
            child: _dateWiseAttendance.isEmpty
                ? const Center(child: Text('No attendance data available'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _dateWiseAttendance.length,
                    itemBuilder: (context, index) {
                      final dateAttendance = _dateWiseAttendance[index];
                      return _buildDateCard(dateAttendance);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildDateCard(DateAttendance dateAttendance) {
    final isPresent = dateAttendance.isPresent;
    final record = dateAttendance.attendanceRecord;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPresent ? Colors.green.shade200 : Colors.red.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPresent ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPresent ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Date and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(dateAttendance.date),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPresent ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPresent ? 'Present' : 'Absent',
                  style: TextStyle(
                    fontSize: 14,
                    color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isPresent && record != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.login,
                    'Check-in',
                    DateFormat('hh:mm a').format(record.checkInTime),
                    record.checkInLocation,
                  ),
                  if (record.checkOutTime != null) ...[
                    const SizedBox(height: 4),
                    _buildDetailRow(
                      Icons.logout,
                      'Check-out',
                      DateFormat('hh:mm a').format(record.checkOutTime!),
                      record.checkOutLocation,
                    ),
                  ],
                  if (record.hoursWorked != null && record.hoursWorked!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildDetailRow(
                      Icons.access_time,
                      'Hours',
                      record.hoursWorked!,
                      null,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, String? location) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        if (location != null && location.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '($location)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class DateAttendance {
  final DateTime date;
  final bool isPresent;
  final AttendanceRecord? attendanceRecord;

  DateAttendance({
    required this.date,
    required this.isPresent,
    this.attendanceRecord,
  });
}

