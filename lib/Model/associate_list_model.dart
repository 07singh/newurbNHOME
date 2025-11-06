class AssociateList {
  List<Data1>? data1;
  String? message;

  AssociateList({this.data1, this.message});

  AssociateList.fromJson(Map<String, dynamic> json) {
    if (json['data1'] != null) {
      data1 = <Data1>[];
      json['data1'].forEach((v) {
        data1!.add(Data1.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (data1 != null) {
      data['data1'] = data1!.map((v) => v.toJson()).toList();
    }
    data['message'] = message;
    return data;
  }
}

class Data1 {
  int? id;
  String? fullName;
  String? phone;
  String? email;
  String? currentAddress;
  String? permanentAddress;
  String? state;
  String? city;
  String? pincode;
  String? aadhaarNo;
  String? panNo;
  String? aadharFrontPic;
  String? aadhaarBackPic;
  String? panPic;
  String? password;
  bool? status;
  String? associateId;
  String? createDate;
  String? joiningDate;
  String? loginDate;
  String? logoutDate;
  String? photoBase64;

  Data1({
    this.id,
    this.fullName,
    this.phone,
    this.email,
    this.currentAddress,
    this.permanentAddress,
    this.state,
    this.city,
    this.pincode,
    this.aadhaarNo,
    this.panNo,
    this.aadharFrontPic,
    this.aadhaarBackPic,
    this.panPic,
    this.password,
    this.status,
    this.associateId,
    this.createDate,
    this.joiningDate,
    this.loginDate,
    this.logoutDate,
    this.photoBase64,
  });

  Data1.fromJson(Map<String, dynamic> json) {
    id = json['Id'];
    fullName = json['FullName'];
    phone = json['Phone'];
    email = json['Email'];
    currentAddress = json['CurrentAddress'];
    permanentAddress = json['PermanentAddress'];
    state = json['State'];
    city = json['City'];
    pincode = json['Pincode'];
    aadhaarNo = json['AadhaarNo'];
    panNo = json['PanNo'];
    aadharFrontPic = json['AadharFrontPic'];
    aadhaarBackPic = json['AadhaarBackPic'];
    panPic = json['PanPic'];
    password = json['Password'];
    status = json['Status'];
    associateId = json['AssociateId'];
    createDate = json['CreateDate'];
    joiningDate = json['JoiningDate'];
    loginDate = json['LoginDate'];
    logoutDate = json['LogoutDate'];
    photoBase64 = json['PhotoBase64'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Id'] = id;
    data['FullName'] = fullName;
    data['Phone'] = phone;
    data['Email'] = email;
    data['CurrentAddress'] = currentAddress;
    data['PermanentAddress'] = permanentAddress;
    data['State'] = state;
    data['City'] = city;
    data['Pincode'] = pincode;
    data['AadhaarNo'] = aadhaarNo;
    data['PanNo'] = panNo;
    data['AadharFrontPic'] = aadharFrontPic;
    data['AadhaarBackPic'] = aadhaarBackPic;
    data['PanPic'] = panPic;
    data['Password'] = password;
    data['Status'] = status;
    data['AssociateId'] = associateId;
    data['CreateDate'] = createDate;
    data['JoiningDate'] = joiningDate;
    data['LoginDate'] = loginDate;
    data['LogoutDate'] = logoutDate;
    data['PhotoBase64'] = photoBase64;
    return data;
  }
}