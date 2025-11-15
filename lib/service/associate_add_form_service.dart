// service/associate_add_form_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/associate_add_client_form_model.dart';

class AssociateAddFormService {
  static const String _baseUrl = 'https://realapp.cheenu.in/Api/AddClient/AddClients/';

  Future<AddClientResponse> addClient(AddClientRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return AddClientResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return AddClientResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to add client: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Validation method
  String? validateForm({
    required String clientName,
    required String projectName,
    required String contactNo,
    required String note,
  }) {
    if (clientName.isEmpty) {
      return 'Please enter client name';
    }
    if (projectName.isEmpty) {
      return 'Please select a project';
    }
    if (contactNo.isEmpty) {
      return 'Please enter contact number';
    }
    if (contactNo.length != 10) {
      return 'Contact number must be 10 digits';
    }
    if (note.isEmpty) {
      return 'Please enter a note';
    }
    return null;
  }
}