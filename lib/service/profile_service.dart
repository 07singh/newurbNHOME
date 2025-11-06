// lib/services/profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/profile_model.dart';

class ProfileService {
  final String baseUrl = 'https://realapp.cheenu.in/Api';

  /// Fetch profile by phone and position.
  /// Returns ProfileResponse on success, otherwise throws an exception.
  Future<ProfileResponse> fetchProfile({required String phone, required String position}) async {
    final uri = Uri.parse('$baseUrl/Profile?Phone=$phone&position=$position');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(res.body) as Map<String, dynamic>;
      // You can check body['message'] if needed
      return ProfileResponse.fromJson(body);
    } else {
      throw Exception('Failed to fetch profile. Status: ${res.statusCode}');
    }
  }
}
