class StaffProfileResponse {
  final String message;
  final String status;
  final Staff? staff;

  StaffProfileResponse({
    required this.message,
    required this.status,
    required this.staff,
  });

  factory StaffProfileResponse.fromJson(Map<String, dynamic> json) {
    return StaffProfileResponse(
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      staff: json['staff'] != null ? Staff.fromJson(json['staff']) : null,
    );
  }
}

class Staff {
  final int id;
  final String fullName;
  final String phone;
  final String email;
  final String position;
  final String staffId;
  final String password;
  final bool status;
  final String createDate;
  final String? loginDate;
  final String? logoutDate;
  final String joiningDate;
  final String? profilePicUrl;

  Staff({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.position,
    required this.staffId,
    required this.password,
    required this.status,
    required this.createDate,
    this.loginDate,
    this.logoutDate,
    required this.joiningDate,
    this.profilePicUrl,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['Id'] ?? 0,
      fullName: json['Fullname'] ?? '',
      phone: json['Phone'] ?? '',
      email: json['Email'] ?? '',
      position: json['Position'] ?? '',
      staffId: json['Staff_Id'] ?? '',
      password: json['Password'] ?? '',
      status: json['Status'] ?? false,
      createDate: json['CreateDate'] ?? '',
      loginDate: json['LoginDate'],
      logoutDate: json['LogoutDate'],
      joiningDate: json['JoiningDate'] ?? '',
      profilePicUrl: json['profilePicUrl'],
    );
  }

  /// Returns full image URL with domain if available
  String get fullProfilePicUrl {
    if (profilePicUrl == null || profilePicUrl!.isEmpty) {
      return "https://realapp.cheenu.in/Uploads/default.png";
    }
    if (profilePicUrl!.startsWith("http")) {
      return profilePicUrl!;
    }
    return "https://realapp.cheenu.in${profilePicUrl!}";
  }
}
