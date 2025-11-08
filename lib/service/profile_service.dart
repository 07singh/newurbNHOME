import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/profile_model.dart';

class StaffProfileService {
  final String _baseUrl = "https://realapp.cheenu.in/Api/StaffProfile";

  Future<StaffProfileResponse> fetchProfile({
    required String phone,
    required String position,
  }) async {
    final uri = Uri.parse("$_baseUrl?Phone=$phone&Position=$position");

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return StaffProfileResponse.fromJson(jsonResponse);
      } else {
        throw Exception("Failed to fetch profile. Status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching staff profile: $e");
    }
  }
}
