import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/add_booking.dart';

class BookingService {
  static const String _baseUrl = "https://realapp.cheenu.in/api/booking/add";

  static Future<Map<String, dynamic>> addBooking(Booking booking) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(booking.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "Error",
          "message": "Failed with status code ${response.statusCode}"
        };
      }
    } catch (e) {
      return {
        "status": "Error",
        "message": e.toString(),
      };
    }
  }
}
