import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/Model/user_session.dart';

class AuthManager {
  static const String _sessionBoxName = 'userSessionBox';
  static const String _sessionKey = 'currentSession';
  static Box<UserSession>? _sessionBox;
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Initialize Hive and open the session box
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register the UserSession adapter if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserSessionAdapter());
    }
    
    _sessionBox = await Hive.openBox<UserSession>(_sessionBoxName);
  }

  // Save user session after successful login
  static Future<bool> saveSession(UserSession session) async {
    try {
      if (_sessionBox == null) await initialize();
      
      await _sessionBox!.put(_sessionKey, session);
      
      // Also save to secure storage as backup
      await _secureStorage.write(key: 'user_id', value: session.userId ?? '');
      await _secureStorage.write(key: 'user_name', value: session.userName ?? '');
      await _secureStorage.write(key: 'user_mobile', value: session.userMobile ?? '');
      await _secureStorage.write(key: 'user_role', value: session.userRole ?? '');
      await _secureStorage.write(key: 'login_type', value: session.loginType ?? '');
      
      if (session.profilePic != null) {
        await _secureStorage.write(key: 'profile_pic', value: session.profilePic!);
      }
      
      return true;
    } catch (e) {
      print('Error saving session: $e');
      return false;
    }
  }

  // Get current user session
  static Future<UserSession?> getCurrentSession() async {
    try {
      if (_sessionBox == null) await initialize();
      
      UserSession? session = _sessionBox!.get(_sessionKey);
      
      // Validate session - check if it's recent (e.g., within 30 days)
      if (session != null && session.isLoggedIn) {
        if (session.lastLoginTime != null) {
          final daysSinceLogin = DateTime.now().difference(session.lastLoginTime!).inDays;
          if (daysSinceLogin > 30) {
            // Session expired, clear it
            await clearSession();
            return null;
          }
        }
        return session;
      }
      
      return null;
    } catch (e) {
      print('Error getting session: $e');
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final session = await getCurrentSession();
      return session != null && session.isLoggedIn;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Get login type of current user
  static Future<String?> getLoginType() async {
    try {
      final session = await getCurrentSession();
      return session?.loginType;
    } catch (e) {
      print('Error getting login type: $e');
      return null;
    }
  }

  // Clear session (logout)
  static Future<void> clearSession() async {
    try {
      if (_sessionBox == null) await initialize();
      
      // Clear Hive session
      await _sessionBox!.delete(_sessionKey);
      
      // Clear secure storage
      await _secureStorage.deleteAll();
      
      print('Session cleared successfully');
    } catch (e) {
      print('Error clearing session: $e');
    }
  }

  // Update session data (e.g., after profile update)
  static Future<bool> updateSession({
    String? userName,
    String? profilePic,
    String? userRole,
  }) async {
    try {
      final session = await getCurrentSession();
      if (session != null) {
        if (userName != null) session.userName = userName;
        if (profilePic != null) session.profilePic = profilePic;
        if (userRole != null) session.userRole = userRole;
        
        await saveSession(session);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating session: $e');
      return false;
    }
  }

  // Get user details from session
  static Future<Map<String, dynamic>?> getUserDetails() async {
    try {
      final session = await getCurrentSession();
      if (session != null) {
        return {
          'userId': session.userId,
          'userName': session.userName,
          'userMobile': session.userMobile,
          'userRole': session.userRole,
          'profilePic': session.profilePic,
          'loginType': session.loginType,
          'phone': session.phone,
          'position': session.position,
          'fullProfileImageUrl': session.fullProfileImageUrl,
        };
      }
      return null;
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }

  // Close Hive box (call this when app is disposed)
  static Future<void> dispose() async {
    await _sessionBox?.close();
  }
}



