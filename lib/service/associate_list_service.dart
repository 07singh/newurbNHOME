import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/associate_list_model.dart';

class AssociateService {
  final String _baseUrl = 'https://realapp.cheenu.in/api/AssociateList/get';

  Future<AssociateList> fetchAssociateList({required String phone}) async {
    try {
      final uri = Uri.parse("$_baseUrl?phone=$phone");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return AssociateList.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load associates: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching associates: $e');
    }
  }
}
