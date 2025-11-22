import 'dart:convert';

import 'package:http/http.dart' as http;

import '../Model/add_associate_model.dart';

class AddAssociateService {
  static const String _endpoint = 'https://realapp.cheenu.in/api/associate/add';

  Future<AddAssociateResponse> submitAssociate(
      Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body.isEmpty ? {} : jsonDecode(response.body);
        return AddAssociateResponse.fromJson(body);
      }

      throw Exception(
        'Failed to submit associate (${response.statusCode}): ${response.body}',
      );
    } catch (e) {
      throw Exception('Unable to submit associate: $e');
    }
  }
}
