import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/add_visitor_list.dart';

class VisitorService {
  final String _baseUrl = 'https://realapp.cheenu.in/api/officevisitorlist/list';

  Future<List<Visitor>> fetchVisitors() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> visitorsJson = data['data'];
      return visitorsJson.map((json) => Visitor.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load visitors');
    }
  }
}
