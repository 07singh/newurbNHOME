// services/change_password_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '/Model/associateForgetPassword_model.dart';

class ChangePasswordService {
  static const String baseUrl = 'https://realapp.cheenu.in/Api/AssociateChangePass';

  static Future<ChangePasswordResponse> changePassword({
    required String phone,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'phone': phone,
        'OldPassword': oldPassword,
        'NewPassword': newPassword,
        'ConfirmPassword': confirmPassword,
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ChangePasswordResponse.fromJson(responseData);
      } else {
        throw Exception('Failed to change password. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}