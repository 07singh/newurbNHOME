class Associate {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String? profilePic;
  final String? currentAddress;
  final String? permanentAddress;
  final String? state;
  final String? city;
  final String? pincode;
  final String? aadhaarNo;
  final String? panNo;
  final String? associateId;
  final String? createDate;
  final String? joiningDate;
  final bool status;
  final String? aadharFrontPic;
  final String? aadhaarBackPic;
  final String? panPic;
  final String? projectName1;
  final String? projectName2;
  final num? commissionProject1;
  final num? commissionProject2;

  Associate({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profilePic,
    this.currentAddress,
    this.permanentAddress,
    this.state,
    this.city,
    this.pincode,
    this.aadhaarNo,
    this.panNo,
    this.associateId,
    this.createDate,
    this.joiningDate,
    this.status = true,
    this.aadharFrontPic,
    this.aadhaarBackPic,
    this.panPic,
    this.projectName1,
    this.projectName2,
    this.commissionProject1,
    this.commissionProject2,
  });

  factory Associate.fromJson(Map<String, dynamic> json) {
    return Associate(
      id: json['Id'] ?? 0,
      fullName: json['FullName'] ?? '',
      email: json['Email'] ?? '',
      phone: json['Phone'] ?? '',
      profilePic: json['Profile_Pic'],
      currentAddress: json['CurrentAddress'],
      permanentAddress: json['PermanentAddress'],
      state: json['State'],
      city: json['City'],
      pincode: json['Pincode'],
      aadhaarNo: json['AadhaarNo'],
      panNo: json['PanNo'],
      associateId: json['AssociateId'],
      createDate: json['CreateDate'],
      joiningDate: json['JoiningDate'],
      status: json['Status'] ?? true,
      aadharFrontPic: json['AadharFrontPic'],
      aadhaarBackPic: json['AadhaarBackPic'],
      panPic: json['PanPic'],
      projectName1: json['ProjectName1'],
      projectName2: json['ProjectName2'],
      commissionProject1: json['CommissionProject1'],
      commissionProject2: json['commissionProject2'],
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
