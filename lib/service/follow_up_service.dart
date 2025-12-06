import 'dart:convert';

import 'package:http/http.dart' as http;

import '/Model/follow_up_summary_model.dart';

class FollowUpService {
  static const String _summaryUrl =
      'https://realapp.cheenu.in/Api/GetFollowUpSummaryList/list';

  /// Fetches the global follow-up summary list.
  /// Used by both Director and HR follow-up pages so they show the same data.
  static Future<List<FollowUpSummary>> fetchFollowUpSummaryList() async {
    try {
      final response = await http.get(Uri.parse(_summaryUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final summaryResponse = FollowUpSummaryResponse.fromJson(jsonData);
        return summaryResponse.data;
      } else {
        throw Exception(
          'Failed to load follow-up summary. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching follow-up summary: $e');
    }
  }
}


