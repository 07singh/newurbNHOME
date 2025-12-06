import 'package:flutter/foundation.dart';
import '/service/auth_manager.dart';
import '/service/device_token_service.dart';
import '/service/notification_service.dart';
import '/service/activity_notification_helper.dart';

/// Helper class for debugging notification issues
class NotificationDebugHelper {
  /// Print complete notification system status
  static Future<void> printSystemStatus() async {
    print('\n🔍 ========== NOTIFICATION SYSTEM STATUS ==========\n');

    // 1. Check user session
    print('1️⃣ USER SESSION:');
    final session = await AuthManager.getCurrentSession();
    if (session != null) {
      print('   ✅ User logged in');
      print('   UserId: ${session.userId}');
      print('   UserName: ${session.userName}');
      print('   LoginType: ${session.loginType}');
      print('   Position: ${session.position}');
      print('   UserRole: ${session.userRole}');
      
      // Check if HR/Director
      final role = (session.position ?? session.loginType ?? session.userRole ?? '').toLowerCase();
      if (role.contains('hr') || role.contains('director')) {
        print('   ✅ User is HR/Director - will receive notifications');
      } else {
        print('   ⚠️ User is NOT HR/Director - will NOT receive notifications');
      }
    } else {
      print('   ❌ No user session found');
    }

    // 2. Check FCM token
    print('\n2️⃣ FCM TOKEN:');
    final notificationService = NotificationService();
    final fcmToken = notificationService.fcmToken;
    if (fcmToken != null) {
      print('   ✅ FCM Token exists');
      print('   Token (first 30 chars): ${fcmToken.substring(0, fcmToken.length > 30 ? 30 : fcmToken.length)}...');
      
      // Try to save token
      print('\n   📤 Attempting to save token to backend...');
      final saved = await DeviceTokenService.saveDeviceToken(
        token: fcmToken,
        deviceType: 'Android',
      );
      if (saved) {
        print('   ✅ Token saved to backend successfully');
      } else {
        print('   ❌ Failed to save token to backend');
      }
    } else {
      print('   ❌ No FCM token available');
      print('   💡 Initialize notification service first');
    }

    // 3. Test notification
    print('\n3️⃣ TEST NOTIFICATION:');
    if (session != null) {
      print('   📤 Sending test notification...');
      final sent = await ActivityNotificationHelper.notifyHRAndDirector(
        actionType: 'test',
        message: 'This is a test notification from debug helper',
        userId: int.tryParse(session.userId ?? ''),
      );
      if (sent) {
        print('   ✅ Test notification sent successfully');
        print('   💡 Check HR/Director phones for notification');
      } else {
        print('   ❌ Failed to send test notification');
        print('   💡 Check backend API endpoint: /api/notification/send');
      }
    } else {
      print('   ⚠️ Cannot send test - no user session');
    }

    print('\n🔍 ================================================\n');
  }

  /// Check if current user can receive notifications
  static Future<bool> canReceiveNotifications() async {
    final session = await AuthManager.getCurrentSession();
    if (session == null) return false;

    final role = (session.position ?? session.loginType ?? session.userRole ?? '').toLowerCase();
    return role.contains('hr') || role.contains('director');
  }

  /// Print token save status
  static Future<void> checkTokenSave() async {
    print('\n📱 Checking Token Save Status...\n');
    
    final notificationService = NotificationService();
    final fcmToken = notificationService.fcmToken;
    
    if (fcmToken == null) {
      print('❌ No FCM token available');
      return;
    }

    print('FCM Token: ${fcmToken.substring(0, 30)}...');
    
    final session = await AuthManager.getCurrentSession();
    if (session == null) {
      print('❌ No user session - cannot save token');
      return;
    }

    print('User: ${session.userName}');
    print('Role: ${session.position ?? session.loginType ?? session.userRole}');
    print('\nSaving token...');

    final saved = await DeviceTokenService.saveDeviceToken(
      token: fcmToken,
      deviceType: 'Android',
    );

    if (saved) {
      print('✅ Token saved successfully!');
      print('💡 Check database: SELECT * FROM tbl_DeviceTokens WHERE UserId = ${session.userId}');
    } else {
      print('❌ Failed to save token');
      print('💡 Check backend API: /api/device/save');
    }
  }

  /// Test notification sending
  static Future<void> testNotification() async {
    print('\n🧪 Testing Notification...\n');

    final sent = await ActivityNotificationHelper.notifyHRAndDirector(
      actionType: 'test',
      message: 'Test notification from debug helper',
      userId: null,
    );

    if (sent) {
      print('✅ Notification request sent to backend');
      print('💡 Check HR/Director phones for notification');
      print('💡 If not received, check:');
      print('   1. Backend API is working');
      print('   2. Tokens exist in database');
      print('   3. FCM service is configured');
    } else {
      print('❌ Failed to send notification');
      print('💡 Check backend API endpoint: /api/notification/send');
    }
  }
}




