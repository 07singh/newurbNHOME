import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/day_book_model.dart';

class DayBookService {
  static const String baseUrl = "https://realapp.cheenu.in/api/AddDayBook/add";

  /// Add a new DayBook entry
  static Future<Map<String, dynamic>> addDayBook(DayBook dayBook) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(dayBook.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "message": data['message'] ?? 'Data added successfully',
          "status": data['status'] ?? 'Success',
        };
      } else {
        return {
          "success": false,
          "message": 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": 'Exception: $e',
      };
    }
  }
}
