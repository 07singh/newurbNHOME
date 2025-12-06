import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import '/service/auth_manager.dart';
import '/service/device_token_service.dart';
import '/service/backend_notification_service.dart';

/// Service for handling push notifications using Firebase Cloud Messaging
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ User granted provisional notification permission');
      } else {
        print('❌ User declined notification permission');
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $_fcmToken');

      // Save token to backend
      if (_fcmToken != null) {
        await _saveTokenToBackend(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        print('🔄 FCM Token refreshed: $newToken');
        // Save updated token to backend
        await _saveTokenToBackend(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }

      _initialized = true;
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  /// Initialize local notifications for Android
  Future<void> _initializeLocalNotifications() async {
    try {
      print('🔧 Initializing local notifications...');
      
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      final initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        print('✅ Local notifications initialized');
      } else {
        print('⚠️ Local notifications initialization returned false');
      }

      // Create notification channel for Android
      if (Platform.isAndroid) {
        print('📱 Creating Android notification channel...');
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        final androidImplementation = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation != null) {
          await androidImplementation.createNotificationChannel(channel);
          print('✅ Android notification channel created: high_importance_channel');
        } else {
          print('⚠️ Android implementation not found');
        }
      }
    } catch (e) {
      print('❌ Error initializing local notifications: $e');
      rethrow;
    }
  }

  /// Handle foreground messages (when app is open)
  /// Backend already filters and sends only to HR/Director, so we can show notification directly
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Foreground message received: ${message.messageId}');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');
    
    // Backend already filters notifications to HR/Director only
    // So we can show notification directly without checking role again
    await _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      data: message.data,
    );
  }

  /// Handle background messages (when app is in background or terminated)
  void _handleBackgroundMessage(RemoteMessage message) {
    print('📨 Background message received: ${message.messageId}');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');
    
    // Handle navigation or other actions based on notification data
    // You can add navigation logic here based on message.data
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('🔔 Attempting to show local notification:');
      print('   Title: $title');
      print('   Body: $body');
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: data != null ? data.toString() : null,
      );
      
      print('   ✅ Notification displayed with ID: $notificationId');
    } catch (e) {
      print('   ❌ Error displaying notification: $e');
      rethrow;
    }
  }

  /// Test notification - for debugging purposes
  /// Shows a local notification to test if notification system is working
  Future<void> testNotification() async {
    print('🧪 Testing notification...');
    
    // Check if user is HR or Director
    final isAuthorized = await _isHROrDirector();
    
    if (!isAuthorized) {
      print('⚠️ Test notification: User is not HR or Director');
      print('   ℹ️ Backend sends notifications only to HR/Director devices');
      return;
    }
    
    // Show local test notification
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'Notification system is working! Backend will send notifications to HR/Director only.',
      data: {'type': 'test'},
    );
    
    print('✅ Test notification displayed');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // Handle navigation based on notification payload
  }

  /// Check if current user is HR or Director
  Future<bool> _isHROrDirector() async {
    try {
      final session = await AuthManager.getCurrentSession();
      if (session == null) {
        print('⚠️ No user session found - notification will not be sent');
        return false;
      }

      // Debug: Print all session details
      print('🔍 Checking user role for notifications:');
      print('   loginType: ${session.loginType}');
      print('   position: ${session.position}');
      print('   userRole: ${session.userRole}');

      // Check loginType (case-insensitive)
      final loginType = session.loginType?.toLowerCase().trim() ?? '';
      if (loginType == 'hr' || loginType == 'director') {
        print('✅ User authorized via loginType: $loginType');
        return true;
      }

      // Check position (case-insensitive)
      final position = session.position?.toLowerCase().trim() ?? '';
      if (position == 'hr' || position == 'director') {
        print('✅ User authorized via position: $position');
        return true;
      }

      // Check userRole (case-insensitive)
      final userRole = session.userRole?.toLowerCase().trim() ?? '';
      if (userRole == 'hr' || userRole == 'director') {
        print('✅ User authorized via userRole: $userRole');
        return true;
      }

      print('⚠️ User is not HR or Director (loginType: "$loginType", position: "$position", role: "$userRole") - notification will not be sent');
      return false;
    } catch (e) {
      print('❌ Error checking user role: $e');
      return false;
    }
  }

  /// Send notification to backend
  /// NOTE: Backend should handle notifications automatically in event APIs
  /// This method is optional - if backend notification API exists, it will be called
  /// If API doesn't exist (404), backend will handle notifications from event APIs
  Future<void> sendNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? topic,
  }) async {
    print('📤 Notification send request received:');
    print('   Title: $title');
    print('   Body: $body');
    print('   Topic: ${topic ?? "all"}');
    print('   Data: $data');
    
    // Determine notification type from data or topic
    String notificationType = 'general';
    if (data != null && data.containsKey('type')) {
      notificationType = data['type'].toString();
    } else if (topic != null) {
      notificationType = topic;
    }
    
    // Try to send notification to backend API (optional)
    // If API doesn't exist, backend should handle notifications from event APIs
    try {
      final success = await BackendNotificationService.sendNotificationToBackend(
        title: title,
        body: body,
        data: data,
        notificationType: notificationType,
      );
      
      if (success) {
        print('   ✅ Notification sent to backend API - will be delivered to HR/Director only');
      } else {
        // API might not exist (404) - that's okay, backend will handle from event APIs
        print('   ℹ️ Notification API not available - backend will handle notifications from event APIs');
      }
    } catch (e) {
      // Silently handle - backend will send notifications from event APIs
      print('   ℹ️ Notification API call failed - backend will handle notifications automatically');
    }
  }

  /// Get FCM token (for sending to backend)
  String? get fcmToken => _fcmToken;

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Save FCM token to backend
  Future<void> _saveTokenToBackend(String token) async {
    try {
      // Wait a bit for user session to be available (in case app just started)
      await Future.delayed(const Duration(seconds: 2));
      
      final saved = await DeviceTokenService.saveDeviceToken(
        token: token,
        deviceType: Platform.isAndroid ? 'Android' : 'iOS',
      );
      
      if (saved) {
        print('✅ Device token saved to backend successfully');
      } else {
        print('⚠️ Failed to save device token to backend (will retry on next login)');
      }
    } catch (e) {
      print('❌ Error saving token to backend: $e');
      // Don't throw - token save failure shouldn't break the app
    }
  }

  /// Manually save token to backend (call this after login)
  Future<void> saveTokenToBackend() async {
    if (_fcmToken != null) {
      await _saveTokenToBackend(_fcmToken!);
    } else {
      print('⚠️ No FCM token available to save');
    }
  }
}


