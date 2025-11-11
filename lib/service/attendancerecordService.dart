import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/AttendanceRecord.dart';
class AttendanceService {
  static const String baseUrl = 'https://realapp.cheenu.in/api/attendencelist/get';

  // Method to get all attendance records
  Future<AttendanceResponse> getAttendanceRecords() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return AttendanceResponse.fromJson(responseData);
      } else {
        throw Exception('Failed to load attendance records. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching attendance records: $e');
    }
  }
}