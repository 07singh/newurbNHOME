/// Attendance Model for Check-In/Check-Out
class AttendanceModel {
  final String employeeName;
  final String empMob;
  final String? checkInTime;
  final String? checkOutTime;
  final String? checkInLocation;
  final String? checkOutLocation;
  final String? checkInImage;
  final String? checkOutImage;
  final String? status;
  final String? action;
  final String? state;

  AttendanceModel({
    required this.employeeName,
    required this.empMob,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLocation,
    this.checkOutLocation,
    this.checkInImage,
    this.checkOutImage,
    this.status,
    this.action,
    this.state,
  });

  /// Create from JSON
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      employeeName: json['EmployeeName'] ?? '',
      empMob: json['EmpMob'] ?? '',
      checkInTime: json['CheckInTime'],
      checkOutTime: json['CheckOutTime'],
      checkInLocation: json['CheckInLocation'],
      checkOutLocation: json['CheckOutLocation'],
      checkInImage: json['CheckInImage'],
      checkOutImage: json['CheckOutImage'],
      status: json['Status'],
      action: json['Action'],
      state: json['State'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'EmployeeName': employeeName,
      'EmpMob': empMob,
      if (checkInTime != null) 'CheckInTime': checkInTime,
      if (checkOutTime != null) 'CheckOutTime': checkOutTime,
      if (checkInLocation != null) 'CheckInLocation': checkInLocation,
      if (checkOutLocation != null) 'CheckOutLocation': checkOutLocation,
      if (checkInImage != null) 'CheckInImage': checkInImage,
      if (checkOutImage != null) 'CheckOutImage': checkOutImage,
      // Always include Status and Action if they are set (required for check-out)
      if (status != null && status!.isNotEmpty) 'Status': status,
      if (action != null && action!.isNotEmpty) 'Action': action,
      if (state != null) 'State': state,
    };
  }

  /// Create a copy with updated values
  AttendanceModel copyWith({
    String? employeeName,
    String? empMob,
    String? checkInTime,
    String? checkOutTime,
    String? checkInLocation,
    String? checkOutLocation,
    String? checkInImage,
    String? checkOutImage,
    String? status,
    String? action,
    String? state,
  }) {
    return AttendanceModel(
      employeeName: employeeName ?? this.employeeName,
      empMob: empMob ?? this.empMob,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      checkInImage: checkInImage ?? this.checkInImage,
      checkOutImage: checkOutImage ?? this.checkOutImage,
      status: status ?? this.status,
      action: action ?? this.action,
      state: state ?? this.state,
    );
  }
}

/// Response model for attendance API
class AttendanceResponse {
  final String? message;
  final String? status;
  final Map<String, dynamic>? data;

  AttendanceResponse({
    this.message,
    this.status,
    this.data,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      message: json['message'],
      status: json['status'],
      data: json['data'],
    );
  }
}
