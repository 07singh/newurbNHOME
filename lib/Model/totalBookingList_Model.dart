class TotalBookingListModel {
  final String dealerPhone;
  final List<BookingCommissionHistory> history;

  TotalBookingListModel({
    required this.dealerPhone,
    required this.history,
  });

  factory TotalBookingListModel.fromJson(Map<String, dynamic> json) {
    return TotalBookingListModel(
      dealerPhone: json['dealer_phone'] ?? "",
      history: (json['booking_commission_history'] as List? ?? [])
          .map((e) => BookingCommissionHistory.fromJson(e))
          .toList(),
    );
  }
}

class BookingCommissionHistory {
  final String projectName;
  final String plotNumber;
  final String? bookingDate;
  final String bookingArea;
  final String purchasePrice;
  final double commission;

  BookingCommissionHistory({
    required this.projectName,
    required this.plotNumber,
    required this.bookingDate,
    required this.bookingArea,
    required this.purchasePrice,
    required this.commission,
  });

  factory BookingCommissionHistory.fromJson(Map<String, dynamic> json) {
    return BookingCommissionHistory(
      projectName: json['Project_Name'] ?? "",
      plotNumber: json['Plot_Number'] ?? "",
      bookingDate: json['Bookingdate'],
      bookingArea: json['Booking_Area'] ?? "",
      purchasePrice: json['Purchase_price'] ?? "",
      commission:
      double.tryParse(json['Commission']?.toString() ?? "0") ?? 0.0,
    );
  }
}