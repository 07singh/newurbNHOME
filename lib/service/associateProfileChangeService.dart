// service/associate_profile_change_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../Model/associate_profile_change_model.dart';

class AssociateProfileChangeService {
  static const String _baseUrl = 'https://realapp.cheenu.in/api/AssoChangeProfile';

  // Upload image file and get filename from server
  Future<String?> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'ProfilePic',
          imageFile.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      var response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (jsonResponse['Status'] == 'Success') {
        return jsonResponse['FileName']; // Assuming API returns filename
      }
      return null;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Update profile with image filename
  Future<AssociateProfileChangeResponse> updateProfile(
      AssociateProfileChangeRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return AssociateProfileChangeResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Combined method to handle both image upload and profile update
  Future<AssociateProfileChangeResponse> changeProfileImage(
      String phone, File imageFile) async {
    try {
      // First upload the image
      var uploadRequest = http.MultipartRequest('POST', Uri.parse(_baseUrl));

      uploadRequest.fields['Phone'] = phone;
      uploadRequest.files.add(
        await http.MultipartFile.fromPath(
          'ProfilePic',
          imageFile.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      var response = await uploadRequest.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      return AssociateProfileChangeResponse.fromJson(jsonResponse);
    } catch (e) {
      throw Exception('Failed to change profile image: $e');
    }
  }
}