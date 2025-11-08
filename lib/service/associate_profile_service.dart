import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/associate_profile_model.dart';

class AssociateProfileService {
  Future<AssociateProfile?> fetchProfile(String phone) async {
    final url = Uri.parse('https://realapp.cheenu.in/Api/AssociateProfile?Phone=$phone');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['message'] == 'Success' && data['data'] != null) {
        return AssociateProfile.fromJson(data['data']);
      }
    }
    return null;
  }
}
