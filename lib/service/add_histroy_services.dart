import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/add_history_screen.dart';

class DayBookHistoryService {
  static const String url = 'https://realapp.cheenu.in/Api/AddDayBookHistory';

  static Future<List<DayBookHistory>> fetchHistory() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final List<dynamic> dataList = jsonData['data1'] ?? [];

      List<DayBookHistory> history = dataList
          .map((entry) => DayBookHistory.fromJson(entry))
          .toList();

      return history;
    } else {
      throw Exception('Failed to load DayBook history');
    }
  }
}
