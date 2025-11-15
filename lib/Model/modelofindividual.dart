// /Model/modelofindividual.dart
import 'dart:convert';

/// Response wrapper for MyBooking API
class MyBookingResponse {
  final String message;
  final List<Booking> data;

  MyBookingResponse({required this.message, required this.data});

  factory MyBookingResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    return MyBookingResponse(
      message: json['message']?.toString() ?? '',
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

/// Booking model – matches your API keys exactly
class Booking {
  final int id;
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
  final String purchasePrice;
  final double receivingAmount;
  final double pendingAmount;
  final double totalAmount;
  final double? totalArea;
  final String paidThrough;
  final String? screenshot;

  Booking({
    required this.id,
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

  /// Safe parsing helpers
  double? _parseNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String && v.isNotEmpty) return double.tryParse(v);
    return null;
  }

  double _parseDouble(dynamic v, [double defaultValue = 0.0]) {
    if (v == null) return defaultValue;
    if (v is num) return v.toDouble();
    if (v is String && v.isNotEmpty) return double.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return DateTime.tryParse(s);
    }
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] is num
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      bookedByDealer: json['Booked_ByDealer']?.toString() ?? '',
      projectName: json['Project_Name']?.toString() ?? '',
      plotNumber: json['Plot_Number']?.toString() ?? '',
      plotType: json['Plot_Type']?.toString() ?? '',
      bookingArea: (json['Booking_Area'] is num)
          ? json['Booking_Area'].toDouble()
          : double.tryParse(json['Booking_Area']?.toString() ?? ''),
      bookingStatus: json['Booking_Status']?.toString() ?? '',
      customerName: json['Customer_Name']?.toString() ?? '',
      customerPhnNumber: json['Customer_Phn_Number']?.toString() ?? '',
      dealerPhnNumber: json['Dealer_Phn_Number']?.toString() ?? '',
      bookingDate: (json['Bookingdate'] is String)
          ? DateTime.tryParse(json['Bookingdate'])
          : null,
      purchasePrice: json['Purchase_price']?.toString() ?? '',
      receivingAmount: (json['Receiving_Amount'] is num)
          ? json['Receiving_Amount'].toDouble()
          : double.tryParse(json['Receiving_Amount']?.toString() ?? '') ?? 0.0,
      pendingAmount: (json['Pending_Amount'] is num)
          ? json['Pending_Amount'].toDouble()
          : double.tryParse(json['Pending_Amount']?.toString() ?? '') ?? 0.0,
      totalAmount: (json['Total_Amount'] is num)
          ? json['Total_Amount'].toDouble()
          : double.tryParse(json['Total_Amount']?.toString() ?? '') ?? 0.0,
      totalArea: (json['Total_Area'] is num)
          ? json['Total_Area'].toDouble()
          : double.tryParse(json['Total_Area']?.toString() ?? ''),
      paidThrough: json['Paid_Through']?.toString() ?? '',
      screenshot: (json['Screenshot'] == null ||
          json['Screenshot'].toString().trim().isEmpty)
          ? null
          : json['Screenshot'].toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
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

/// Payment Response Model - handles payment submission response
class PaymentResponse {
  final String message;
  final String paymentStatus;
  final double pendingAmount;
  final double totalReceived;
  final double paidAmount;

  PaymentResponse({
    required this.message,
    required this.paymentStatus,
    required this.pendingAmount,
    required this.totalReceived,
    required this.paidAmount,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      message: json['message']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? 'Pending',
      pendingAmount: _parseDouble(json['pending_amount'], 0.0),
      totalReceived: _parseDouble(json['total_received'], 0.0),
      paidAmount: _parseDouble(json['paidAmount'], 0.0),
    );
  }

  static double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String && value.isNotEmpty) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'payment_status': paymentStatus,
    'pending_amount': pendingAmount,
    'total_received': totalReceived,
    'paidAmount': paidAmount,
  };

  bool get isSuccess => paymentStatus.toLowerCase() == 'approved' || 
                       message.toLowerCase().contains('success');

  bool get isPending => paymentStatus.toLowerCase() == 'pending';

  @override
  String toString() => jsonEncode(toJson());
}