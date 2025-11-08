class Associate {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String? profilePic;

  Associate({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profilePic,
  });

  factory Associate.fromJson(Map<String, dynamic> json) {
    return Associate(
      id: json['Id'] ?? 0,
      fullName: json['FullName'] ?? '',
      email: json['Email'] ?? '',
      phone: json['Phone'] ?? '',
      profilePic: json['Profile_Pic'],
    );
  }
}

class LoginResponse {
  final String message;
  final String status;
  final Associate? associate;

  LoginResponse({
    required this.message,
    required this.status,
    this.associate,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      associate: json['associate'] != null
          ? Associate.fromJson(json['associate'])
          : null,
    );
  }
}
