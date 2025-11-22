import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/add_history_screen.dart';

class DayBookHistoryService {
  static const String url = 'https://realapp.cheenu.in/Api/AddDayBookHistory';

  static Future<List<DayBookHistory>> fetchHistory() async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData['data1'] == null) {
          return [];
        }

        final List<dynamic> dataList = jsonData['data1'];

        return dataList
            .map((item) => DayBookHistory.fromJson(item))
            .toList();
      } else {
        throw Exception(
            'Failed to load DayBook history. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception("Error fetching DayBook history: $e");
    }
  }
}
