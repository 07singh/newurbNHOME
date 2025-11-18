import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/ChangePasswordResponse.dart';

class ChangePasswordService {
  Future<ChangePasswordResponse> changePassword({
    required String phone,
    required String position,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    const String url =
        "https://realapp.cheenu.in/Api/StaffChangePassword";

    try {
      final response = await http.post(
        Uri.parse(url).replace(queryParameters: {
          "phone": phone,
          "position": position,
          "OldPassword": oldPassword,
          "NewPassword": newPassword,
          "ConfirmPassword": confirmPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChangePasswordResponse.fromJson(data);
      } else {
        throw Exception("Server Error ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed: $e");
    }
  }
}
