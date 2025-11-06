class Booking {
  String projectName;
  String plotNumber;
  String bookingArea;
  String totalArea;
  double purchasePrice;
  double totalAmount;
  double receivingAmount;
  double pendingAmount;
  String paidThrough;
  String screenshot;
  String bookingDate;
  String bookedByDealer;
  String customerName;
  String customerPhnNumber;
  String dealerPhnNumber;
  bool status;

  Booking({
    required this.projectName,
    required this.plotNumber,
    required this.bookingArea,
    required this.totalArea,
    required this.purchasePrice,
    required this.totalAmount,
    required this.receivingAmount,
    required this.pendingAmount,
    required this.paidThrough,
    required this.screenshot,
    required this.bookingDate,
    required this.bookedByDealer,
    required this.customerName,
    required this.customerPhnNumber,
    required this.dealerPhnNumber,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      projectName: json['Project_Name'],
      plotNumber: json['Plot_Number'],
      bookingArea: json['Booking_Area'],
      totalArea: json['Total_Area'],
      purchasePrice: (json['Purchase_price'] as num).toDouble(),
      totalAmount: (json['Total_Amount'] as num).toDouble(),
      receivingAmount: (json['Receiving_Amount'] as num).toDouble(),
      pendingAmount: (json['Pending_Amount'] as num).toDouble(),
      paidThrough: json['Paid_Through'],
      screenshot: json['Screenshot'],
      bookingDate: json['Bookingdate'],
      bookedByDealer: json['Booked_ByDealer'],
      customerName: json['Customer_Name'],
      customerPhnNumber: json['Customer_Phn_Number'],
      dealerPhnNumber: json['Dealer_Phn_Number'],
      status: json['Status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "Project_Name": projectName,
      "Plot_Number": plotNumber,
      "Booking_Area": bookingArea,
      "Total_Area": totalArea,
      "Purchase_price": purchasePrice,
      "Total_Amount": totalAmount,
      "Receiving_Amount": receivingAmount,
      "Pending_Amount": pendingAmount,
      "Paid_Through": paidThrough,
      "Screenshot": screenshot,
      "Bookingdate": bookingDate,
      "Booked_ByDealer": bookedByDealer,
      "Customer_Name": customerName,
      "Customer_Phn_Number": customerPhnNumber,
      "Dealer_Phn_Number": dealerPhnNumber,
      "Status": status,
    };
  }
}
