class AssociateProfile {
  final int id;
  final String fullName;
  final String phone;
  final String email;
  final String currentAddress;
  final String city;
  final String state;
  final String pincode;
  final String aadhaarNo;
  final String panNo;
  final bool status;
  final String associateId;
  final String? loginDate;
  final String? logoutDate;
  final String? profileImageUrl;
  final String? aadharFrontPic;
  final String? aadharBackPic;
  final String? panPic;

  AssociateProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.currentAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.aadhaarNo,
    required this.panNo,
    required this.status,
    required this.associateId,
    this.loginDate,
    this.logoutDate,
    this.profileImageUrl,
    this.aadharFrontPic,
    this.aadharBackPic,
    this.panPic,
  });

  factory AssociateProfile.fromJson(Map<String, dynamic> json) {
    // Try multiple possible keys for profile image
    String? getProfileImageUrl(Map<String, dynamic> json) {
      // Try different possible field names from API
      return json['profileImageUrl'] ?? 
             json['ProfileImageUrl'] ?? 
             json['ProfilePic'] ?? 
             json['Profilepic'] ?? 
             json['profile_pic'] ?? 
             json['profilePic'] ??
             json['ImageUrl'] ??
             json['image_url'];
    }
    
    return AssociateProfile(
      id: json['Id'] ?? 0,
      fullName: json['FullName'] ?? '',
      phone: json['Phone'] ?? '',
      email: json['Email'] ?? '',
      currentAddress: json['CurrentAddress'] ?? '',
      city: json['City'] ?? '',
      state: json['State'] ?? '',
      pincode: json['Pincode'] ?? '',
      aadhaarNo: json['AadhaarNo'] ?? '',
      panNo: json['PanNo'] ?? '',
      status: json['Status'] ?? false,
      associateId: json['AssociateId'] ?? '',
      loginDate: json['LoginDate'],
      logoutDate: json['LogoutDate'],
      profileImageUrl: getProfileImageUrl(json),
      aadharFrontPic: json['Aadharfrontpic'] ?? json['AadharFrontPic'],
      aadharBackPic: json['Aadharbackpic'] ?? json['AadharBackPic'],
      panPic: json['Panpic'] ?? json['PanPic'],
    );
  }
}
