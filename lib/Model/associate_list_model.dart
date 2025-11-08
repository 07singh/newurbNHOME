class Associate {
  final int id;
  final String fullName;
  final String phone;
  final String email;
  final String currentAddress;
  final String permanentAddress;
  final String state;
  final String city;
  final String pincode;
  final String aadhaarNo;
  final String panNo;
  final String aadharFrontPic;
  final String aadhaarBackPic;
  final String panPic;
  final String password;
  final bool status;
  final String associateId;
  final String createDate;
  final String? joiningDate;
  final String? loginDate;
  final String? logoutDate;
  final String profilePic;

  Associate({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.currentAddress,
    required this.permanentAddress,
    required this.state,
    required this.city,
    required this.pincode,
    required this.aadhaarNo,
    required this.panNo,
    required this.aadharFrontPic,
    required this.aadhaarBackPic,
    required this.panPic,
    required this.password,
    required this.status,
    required this.associateId,
    required this.createDate,
    this.joiningDate,
    this.loginDate,
    this.logoutDate,
    required this.profilePic,
  });

  factory Associate.fromJson(Map<String, dynamic> json) {
    return Associate(
      id: json['Id'],
      fullName: json['FullName'],
      phone: json['Phone'],
      email: json['Email'],
      currentAddress: json['CurrentAddress'],
      permanentAddress: json['PermanentAddress'],
      state: json['State'],
      city: json['City'],
      pincode: json['Pincode'],
      aadhaarNo: json['AadhaarNo'],
      panNo: json['PanNo'],
      aadharFrontPic: json['AadharFrontPic'],
      aadhaarBackPic: json['AadhaarBackPic'],
      panPic: json['PanPic'],
      password: json['Password'],
      status: json['Status'],
      associateId: json['AssociateId'],
      createDate: json['CreateDate'],
      joiningDate: json['JoiningDate'],
      loginDate: json['LoginDate'],
      logoutDate: json['LogoutDate'],
      profilePic: json['Profile_Pic'],
    );
  }
}
