import 'dart:convert';
import 'package:http/http.dart' as http;
import '/service/auth_manager.dart';

/// Service for saving and managing device tokens in backend
class DeviceTokenService {
  static const String _baseUrl = 'https://realapp.cheenu.in/api';
  
  /// Save device token to backend
  /// 
  /// [token] - FCM token from Firebase
  /// [deviceType] - Device type (e.g., "Android", "iOS")
  /// 
  /// Returns true if saved successfully, false otherwise
  static Future<bool> saveDeviceToken({
    required String token,
    String deviceType = 'Android',
  }) async {
    try {
      // Get current user session to get UserId and UserRole
      final session = await AuthManager.getCurrentSession();
      if (session == null || session.userId == null) {
        print('⚠️ Cannot save device token: No user session found');
        return false;
      }

      final userId = int.tryParse(session.userId ?? '');
      if (userId == null) {
        print('⚠️ Cannot save device token: Invalid UserId');
        return false;
      }

      // Get UserRole from session (priority: position > loginType > userRole)
      String userRole = session.position ?? 
                       session.loginType ?? 
                       session.userRole ?? 
                       'Employee';
      
      // Normalize role to match backend expectations (HR, Director, Employee, Associate)
      final roleLower = userRole.toLowerCase().trim();
      if (roleLower.contains('hr')) {
        userRole = 'HR';
      } else if (roleLower.contains('director') || roleLower.contains('admin')) {
        userRole = 'Director';
      } else if (roleLower.contains('associate')) {
        userRole = 'Associate';
      } else {
        userRole = 'Employee';
      }

      final url = Uri.parse('$_baseUrl/device/save');
      
      final body = {
        'UserId': userId,
        'Token': token,
        'DeviceType': deviceType,
        'UserRole': userRole,  // Added UserRole field
      };

      print('📤 Saving device token to backend:');
      print('   URL: $url');
      print('   UserId: $userId');
      print('   Token: ${token.substring(0, 20)}...');
      print('   DeviceType: $deviceType');
      print('   UserRole: $userRole');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Device token save timeout');
          return http.Response('Timeout', 408);
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Device token saved successfully');
        try {
          final responseData = json.decode(response.body);
          print('   Response: $responseData');
        } catch (e) {
          // Response might not be JSON, that's okay
          print('   Response: ${response.body}');
        }
        return true;
      } else {
        print('❌ Failed to save device token: ${response.statusCode}');
        print('   Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error saving device token: $e');
      return false;
    }
  }

  /// Update device token (if token already exists)
  /// 
  /// [token] - New FCM token
  /// [deviceType] - Device type
  static Future<bool> updateDeviceToken({
    required String token,
    String deviceType = 'Android',
  }) async {
    // For now, we'll use the same save endpoint
    // Backend should handle update if token exists
    return await saveDeviceToken(token: token, deviceType: deviceType);
  }

  /// Delete device token (on logout)
  /// 
  /// [token] - FCM token to delete
  static Future<bool> deleteDeviceToken({
    required String token,
  }) async {
    try {
      final session = await AuthManager.getCurrentSession();
      if (session == null || session.userId == null) {
        return false;
      }

      final userId = int.tryParse(session.userId ?? '');
      if (userId == null) {
        return false;
      }

      final url = Uri.parse('$_baseUrl/DeviceToken/Delete');
      
      final body = {
        'UserId': userId,
        'Token': token,
      };

      print('🗑️ Deleting device token from backend');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Device token deleted successfully');
        return true;
      } else {
        print('⚠️ Failed to delete device token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting device token: $e');
      return false;
    }
  }
}

