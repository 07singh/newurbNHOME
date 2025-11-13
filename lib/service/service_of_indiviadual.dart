// services/booking_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/modelofindividual.dart';

class BookingService {
  static const String _base = 'https://realapp.cheenu.in/Api';

  /// Fetch bookings for a phone number.
  /// Throws an Exception on network / parsing errors.
  Future<List<Booking>> fetchBookingsForPhone(String phone) async {
    final url = Uri.parse('$_base/MyBookingIndividualRecord?phone=$phone');

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load bookings (status ${response.statusCode})');
    }

    final Map<String, dynamic> body = json.decode(response.body) as Map<String, dynamic>;
    // Optional: check message or status if API sends it
    // parse
    final myResp = MyBookingResponse.fromJson(body);
    return myResp.data;
  }
}