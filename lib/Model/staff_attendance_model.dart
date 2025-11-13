class StaffAttendance {
  final String empId;
  final String employeeName;
  final String employeeType;
  final String empMob;
  final String checkInTime;
  final String checkOutTime;
  final String checkInImage;
  final String checkOutImage;
  final String checkInLocation;
  final String checkOutLocation;
  final String hoursWorked;
  final String status;
  final String action;

  StaffAttendance({
    required this.empId,
    required this.employeeName,
    required this.employeeType,
    required this.empMob,
    required this.checkInTime,
    required this.checkOutTime,
    required this.checkInImage,
    required this.checkOutImage,
    required this.checkInLocation,
    required this.checkOutLocation,
    required this.hoursWorked,
    required this.status,
    required this.action,
  });

  factory StaffAttendance.fromJson(Map<String, dynamic> json) {
    return StaffAttendance(
      empId: json['EmpId']?.toString() ?? '',
      employeeName: json['EmployeeName'] ?? '',
      employeeType: json['EmployeeType'] ?? '',
      empMob: json['EmpMob'] ?? '',
      checkInTime: json['CheckInTime'] ?? '',
      checkOutTime: json['CheckOutTime'] ?? '',
      checkInImage: json['CheckInImage'] ?? '',
      checkOutImage: json['CheckOutImage'] ?? '',
      checkInLocation: json['CheckInLocation'] ?? '',
      checkOutLocation: json['CheckOutLocation'] ?? '',
      hoursWorked: json['HoursWorked'] ?? '',
      status: json['Status'] ?? '',
      action: json['Action'] ?? '',
    );
  }
}