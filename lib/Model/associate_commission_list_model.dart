// Model/associate_commission_list_model.dart
class CommissionClient {
  final int id;
  final String? clientName;
  final String? projectName;
  final String createDate;
  final String contactNo;
  final String? note;
  final String? message;

  CommissionClient({
    required this.id,
    this.clientName,
    this.projectName,
    required this.createDate,
    required this.contactNo,
    this.note,
    this.message,
  });

  factory CommissionClient.fromJson(Map<String, dynamic> json) {
    return CommissionClient(
      id: json['Id'] ?? 0,
      clientName: json['Client_Name'],
      projectName: json['Project_Name'],
      createDate: json['CreateDate'] ?? '',
      contactNo: json['Contact_No'] ?? '',
      note: json['Note'],
      message: json['Message'],
    );
  }

  DateTime get parsedDate {
    try {
      return DateTime.parse(createDate);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get displayName => clientName ?? 'Unknown Client';
  String get displayProject => projectName ?? 'No Project';
  String get displayNote => note ?? 'No notes available';
}