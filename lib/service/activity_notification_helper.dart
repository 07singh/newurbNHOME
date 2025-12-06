import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Helper service to trigger notifications to HR/Director when Employee/Associate performs activities
/// This service calls the backend API which handles FCM notification sending
class ActivityNotificationHelper {
  static const String _baseUrl = 'https://realapp.cheenu.in/api';

  /// Send notification to HR/Director when an activity is performed
  /// 
  /// [actionType] - Type of activity: 'visitor_added', 'payment_added', 'attendance_recorded', etc.
  /// [message] - Notification message to display
  /// [userId] - Optional user ID who performed the activity
  /// 
  /// Returns true if notification request was sent successfully
  static Future<bool> notifyHRAndDirector({
    required String actionType,
    required String message,
    int? userId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/notification/send');
      
      final requestBody = {
        'actionType': actionType,
        'message': message,
        if (userId != null) 'userId': userId,
      };

      if (kDebugMode) {
        print('📤 Sending activity notification:');
        print('   Action: $actionType');
        print('   Message: $message');
        print('   UserId: ${userId ?? "N/A"}');
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
          try {
            final responseData = json.decode(response.body);
            final sentCount = responseData['sentCount'] ?? 0;
            print('✅ Notification sent successfully to $sentCount device(s)');
          } catch (e) {
            print('✅ Notification sent successfully');
          }
        }
        return true;
      } else {
        if (kDebugMode) {
          print('⚠️ Failed to send notification: ${response.statusCode}');
          print('   Response: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending activity notification: $e');
      }
      // Don't throw - notification failure shouldn't break the app
      return false;
    }
  }

  /// Convenience method for visitor added
  static Future<bool> notifyVisitorAdded({
    required String visitorName,
    required String mobileNo,
    required String purpose,
    int? userId,
  }) {
    return notifyHRAndDirector(
      actionType: 'visitor_added',
      message: '$visitorName ($mobileNo) has arrived. Purpose: $purpose',
      userId: userId,
    );
  }

  /// Convenience method for payment added
  static Future<bool> notifyPaymentAdded({
    required double amount,
    required String paymentMethod,
    required int bookingId,
    int? userId,
  }) {
    return notifyHRAndDirector(
      actionType: 'payment_added',
      message: 'Payment of ₹${amount.toStringAsFixed(2)} added via $paymentMethod for Booking #$bookingId',
      userId: userId,
    );
  }

  /// Convenience method for attendance recorded
  static Future<bool> notifyAttendanceRecorded({
    required String employeeName,
    required String action, // 'CheckIn', 'CheckOut', 'Both'
    required String location,
    int? userId,
  }) {
    String actionType = action == 'CheckIn' 
        ? 'Check-In Recorded' 
        : action == 'CheckOut' 
            ? 'Check-Out Recorded' 
            : 'Attendance Recorded';
    
    return notifyHRAndDirector(
      actionType: 'attendance_recorded',
      message: '$employeeName - $actionType at $location',
      userId: userId,
    );
  }

  /// Convenience method for follow-up added
  static Future<bool> notifyFollowUpAdded({
    required String clientName,
    required String projectName,
    int? userId,
  }) {
    return notifyHRAndDirector(
      actionType: 'followup_added',
      message: 'New follow-up added for $clientName - Project: $projectName',
      userId: userId,
    );
  }

  /// Convenience method for booking added
  static Future<bool> notifyBookingAdded({
    required String customerName,
    required String plotNumber,
    required String projectName,
    int? userId,
  }) {
    return notifyHRAndDirector(
      actionType: 'booking_added',
      message: 'New booking: $customerName - Plot $plotNumber in $projectName',
      userId: userId,
    );
  }
}





