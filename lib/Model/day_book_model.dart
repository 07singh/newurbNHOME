class DayBook {
  int id;
  String employeeName;
  DateTime dateTime;
  double amount;
  String purpose;
  String spendBy;

  DayBook({
    required this.id,
    required this.employeeName,
    required this.dateTime,
    required this.amount,
    required this.purpose,
    required this.spendBy,
  });

  /// Parse from JSON (response)
  factory DayBook.fromJson(Map<String, dynamic> json) {
    return DayBook(
      id: json['Id'] ?? 0,
      employeeName: json['Employee_Name'] ?? '',
      dateTime: DateTime.tryParse(json['Date_Time'] ?? '') ?? DateTime.now(),
      amount: (json['Amount']?.toDouble()) ?? 0.0,
      purpose: json['Purpose'] ?? '',
      spendBy: json['Spend_By'] ?? '',
    );
  }

  /// Convert to JSON (request)
  Map<String, dynamic> toJson() {
    return {
      "Id": id,
      "Employee_Name": employeeName,
      "Date_Time": dateTime.toIso8601String(),
      "Amount": amount,
      "Purpose": purpose,
      "Spend_By": spendBy,
    };
  }
}
