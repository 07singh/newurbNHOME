class ChangePasswordResponse {
  final String message;
  final String status;

  ChangePasswordResponse({
    required this.message,
    required this.status,
  });

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      message: json['Message'] ?? '',
      status: json['Status'] ?? '',
    );
  }
}
