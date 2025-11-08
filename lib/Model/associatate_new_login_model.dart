class AssociateLoginResponse {
  final String message;
  final String status;

  AssociateLoginResponse({
    required this.message,
    required this.status,
  });

  factory AssociateLoginResponse.fromJson(Map<String, dynamic> json) {
    return AssociateLoginResponse(
      message: json['message'] ?? '',
      status: json['status'] ?? '',
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}
