class AddAssociateResponse {
  final String message;
  final String statusCode;

  AddAssociateResponse({
    required this.message,
    required this.statusCode,
  });

  factory AddAssociateResponse.fromJson(Map<String, dynamic> json) {
    return AddAssociateResponse(
      message: json['message'] ?? 'No message',
      statusCode: json['StatusCode'] ?? 'Error',
    );
  }
}
