class DayBookHistory {
  final int id;
  final String? employeeName;
  final DateTime? dateTime;
  final double? amount;
  final String? purpose;
  final String? spendBy;

  DayBookHistory({
    required this.id,
    this.employeeName,
    this.dateTime,
    this.amount,
    this.purpose,
    this.spendBy,
  });

  factory DayBookHistory.fromJson(Map<String, dynamic> json) {
    return DayBookHistory(
      id: json['Id'] ?? 0,
      employeeName: json['Employee_Name'],
      dateTime: json['Date_Time'] != null ? DateTime.tryParse(json['Date_Time']) : null,
      amount: json['Amount'] != null ? (json['Amount'] as num).toDouble() : null,
      purpose: json['Purpose'],
      spendBy: json['Spend_By'],
    );
  }
}
