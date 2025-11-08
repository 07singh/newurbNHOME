import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/associatate_new_login_model.dart';

class AssociateLoginService {
  static const String _baseUrl = "https://realapp.cheenu.in/api/associate/login";

  Future<AssociateLoginResponse> login({
    required String phone,
    required String password,
  }) async {
    final Uri url = Uri.parse("$_baseUrl?Phone=$phone&Password=$password");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AssociateLoginResponse.fromJson(data);
    } else {
      throw Exception("Failed to login. Status: ${response.statusCode}");
    }
  }
}
