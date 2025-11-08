import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/associate_model.dart';

class AssociateService {
  final String baseUrl = "https://realapp.cheenu.in";

  Future<LoginResponse?> login({
    required String phone,
    required String password,
  }) async {
    try {
      final url =
          "$baseUrl/api/associate/login?Phone=$phone&Password=$password";
      print("🔗 Calling GET: $url");

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("✅ Response: $data");
        return LoginResponse.fromJson(data);
      } else {
        print("❌ Status code: ${response.statusCode}");
        return LoginResponse(
          message: "Server returned ${response.statusCode}",
          status: "Error",
        );
      }
    } catch (e) {
      print("⚠️ Exception: $e");
      return LoginResponse(
        message: "Something went wrong. Please try again.",
        status: "Error",
      );
    }
  }
}
