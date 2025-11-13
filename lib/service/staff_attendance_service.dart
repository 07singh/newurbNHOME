import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/staff_attendance_model.dart';

class StaffAttendanceService {
  static const String _baseUrl =
      'https://realapp.cheenu.in/Api/StaffAttendenceIndividualRecord';

  Future<List<StaffAttendance>> fetchAttendanceByPhone(String phone) async {
    final Uri url = Uri.parse('$_baseUrl?phone=$phone');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      if (jsonResponse['message'] == 'Success' && jsonResponse['data'] != null) {
        final List<dynamic> data = jsonResponse['data'];
        return data.map((e) => StaffAttendance.fromJson(e)).toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load attendance data');
    }
  }
}