import 'package:flutter/material.dart';
import '/Model/staff_attendance_model.dart';
import '/service/staff_attendance_service.dart';

class StaffAttendanceScreen extends StatefulWidget {
  final String phone;
  const StaffAttendanceScreen({super.key, required this.phone});

  @override
  State<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends State<StaffAttendanceScreen> {
  late Future<List<StaffAttendance>> _futureAttendance;
  final StaffAttendanceService _service = StaffAttendanceService();

  @override
  void initState() {
    super.initState();
    _futureAttendance = _service.fetchAttendanceByPhone(widget.phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "My Attendance",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF871BBF),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: FutureBuilder<List<StaffAttendance>>(
        future: _futureAttendance,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return const Center(
              child: Text(
                "No attendance records found",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: records.length,
            itemBuilder: (context, index) {
              return _buildAttendanceCard(records[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildAttendanceCard(StaffAttendance record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                record.employeeName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: record.status.toLowerCase() == "present"
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.status.isEmpty ? "Unknown" : record.status,
                  style: TextStyle(
                    color: record.status.toLowerCase() == "present"
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow("Employee Type", record.employeeType),
          _infoRow("Check In", _formatTime(record.checkInTime)),
          _infoRow("Check Out", _formatTime(record.checkOutTime)),
          _infoRow("Location In", record.checkInLocation),
          _infoRow("Location Out", record.checkOutLocation),
          _infoRow("Hours Worked", record.hoursWorked),
          _infoRow("Action", record.action),
          const SizedBox(height: 10),
          Row(
            children: [
              if (record.checkInImage.isNotEmpty)
                Expanded(
                  child: _imageBox(
                      "Check-In",
                      "https://realapp.cheenu.in${record.checkInImage}"),
                ),
              const SizedBox(width: 10),
              if (record.checkOutImage.isNotEmpty)
                Expanded(
                  child: _imageBox(
                      "Check-Out",
                      "https://realapp.cheenu.in${record.checkOutImage}"),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "N/A" : value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timeString) {
    if (timeString.isEmpty) return "N/A";
    try {
      // If the time string is already formatted, return as is
      if (timeString.contains(":")) {
        return timeString;
      }
      // Otherwise try to parse and format
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  Widget _imageBox(String label, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) =>
                  Dialog(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBar(
                          title: Text(label),
                          backgroundColor: const Color(0xFF871BBF),
                          iconTheme: const IconThemeData(color: Colors.white),
                        ),
                        Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text("Failed to load image"),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
            );
          },
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

}