import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '/Model/AttendanceRecord.dart';
import '/Model/attendance_summary.dart';

class AttendanceService {
  static const String baseUrl = 'https://realapp.cheenu.in/api/attendencelist/get';
  static const String approveUrl = 'https://realapp.cheenu.in/api/attendance/approve';
  static const String rejectUrl = 'https://realapp.cheenu.in/api/attendance/reject';
  static const String summaryUrl = 'https://realapp.cheenu.in/Api/AbsentStaffAttendenceRecord';

  Future<AttendanceResponse> getAttendanceRecords() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AttendanceResponse.fromJson(data);
      } else {
        throw Exception('Failed to load attendance records');
      }
    } catch (e) {
      throw Exception('Error fetching attendance: $e');
    }
  }

  Future<AttendanceSummary?> getAttendanceSummary() async {
    try {
      final response = await http.get(Uri.parse(summaryUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          return AttendanceSummary.fromJson(data);
        }
      } else {
        debugPrint('Summary fetch failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching attendance summary: $e');
    }
    return null;
  }

  /// ⭐ ACCEPT API (works on Attendance Id)
  Future<String> acceptAttendance(String attendanceId) async {
    final response = await http.post(
      Uri.parse(approveUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Id': attendanceId}),
    );

    debugPrint('Approve response (${response.statusCode}): ${response.body}');

    if (response.statusCode == 200) {
      return "Attendance Accepted";
    } else {
      return "Failed to Accept (${response.statusCode}): ${response.body}";
    }
  }

  /// ⭐ REJECT API (works on Attendance Id)
  Future<String> rejectAttendance(String attendanceId) async {
    final response = await http.post(
      Uri.parse(rejectUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Id': attendanceId}),
    );

    debugPrint('Reject response (${response.statusCode}): ${response.body}');

    if (response.statusCode == 200) {
      return "Attendance Rejected";
    } else {
      return "Failed to Reject (${response.statusCode}): ${response.body}";
    }
  }
}
