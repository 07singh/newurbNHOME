import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/associate_model.dart';

class AssociateService {
  final String _baseUrl = 'https://realapp.cheenu.in/api/AssociateList';

  Future<List<Associate>> fetchAssociates() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> associatesJson = data['data1'];
      return associatesJson.map((json) => Associate.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load associates');
    }
  }
}
