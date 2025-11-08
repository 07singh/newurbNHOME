class LoginApi {
  final int? id;
  final String? name;
  final String? mobile;
  final String? position;
  final String? profilePic;
  final String statuscode;
  final String message;

  LoginApi({
    this.id,
    this.name,
    this.mobile,
    this.position,
    this.profilePic,
    required this.statuscode,
    required this.message,
  });

  factory LoginApi.fromJson(Map<String, dynamic> json) {
    final staff = json['staff'];
    return LoginApi(
      id: staff != null ? staff['Id'] : null,
      name: staff != null ? staff['Fullname'] : null,
      mobile: staff != null ? staff['mobile'] : null,
      position: staff != null ? staff['Position'] : null,
      profilePic: staff != null ? staff['profilepic'] : null,
      statuscode: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
