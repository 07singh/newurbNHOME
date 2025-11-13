import 'dart:convert';

class MyBookingResponse {
  final String message;
  final List<Booking> data;

  MyBookingResponse({required this.message, required this.data});

  factory MyBookingResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    return MyBookingResponse(
      message: json['message'] as String? ?? '',
      data: dataList.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'data': data.map((b) => b.toJson()).toList(),
  };

  @override
  String toString() => jsonEncode(toJson());
}

class Booking {
  final String bookedByDealer;
  final String projectName;
  final String plotNumber;
  final String plotType;
  final double? bookingArea;
  final String bookingStatus;
  final String customerName;
  final String customerPhnNumber;
  final String dealerPhnNumber;
  final DateTime? bookingDate;
  final String purchasePrice; // kept as String because JSON had "10"
  final double receivingAmount;
  final double pendingAmount;
  final double totalAmount;
  final double? totalArea;
  final String paidThrough;
  final String? screenshot;

  Booking({
    required this.bookedByDealer,
    required this.projectName,
    required this.plotNumber,
    required this.plotType,
    this.bookingArea,
    required this.bookingStatus,
    required this.customerName,
    required this.customerPhnNumber,
    required this.dealerPhnNumber,
    this.bookingDate,
    required this.purchasePrice,
    required this.receivingAmount,
    required this.pendingAmount,
    required this.totalAmount,
    this.totalArea,
    required this.paidThrough,
    this.screenshot,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    double? parseNullableDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String && v.isNotEmpty) return double.tryParse(v);
      return null;
    }

    double parseDoubleWithDefault(dynamic v, [double defaultValue = 0]) {
      if (v == null) return defaultValue;
      if (v is num) return v.toDouble();
      if (v is String && v.isNotEmpty) return double.tryParse(v) ?? defaultValue;
      return defaultValue;
    }

    DateTime? parseNullableDate(String? s) {
      if (s == null || s.isEmpty) return null;
      // try parsing yyyy-MM-dd or full iso
      try {
        return DateTime.parse(s);
      } catch (_) {
        try {
          // fallback: try common format
          return DateTime.tryParse(s);
        } catch (_) {
          return null;
        }
      }
    }

    return Booking(
      bookedByDealer: json['Booked_ByDealer']?.toString() ?? '',
      projectName: json['Project_Name']?.toString() ?? '',
      plotNumber: json['Plot_Number']?.toString() ?? '',
      plotType: json['Plot_Type']?.toString() ?? '',
      bookingArea: parseNullableDouble(json['Booking_Area']),
      bookingStatus: json['Booking_Status']?.toString() ?? '',
      customerName: json['Customer_Name']?.toString() ?? '',
      customerPhnNumber: json['Customer_Phn_Number']?.toString() ?? '',
      dealerPhnNumber: json['Dealer_Phn_Number']?.toString() ?? '',
      bookingDate: parseNullableDate(json['Bookingdate']?.toString()),
      purchasePrice: json['Purchase_price']?.toString() ?? '',
      receivingAmount: parseDoubleWithDefault(json['Receiving_Amount'], 0.0),
      pendingAmount: parseDoubleWithDefault(json['Pending_Amount'], 0.0),
      totalAmount: parseDoubleWithDefault(json['Total_Amount'], 0.0),
      totalArea: parseNullableDouble(json['Total_Area']),
      paidThrough: json['Paid_Through']?.toString() ?? '',
      screenshot: (json['Screenshot'] == null || json['Screenshot'].toString().isEmpty)
          ? null
          : json['Screenshot'].toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'Booked_ByDealer': bookedByDealer,
    'Project_Name': projectName,
    'Plot_Number': plotNumber,
    'Plot_Type': plotType,
    'Booking_Area': bookingArea,
    'Booking_Status': bookingStatus,
    'Customer_Name': customerName,
    'Customer_Phn_Number': customerPhnNumber,
    'Dealer_Phn_Number': dealerPhnNumber,
    'Bookingdate': bookingDate?.toIso8601String(),
    'Purchase_price': purchasePrice,
    'Receiving_Amount': receivingAmount,
    'Pending_Amount': pendingAmount,
    'Total_Amount': totalAmount,
    'Total_Area': totalArea,
    'Paid_Through': paidThrough,
    'Screenshot': screenshot,
  };

  @override
  String toString() => toJson().toString();
}