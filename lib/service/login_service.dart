import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/login_model.dart';

class LoginService {
  // Login user with mobile, password, and position (TL/Sales)
  Future<LoginApi?> loginUser(String mobile, String password, String position) async {
    if (mobile.isEmpty || password.isEmpty || position.isEmpty) {
      print("⚠️ Mobile, password, or position is empty");
      return null;
    }

    // ✅ Build GET URL with query parameters
    final Uri url = Uri.parse(
      "https://realapp.cheenu.in/Api/Login?mobile=$mobile&password=$password&position=$position",
    );

    try {
      print("🔹 Sending login request to: $url");

      // ✅ Simple GET request, no headers
      final response = await http.get(url);

      print("🔹 Response status: ${response.statusCode}");
      print("🔹 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData.isNotEmpty) {
          final loginData = LoginApi.fromJson(jsonData);
          return loginData;
        } else {
          print("⚠️ Empty response body");
          return null;
        }
      } else if (response.statusCode == 401) {
        print("❌ Unauthorized: Invalid credentials or access denied");
      } else if (response.statusCode == 404) {
        print("❌ Not found: Check API URL");
      } else {
        print("❌ Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("🔥 Exception in loginUser: $e");
    }

    return null;
  }
}
