// lib/Model/payment_history_model.dart
// 
// API Response Format from: https://realapp.cheenu.in/Api/AddPaymentHistory
// {
//   "message": "Payments retrieved successfully",
//   "status": "Success",
//   "data": [
//     {
//       "Payment_Id": 1,
//       "Booking_Id": 8,
//       "Paid_Amount": 100.00,
//       "Paid_Through": "Cash",
//       "Screenshot": "" or "Uploads/Payment/...",
//       "Payment_Status": "Pending",
//       "Payment_Date": "2025-11-15T00:00:00",
//       "Booking_Info": {
//         "id": 8,
//         "Project_Name": "Defence phase 2",
//         "Plot_Number": "31",
//         "Customer_Name": "Akahnd",
//         "Booking_Status": "Sellout"
//       }
//     }
//   ]
// }

class PaymentHistoryResponse {
  final String message;
  final String status;
  final List<Payment> data;

  PaymentHistoryResponse({
    required this.message,
    required this.status,
    required this.data,
  });

  factory PaymentHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryResponse(
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => Payment.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Payment {
  final int paymentId;
  final int bookingId;
  final double paidAmount;
  final String paidThrough;
  final String screenshot;
  final String paymentStatus;
  final DateTime paymentDate;
  final BookingInfo bookingInfo;

  Payment({
    required this.paymentId,
    required this.bookingId,
    required this.paidAmount,
    required this.paidThrough,
    required this.screenshot,
    required this.paymentStatus,
    required this.paymentDate,
    required this.bookingInfo,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paymentId: json['Payment_Id'] as int? ?? 0,
      bookingId: json['Booking_Id'] as int? ?? 0,
      paidAmount: (json['Paid_Amount'] as num?)?.toDouble() ?? 0.0,
      paidThrough: json['Paid_Through'] as String? ?? '',
      screenshot: json['Screenshot'] as String? ?? '',
      paymentStatus: json['Payment_Status'] as String? ?? 'Pending',
      paymentDate: _parseDateTime(json['Payment_Date']),
      bookingInfo: BookingInfo.fromJson(
        json['Booking_Info'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// Parses Payment_Date from API response
  /// Handles ISO 8601 format: "2025-11-15T00:00:00"
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    try {
      if (dateValue is String) {
        // Handles ISO 8601 format: "2025-11-15T00:00:00"
        return DateTime.parse(dateValue);
      }
      return DateTime.now();
    } catch (e) {
      print('⚠️ Failed to parse Payment_Date: $dateValue, error: $e');
      return DateTime.now();
    }
  }
}

class BookingInfo {
  final int id;
  final String projectName;
  final String plotNumber;
  final String customerName;
  final String bookingStatus;

  BookingInfo({
    required this.id,
    required this.projectName,
    required this.plotNumber,
    required this.customerName,
    required this.bookingStatus,
  });

  factory BookingInfo.fromJson(Map<String, dynamic> json) {
    return BookingInfo(
      id: json['id'] as int? ?? 0,
      projectName: json['Project_Name'] as String? ?? '',
      plotNumber: json['Plot_Number'] as String? ?? '',
      customerName: json['Customer_Name'] as String? ?? '',
      bookingStatus: json['Booking_Status'] as String? ?? 'Pending',
    );
  }
}