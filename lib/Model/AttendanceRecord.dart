class AttendanceRecord {
  final int id;
  final String employeeName;
  final DateTime createDate;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String checkInLocation;
  final String checkOutLocation;
  final String checkInImage;
  final String? checkOutImage;
  final String? status;
  final String? hoursWorked;
  final String empId;
  final String employeeType;
  final String action;
  final String empMob;

  AttendanceRecord({
    required this.id,
    required this.employeeName,
    required this.createDate,
    required this.checkInTime,
    this.checkOutTime,
    required this.checkInLocation,
    required this.checkOutLocation,
    required this.checkInImage,
    this.checkOutImage,
    this.status,
    this.hoursWorked,
    required this.empId,
    required this.employeeType,
    required this.action,
    required this.empMob,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['Id'] ?? 0,
      employeeName: json['EmployeeName'] ?? '',
      createDate: DateTime.parse(json['Createdate'] ?? DateTime.now().toString()),
      checkInTime: DateTime.parse(json['CheckInTime'] ?? DateTime.now().toString()),
      checkOutTime: json['CheckOutTime'] != null ? DateTime.parse(json['CheckOutTime']) : null,
      checkInLocation: json['CheckInLocation'] ?? '',
      checkOutLocation: json['CheckOutLocation'] ?? '',
      checkInImage: json['CheckInImage'] ?? '',
      checkOutImage: json['CheckOutImage'],
      status: json['Status'],
      hoursWorked: json['HoursWorked'],
      empId: json['EmpId'] ?? '',
      employeeType: json['EmployeeType'] ?? '',
      action: json['Action'] ?? '',
      empMob: json['EmpMob'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'EmployeeName': employeeName,
      'Createdate': createDate.toIso8601String(),
      'CheckInTime': checkInTime.toIso8601String(),
      'CheckOutTime': checkOutTime?.toIso8601String(),
      'CheckInLocation': checkInLocation,
      'CheckOutLocation': checkOutLocation,
      'CheckInImage': checkInImage,
      'CheckOutImage': checkOutImage,
      'Status': status,
      'HoursWorked': hoursWorked,
      'EmpId': empId,
      'EmployeeType': employeeType,
      'Action': action,
      'EmpMob': empMob,
    };
  }
}

class AttendanceResponse {
  final String message;
  final List<AttendanceRecord> data;

  AttendanceResponse({
    required this.message,
    required this.data,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      message: json['message'] ?? '',
      data: (json['data1'] as List<dynamic>?)
          ?.map((item) => AttendanceRecord.fromJson(item))
          .toList() ?? [],
    );
  }
}