import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/add_visitor.dart';

class VisitorService {
  final String _baseUrl = 'https://realapp.cheenu.in/api/officevisitor/add';

  Future<bool> addVisitor(Visitor visitor) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(visitor.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print('Failed to add visitor: ${response.body}');
      return false;
    }
  }
}
