import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/associate_list_model.dart'; // Adjust path to your model file

class AssociateService {
  final String _baseUrl = 'https://realapp.cheenu.in/Api/AssociateList';
  final Duration _timeoutDuration = Duration(seconds: 30); // Request timeout

  Future<AssociateList> fetchAssociateList({
    required String phone,
    String? authToken,
    Map<String, String>? additionalQueryParams,
  }) async {
    try {
      // Build query parameters
      final queryParams = {'phone': phone, ...?additionalQueryParams};
      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

      // Set headers
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      // Make HTTP GET request with timeout
      final response = await http.get(uri, headers: headers).timeout(
        _timeoutDuration,
        onTimeout: () => throw Exception('Request timed out after ${_timeoutDuration.inSeconds} seconds'),
      );

      // Handle response
      switch (response.statusCode) {
        case 200:
          return AssociateList.fromJson(jsonDecode(response.body));
        case 401:
          throw Exception('Unauthorized: Invalid or missing authentication token');
        case 404:
          throw Exception('API endpoint not found');
        case 500:
          throw Exception('Server error: Please try again later');
        default:
          throw Exception('Failed to load associates: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching associates: ${e.toString()}');
    }
  }
}