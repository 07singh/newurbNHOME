import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/associate_model.dart';

class AssociateService {
  Future<AssociateLogin?> login(String phone, String password) async {
    try {
      final url = Uri.parse(
          'https://realapp.cheenu.in/Api/AssociateLogin?phone=$phone&password=$password'
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AssociateLogin.fromJson(jsonData);
      } else {
        print("Failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }
}
