class AssociateList {
  final List<AssociateData>? data;
  final String? message;

  AssociateList({this.data, this.message});

  factory AssociateList.fromJson(Map<String, dynamic> json) {
    return AssociateList(
      data: (json['data'] as List?)
          ?.map((e) => AssociateData.fromJson(e))
          .toList(),
      message: json['message'] as String?,
    );
  }
}

class AssociateData {
  final int? id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? state;
  final String? city;
  final String? currentAddress;
  final String? permanentAddress;
  final String? aadhaarNo;
  final String? panNo;
  final String? aadharFrontPic;
  final String? aadhaarBackPic;
  final String? panPic;
  final String? password;
  final bool? status;
  final String? associateId;
  final String? profilePic;
  final String? photoBase64;

  AssociateData({
    this.id,
    this.fullName,
    this.phone,
    this.email,
    this.state,
    this.city,
    this.currentAddress,
    this.permanentAddress,
    this.aadhaarNo,
    this.panNo,
    this.aadharFrontPic,
    this.aadhaarBackPic,
    this.panPic,
    this.password,
    this.status,
    this.associateId,
    this.profilePic,
    this.photoBase64,
  });

  factory AssociateData.fromJson(Map<String, dynamic> json) {
    return AssociateData(
      id: json['Id'],
      fullName: json['FullName'],
      phone: json['Phone'],
      email: json['Email'],
      state: json['State'],
      city: json['City'],
      currentAddress: json['CurrentAddress'],
      permanentAddress: json['PermanentAddress'],
      aadhaarNo: json['AadhaarNo'],
      panNo: json['PanNo'],
      aadharFrontPic: json['AadharFrontPic'],
      aadhaarBackPic: json['AadhaarBackPic'],
      panPic: json['PanPic'],
      password: json['Password'],
      status: json['Status'],
      associateId: json['AssociateId'],
      profilePic: json['Profile_Pic'],
      photoBase64: json['photoBase64'], // optional if coming from API
    );
  }
}
