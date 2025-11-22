class AttendanceSummary {
  final DateTime? date;
  final AttendanceCount count;
  final List<StaffStatus> presentStaff;
  final List<StaffStatus> checkoutStaff;
  final List<StaffStatus> absentStaff;

  AttendanceSummary({
    required this.date,
    required this.count,
    required this.presentStaff,
    required this.checkoutStaff,
    required this.absentStaff,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      count: AttendanceCount.fromJson(json['count'] ?? {}),
      presentStaff: (json['presentStaff'] as List<dynamic>? ?? [])
          .map((e) => StaffStatus.fromJson(e as Map<String, dynamic>, StaffCategory.present))
          .toList(),
      checkoutStaff: (json['checkoutStaff'] as List<dynamic>? ?? [])
          .map((e) => StaffStatus.fromJson(e as Map<String, dynamic>, StaffCategory.checkout))
          .toList(),
      absentStaff: (json['absentStaff'] as List<dynamic>? ?? [])
          .map((e) => StaffStatus.fromJson(e as Map<String, dynamic>, StaffCategory.absent))
          .toList(),
    );
  }
}

class AttendanceCount {
  final int present;
  final int absent;
  final int checkedOut;

  AttendanceCount({
    required this.present,
    required this.absent,
    required this.checkedOut,
  });

  factory AttendanceCount.fromJson(Map<String, dynamic> json) {
    return AttendanceCount(
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      checkedOut: json['checkedOut'] ?? 0,
    );
  }
}

enum StaffCategory { present, checkout, absent }

class StaffStatus {
  final String id;
  final String name;
  final String? role;
  final String phone;
  final String status;
  final String action;
  final DateTime? timestamp;
  final String? location;
  final StaffCategory category;
  final String? hoursWorked;

  StaffStatus({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.action,
    required this.category,
    this.role,
    this.timestamp,
    this.location,
    this.hoursWorked,
  });

  factory StaffStatus.fromJson(Map<String, dynamic> json, StaffCategory category) {
    DateTime? ts;
    if (category == StaffCategory.present) {
      ts = DateTime.tryParse(json['CheckInTime'] ?? '');
    } else if (category == StaffCategory.checkout) {
      ts = DateTime.tryParse(json['CheckOutTime'] ?? '');
    } else {
      ts = DateTime.tryParse(json['date'] ?? '');
    }

    return StaffStatus(
      id: json['EmpId']?.toString() ??
          json['Staff_Id']?.toString() ??
          json['EmpId']?.toString() ??
          '',
      name: json['EmployeeName'] ?? json['Fullname'] ?? '',
      role: json['EmployeeType'] ?? json['Position'],
      phone: json['EmpMob'] ?? json['Phone'] ?? '',
      status: json['Status'] ?? '',
      action: json['Action'] ?? '',
      location: json['CheckInLocation'] ?? json['CheckOutLocation'],
      timestamp: ts,
      category: category,
      hoursWorked: json['HoursWorked'],
    );
  }
}




