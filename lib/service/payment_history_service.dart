// lib/service/payment_history_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/payment_history_model.dart';

class PaymentHistoryService {
  static const String baseUrl = 'https://realapp.cheenu.in';
  static const Duration _timeout = Duration(seconds: 30);

  /// Fetches payment history from the API
  Future<List<Payment>> fetchPaymentHistory() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/Api/AddPaymentHistory'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        final apiResponse = PaymentHistoryResponse.fromJson(jsonResponse);
        
        if (apiResponse.status == 'Success') {
          return apiResponse.data;
        } else {
          throw Exception(apiResponse.message.isNotEmpty 
              ? apiResponse.message 
              : 'Failed to fetch payment history');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } on http.ClientException {
      throw Exception('Network connection failed. Please check your internet.');
    } on FormatException {
      throw Exception('Invalid response format from server');
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }
}