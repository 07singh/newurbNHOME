import 'dart:convert';
import 'package:http/http.dart' as http;

class BookingService {
  final String baseUrl = "https://realapp.cheenu.in/api/acceptbooking/add";

  Future<Map<String, dynamic>?> acceptBooking({
    required int id,
    required double totalAmount,
    required double receivingAmount,
    required String paidThrough,
    String? screenshotBase64,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        "id": id,
        "Total_Amount": totalAmount,
        "Receiving_Amount": receivingAmount,
        "Paid_Through": paidThrough,
        "Screenshot": screenshotBase64 ?? "",
      };

      print("📤 Sending payload => $payload");

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("✅ Server response => ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // 🧠 check if it's a map or not
        if (decoded is Map<String, dynamic>) {
          final msg = decoded["message"]?.toString().toLowerCase() ?? "";
          if (msg.contains("success")) {
            return decoded; // ✅ return full response to UI
          } else {
            print("⚠️ API returned failure: ${decoded['message']}");
          }
        } else {
          print("⚠️ Unexpected response type: ${decoded.runtimeType}");
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
      }

      return null;
    } catch (e) {
      print("❌ Exception in acceptBooking: $e");
      return null;
    }
  }
}
