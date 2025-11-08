import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/add_staff_list.dart'; // import model

class StaffService {
  final String apiUrl = "https://realapp.cheenu.in/api/staff/list";

  Future<StaffListResponse> fetchStaffList() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return StaffListResponse.fromJson(data);
    } else {
      throw Exception("Failed to load staff list: ${response.statusCode}");
    }
  }
}
