import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for sending notifications through backend API
/// Backend will filter and send notifications only to HR/Director devices
class BackendNotificationService {
  static const String _baseUrl = 'https://realapp.cheenu.in/api';

  /// Send notification to backend
  /// Backend will automatically filter and send to HR/Director devices only
  /// 
  /// [title] - Notification title
  /// [body] - Notification body/message
  /// [data] - Additional data payload (optional)
  /// [notificationType] - Type of notification (visitor_added, payment_added, attendance_recorded)
  /// 
  /// Returns true if request sent successfully, false otherwise
  static Future<bool> sendNotificationToBackend({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    required String notificationType,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Notification/Send');
      
      final requestBody = {
        'Title': title,
        'Body': body,
        'NotificationType': notificationType,
        'Data': data ?? {},
      };

      if (kDebugMode) {
        print('📤 Sending notification to backend:');
        print('   URL: $url');
        print('   Title: $title');
        print('   Body: $body');
        print('   Type: $notificationType');
        print('   Data: $data');
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            print('⚠️ Notification send timeout');
          }
          return http.Response('Timeout', 408);
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Notification sent to backend successfully');
          try {
            final responseData = json.decode(response.body);
            print('   Response: $responseData');
          } catch (e) {
            print('   Response: ${response.body}');
          }
        }
        return true;
      } else if (response.statusCode == 404) {
        // API endpoint doesn't exist - that's okay, backend will handle from event APIs
        if (kDebugMode) {
          print('ℹ️ Notification API endpoint not found (404) - backend will handle notifications from event APIs');
        }
        return false;
      } else {
        if (kDebugMode) {
          print('⚠️ Failed to send notification to backend: ${response.statusCode}');
          print('   Response: ${response.body}');
          print('   ℹ️ Backend will handle notifications from event APIs');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending notification to backend: $e');
      }
      return false;
    }
  }
}

