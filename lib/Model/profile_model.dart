
class ProfileResponse {
  final List<ProfileData> data1;
  final String? message;

  ProfileResponse({required this.data1, this.message});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data1'] as List<dynamic>?)
        ?.map((e) => ProfileData.fromJson(e as Map<String, dynamic>))
        .toList() ??
        <ProfileData>[];
    return ProfileResponse(data1: data, message: json['message'] as String?);
  }
}

class ProfileData {
  final int? id;
  final String? fullname;
  final String? phone;
  final String? email;
  final String? position;
  final String? password;
  final bool? status;
  final dynamic staffId;
  final String? createDate;
  final String? joiningDate;
  final String? loginDate;
  final String? loginOut;

  ProfileData({
    this.id,
    this.fullname,
    this.phone,
    this.email,
    this.position,
    this.password,
    this.status,
    this.staffId,
    this.createDate,
    this.joiningDate,
    this.loginDate,
    this.loginOut,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: json['Id'] is int ? json['Id'] as int : int.tryParse('${json['Id']}'),
      fullname: json['Fullname'] as String?,
      phone: json['Phone'] as String?,
      email: json['Email'] as String?,
      position: json['Position'] as String?,
      password: json['Password'] as String?,
      status: json['Status'] is bool ? json['Status'] as bool : (json['Status'] == 1),
      staffId: json['Staff_Id'],
      createDate: json['CreateDate']?.toString(),
      joiningDate: json['JoiningDate']?.toString(),
      loginDate: json['LoginDate']?.toString(),
      loginOut: json['LoginOut']?.toString(),
    );
  }
}
