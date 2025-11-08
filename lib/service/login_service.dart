import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/login_model.dart';

class LoginService {
  final String baseUrl = "https://realapp.cheenu.in";

  Future<LoginApi?> loginUser(String mobile, String password, String position) async {
    try {
      final url =
          "$baseUrl/api/staff/login?mobile=$mobile&password=$password&position=$position";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LoginApi.fromJson(data);
      } else {
        return LoginApi(
          statuscode: "Error",
          message: "Server returned ${response.statusCode}",
        );
      }
    } catch (e) {
      return LoginApi(
        statuscode: "Error",
        message: "Something went wrong: $e",
      );
    }
  }
}
