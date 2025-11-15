class PaymentModel {
  final int paymentId;
  final int bookingId;
  final double paidAmount;
  final String paidThrough;
  final String screenshot;
  final String paymentStatus;
  final String paymentDate;
  final Map<String, dynamic> bookingInfo;

  PaymentModel({
    required this.paymentId,
    required this.bookingId,
    required this.paidAmount,
    required this.paidThrough,
    required this.screenshot,
    required this.paymentStatus,
    required this.paymentDate,
    required this.bookingInfo,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId: json['Payment_Id'],
      bookingId: json['Booking_Id'],
      paidAmount: json['Paid_Amount'].toDouble(),
      paidThrough: json['Paid_Through'],
      screenshot: json['Screenshot'],
      paymentStatus: json['Payment_Status'],
      paymentDate: json['Payment_Date'],
      bookingInfo: json['Booking_Info'],
    );
  }
}