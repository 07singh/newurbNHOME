import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/add_visitor.dart';
import '/service/activity_notification_helper.dart';
import '/service/auth_manager.dart';

class VisitorService {
  final String _baseUrl = 'https://realapp.cheenu.in/api/officevisitor/add';

  Future<bool> addVisitor(Visitor visitor) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(visitor.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Get current user ID for notification
      final session = await AuthManager.getCurrentSession();
      final userId = session != null ? int.tryParse(session.userId ?? '') : null;

      // Send notification to HR/Director via backend API
      await ActivityNotificationHelper.notifyVisitorAdded(
        visitorName: visitor.name,
        mobileNo: visitor.mobileNo,
        purpose: visitor.purpose,
        userId: userId,
      );
      
      return true;
    } else {
      print('Failed to add visitor: ${response.body}');
      return false;
    }
  }
}
