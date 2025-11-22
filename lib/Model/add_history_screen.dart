class DayBookHistory {
  final int id;
  final String? employeeName;
  final DateTime? dateTime;
  final double? amount;
  final String? purpose;
  final String? spendBy;
  final String? paymentGivenBy;
  final String? paymentMode;
  final String? remarks;
  final String? screenshot;

  DayBookHistory({
    required this.id,
    this.employeeName,
    this.dateTime,
    this.amount,
    this.purpose,
    this.spendBy,
    this.paymentGivenBy,
    this.paymentMode,
    this.remarks,
    this.screenshot,
  });

  factory DayBookHistory.fromJson(Map<String, dynamic> json) {
    return DayBookHistory(
      id: json['Id'] ?? 0,
      employeeName: json['Employee_Name'],
      dateTime: json['Date_Time'] != null
          ? DateTime.tryParse(json['Date_Time'])
          : null,
      amount: json['Amount'] != null
          ? (json['Amount'] as num).toDouble()
          : null,
      purpose: json['Purpose'],
      spendBy: json['Spend_By'],
      paymentGivenBy: json['PaymentGivenBy'],
      paymentMode: json['PaymentMode'],
      remarks: json['Remarks'],
      screenshot: json['Screenshot'], // already contains path
    );
  }

  /// FULL ONLINE IMAGE URL
  String? getScreenshotFullUrl() {
    if (screenshot == null || screenshot!.isEmpty) return null;

    return "https://realapp.cheenu.in${screenshot!}";
  }
}
