class AssociateLogin {
  String? message;
  String? statusCode;

  AssociateLogin({this.message, this.statusCode});

  factory AssociateLogin.fromJson(Map<String, dynamic> json) {
    return AssociateLogin(
      message: json['message'],
      statusCode: json['StatusCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'StatusCode': statusCode,
    };
  }
}
