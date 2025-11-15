// services/associate_commission_list_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/associate_commission_list_model.dart';

class AssociateCommissionListService {
  static const String _baseUrl = 'https://realapp.cheenu.in/Api/ClientList/ClientListByContact';

  // Method to get all clients (without contact filter)
  Future<List<CommissionClient>> getAllClients() async {
    try {
      // Since the API requires a contact parameter, we'll use an empty or dummy contact
      // Alternatively, you might need to check if there's a different endpoint for all clients
      final response = await http.get(
        Uri.parse('$_baseUrl?Contact='), // Empty contact to get all or check API docs
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse.isEmpty) {
          return [];
        }

        return jsonResponse.map((json) => CommissionClient.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load clients: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Alternative: If the API doesn't work with empty contact, we can try multiple approaches
  Future<List<CommissionClient>> fetchAllClients() async {
    try {
      return await getAllClients();
    } catch (e) {
      throw Exception('Failed to fetch client list: $e');
    }
  }

  // Method to get clients by specific contact (if needed later)
  Future<List<CommissionClient>> getClientsByContact(String contact) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?Contact=$contact'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((json) => CommissionClient.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}