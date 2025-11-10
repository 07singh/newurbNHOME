import 'package:flutter/material.dart';
import '/service/attendance_manager.dart';
import 'attendenceCheckIn.dart';
import 'attendenceCheckOut.dart';

/// Routes to the appropriate attendance screen based on check-in status
class AttendanceRouter extends StatefulWidget {
  const AttendanceRouter({super.key});

  @override
  State<AttendanceRouter> createState() => _AttendanceRouterState();
}

class _AttendanceRouterState extends State<AttendanceRouter> {
  bool _isLoading = true;
  bool _isCheckedIn = false;
  Map<String, dynamic>? _checkInData;

  @override
  void initState() {
    super.initState();
    _checkAttendanceStatus();
  }

  Future<void> _checkAttendanceStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool checkedIn = await AttendanceManager.isCheckedIn();
      Map<String, dynamic>? data;
      
      if (checkedIn) {
        data = await AttendanceManager.getCheckInData();
        // If data is invalid or missing, treat as not checked in
        if (data == null || data['checkInTime'] == null) {
          checkedIn = false;
          await AttendanceManager.clearCheckIn();
        }
      }

      setState(() {
        _isCheckedIn = checkedIn;
        _checkInData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking attendance status: $e');
      setState(() {
        _isCheckedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF6B46FF)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: const Text(
            'Attendance',
            style: TextStyle(color: Color(0xFF6B46FF), fontWeight: FontWeight.w600),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF6B46FF)),
              SizedBox(height: 16),
              Text('Loading attendance status...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // If checked in, show check-out screen
    if (_isCheckedIn && _checkInData != null) {
      return AttendanceCheckOut(
        checkInTime: _checkInData!['checkInTime'] as DateTime,
        checkInPhoto: _checkInData!['checkInPhoto'],
        checkInPosition: _checkInData!['checkInPosition'],
        checkInAddress: _checkInData!['checkInAddress'] as String?,
      );
    }

    // Otherwise, show check-in screen
    return const AttendanceCheckIn();
  }
}

