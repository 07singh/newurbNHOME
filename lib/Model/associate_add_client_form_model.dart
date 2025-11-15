// Model/associate_add_client_form_model.dart
class AddClientRequest {
  final String clientName;
  final String projectName;
  final String createDate;
  final String contactNo;
  final String note;

  AddClientRequest({
    required this.clientName,
    required this.projectName,
    required this.createDate,
    required this.contactNo,
    required this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'Client_Name': clientName,
      'Project_Name': projectName,
      'CreateDate': createDate,
      'Contact_No': contactNo,
      'Note': note,
    };
  }
}

class AddClientResponse {
  final String message;
  final String status;

  AddClientResponse({
    required this.message,
    required this.status,
  });

  factory AddClientResponse.fromJson(Map<String, dynamic> json) {
    return AddClientResponse(
      message: json['message'] ?? '',
      status: json['status'] ?? '',
    );
  }
}