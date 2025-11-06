import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/associate_profile_model.dart';

Future<ProfileAssociate> fetchAssociateProfile(String phone) async {
  final String baseUrl = 'https://realapp.cheenu.in/Api/AssociateProfile';
  final Uri url = Uri.parse('$baseUrl?phone=$phone');

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return ProfileAssociate.fromJson(jsonData);
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching profile: $e');
  }
}