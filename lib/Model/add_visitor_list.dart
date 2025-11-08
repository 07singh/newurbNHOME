class Visitor {
  final int id;
  final String? name;
  final String? mobileNo;
  final String? purpose;
  final DateTime? date;

  Visitor({
    required this.id,
    this.name,
    this.mobileNo,
    this.purpose,
    this.date,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['Id'],
      name: json['Name'],
      mobileNo: json['Mobile_No'],
      purpose: json['Purpose'],
      date: json['Date'] != null ? DateTime.parse(json['Date']) : null,
    );
  }
}
