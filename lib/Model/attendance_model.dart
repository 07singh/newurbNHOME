class AttendanceModel {
  String? message;
  int? employeeId;
  String? hoursWorked;
  String? status;

  AttendanceModel({
    this.message,
    this.employeeId,
    this.hoursWorked,
    this.status,
  });

  AttendanceModel.fromJson(Map<String, dynamic> json) {
    message = json['message'] ?? json['Message'];
    employeeId = json['employeeId'] ?? json['EmployeeId'];
    hoursWorked = json['hoursWorked'] ?? json['HoursWorked'];
    status = json['status'] ?? json['Status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['employeeId'] = employeeId;
    data['hoursWorked'] = hoursWorked;
    data['status'] = status;
    return data;
  }

  bool get isSuccess {
    return message?.toLowerCase().contains('success') == true ||
        status?.toLowerCase().contains('success') == true ||
        employeeId != null;
  }
}

/// Request model for submitting attendance check-in
class AttendanceRequest {
  final String employeeName;
  final String mobile;
  final String checkInTime;
  final double latitude;
  final double longitude;
  final String? address;
  final String? imagePath;

  AttendanceRequest({
    required this.employeeName,
    required this.mobile,
    required this.checkInTime,
    required this.latitude,
    required this.longitude,
    this.address,
    this.imagePath,
  });

  Map<String, String> toMap() {
    return {
      'employeeName': employeeName,
      'mobile': mobile,
      'checkInTime': checkInTime,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'address': address ?? '',
    };
  }
}

