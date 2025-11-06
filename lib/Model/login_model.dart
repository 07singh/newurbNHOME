class LoginApi {
  int? id;
  String? name;
  String? mobile;
  String? password;
  String? message;
  String? statuscode;
  String? position; // ✅ Add this

  LoginApi({this.id, this.name, this.mobile, this.password, this.message, this.statuscode, this.position});

  factory LoginApi.fromJson(Map<String, dynamic> json) {
    return LoginApi(
      id: json['id'],
      name: json['name'],
      mobile: json['mobile'],
      password: json['password'],
      message: json['Message'],       // match backend
      statuscode: json['StatusCode'], // match backend
      position: json['position'],     // map position
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mobile': mobile,
    'password': password,
    'message': message,
    'statuscode': statuscode,
    'position': position,
  };
}
