class PlotModel {
  final int id;
  final double totalAmount;
  final double receivingAmount;
  final String paidThrough;
  final String? screenshotBase64;

  PlotModel({
    required this.id,
    required this.totalAmount,
    required this.receivingAmount,
    required this.paidThrough,
    this.screenshotBase64,
  });

  factory PlotModel.fromJson(Map<String, dynamic> json) {
    return PlotModel(
      id: json['id'] ?? 0,
      totalAmount: double.tryParse(json['Total_Amount']?.toString() ?? '0') ?? 0,
      receivingAmount: double.tryParse(json['Receiving_Amount']?.toString() ?? '0') ?? 0,
      paidThrough: json['Paid_Through']?.toString() ?? '',
      screenshotBase64: json['Screenshot']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "Total_Amount": totalAmount,
      "Receiving_Amount": receivingAmount,
      "Paid_Through": paidThrough,
      "Screenshot": screenshotBase64 ?? "",
    };
  }
}
