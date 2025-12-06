import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/totalBookingList_Model.dart';

class TotalBookingService {
  static const String baseUrl =
      "https://realapp.cheenu.in/Api/GetBookingwiseCommissionHistory";

  static Future<TotalBookingListModel?> getBookingHistory(String phone) async {
    try {
      final url = Uri.parse("$baseUrl?dealerPhone=$phone");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return TotalBookingListModel.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching booking list: $e");
      return null;
    }
  }
}