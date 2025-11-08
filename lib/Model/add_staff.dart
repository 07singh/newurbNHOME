class AddStaffResponse {
  final String? message;
  final String? status;

  AddStaffResponse({this.message, this.status});

  factory AddStaffResponse.fromJson(Map<String, dynamic> json) {
    return AddStaffResponse(
      message: json['message'],
      status: json['Status'],
    );
  }
}

class AddStaffRequest {
  final String fullname;
  final String phone;
  final String email;
  final String position;
  final String password;
  final bool status;
  final String staffId;
  final String createDate;
  final String joiningDate;
  final String loginDate;
  final String logoutDate;
  final String profilePic; // Base64

  AddStaffRequest({
    required this.fullname,
    required this.phone,
    required this.email,
    required this.position,
    required this.password,
    required this.status,
    required this.staffId,
    required this.createDate,
    required this.joiningDate,
    required this.loginDate,
    required this.logoutDate,
    required this.profilePic,
  });

  Map<String, dynamic> toJson() {
    return {
      "Fullname": fullname,
      "Phone": phone,
      "Email": email,
      "Position": position,
      "Password": password,
      "Status": status,
      "Staff_Id": staffId,
      "CreateDate": createDate,
      "JoiningDate": joiningDate,
      "LoginDate": loginDate,
      "LogoutDate": logoutDate,
      "Profile_Pic": profilePic,
    };
  }
}
