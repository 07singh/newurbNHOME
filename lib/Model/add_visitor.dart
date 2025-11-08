class Visitor {
  final String name;
  final String mobileNo;
  final String purpose;
  final DateTime date;

  Visitor({
    required this.name,
    required this.mobileNo,
    required this.purpose,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      "Name": name,
      "Mobile_No": mobileNo,
      "Purpose": purpose,
      "Date": date.toIso8601String(),
    };
  }
}
