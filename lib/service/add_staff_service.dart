import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/add_staff.dart';

class AddStaffService {
  final String baseUrl = "https://realapp.cheenu.in/api/staff/add";

  Future<AddStaffResponse> addStaff(AddStaffRequest request) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return AddStaffResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add staff: ${response.body}');
    }
  }
}
