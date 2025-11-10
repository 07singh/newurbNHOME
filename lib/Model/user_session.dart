import 'package:hive/hive.dart';

part 'user_session.g.dart';

@HiveType(typeId: 0)
class UserSession extends HiveObject {
  @HiveField(0)
  String? userId;

  @HiveField(1)
  String? userName;

  @HiveField(2)
  String? userMobile;

  @HiveField(3)
  String? userRole;

  @HiveField(4)
  String? profilePic;

  @HiveField(5)
  String? loginType; // 'director', 'employee', 'hr', 'associate'

  @HiveField(6)
  String? phone;

  @HiveField(7)
  String? position;

  @HiveField(8)
  DateTime? lastLoginTime;

  @HiveField(9)
  bool isLoggedIn;

  UserSession({
    this.userId,
    this.userName,
    this.userMobile,
    this.userRole,
    this.profilePic,
    this.loginType,
    this.phone,
    this.position,
    this.lastLoginTime,
    this.isLoggedIn = false,
  });

  // Helper method to create a session from login data
  factory UserSession.fromLogin({
    required String userId,
    required String userName,
    required String userMobile,
    required String userRole,
    required String loginType,
    String? profilePic,
    String? phone,
    String? position,
  }) {
    return UserSession(
      userId: userId,
      userName: userName,
      userMobile: userMobile,
      userRole: userRole,
      profilePic: profilePic,
      loginType: loginType,
      phone: phone ?? userMobile,
      position: position ?? userRole,
      lastLoginTime: DateTime.now(),
      isLoggedIn: true,
    );
  }

  // Helper method to clear session (logout)
  void clearSession() {
    userId = null;
    userName = null;
    userMobile = null;
    userRole = null;
    profilePic = null;
    loginType = null;
    phone = null;
    position = null;
    lastLoginTime = null;
    isLoggedIn = false;
  }

  // Helper method to get profile image URL
  String? get fullProfileImageUrl {
    if (profilePic != null && profilePic!.isNotEmpty) {
      if (profilePic!.startsWith('http')) {
        return profilePic;
      }
      return "https://realapp.cheenu.in/Images/$profilePic";
    }
    return null;
  }
}



