// Model/associate_profile_change_model.dart
class AssociateProfileChangeRequest {
  final String phone;
  final String profilePic;

  AssociateProfileChangeRequest({
    required this.phone,
    required this.profilePic,
  });

  Map<String, dynamic> toJson() {
    return {
      'Phone': phone,
      'ProfilePic': profilePic,
    };
  }
}

class AssociateProfileChangeResponse {
  final String status;
  final String message;

  AssociateProfileChangeResponse({
    required this.status,
    required this.message,
  });

  factory AssociateProfileChangeResponse.fromJson(Map<String, dynamic> json) {
    return AssociateProfileChangeResponse(
      status: json['Status'] ?? '',
      message: json['Message'] ?? '',
    );
  }
}