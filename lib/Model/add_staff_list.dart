class StaffListResponse {
  final String message;
  final bool status;
  final List<Staff> data;

  StaffListResponse({
    required this.message,
    required this.status,
    required this.data,
  });

  factory StaffListResponse.fromJson(Map<String, dynamic> json) {
    return StaffListResponse(
      message: json['message'] ?? '',
      status: json['status'] ?? false,
      data: json['data'] != null
          ? List<Staff>.from(json['data'].map((x) => Staff.fromJson(x)))
          : [],
    );
  }
}

class Staff {
  final int id;
  final String fullname;
  final String phone;
  final String email;
  final String position;
  final String password;
  final bool status;
  final String staffId;
  final String? createDate;
  final String? joiningDate;
  final String? loginDate;
  final String? profilePic;
  final String? logoutDate;

  Staff({
    required this.id,
    required this.fullname,
    required this.phone,
    required this.email,
    required this.position,
    required this.password,
    required this.status,
    required this.staffId,
    this.createDate,
    this.joiningDate,
    this.loginDate,
    this.profilePic,
    this.logoutDate,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['Id'] ?? 0,
      fullname: json['Fullname'] ?? '',
      phone: json['Phone'] ?? '',
      email: json['Email'] ?? '',
      position: json['Position'] ?? '',
      password: json['Password'] ?? '',
      status: json['Status'] ?? false,
      staffId: json['Staff_Id'] ?? '',
      createDate: json['CreateDate'],
      joiningDate: json['JoiningDate'],
      loginDate: json['LoginDate'],
      profilePic: json['Profile_Pic'],
      logoutDate: json['LogoutDate'],
    );
  }
}
