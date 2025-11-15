// models/change_password_model.dart
class ChangePasswordRequest {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  ChangePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'OldPassword': oldPassword,
      'NewPassword': newPassword,
      'ConfirmPassword': confirmPassword,
    };
  }
}

class ChangePasswordResponse {
  final String status;
  final String message;

  ChangePasswordResponse({
    required this.status,
    required this.message,
  });

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      status: json['Status'] ?? '',
      message: json['Message'] ?? '',
    );
  }
}