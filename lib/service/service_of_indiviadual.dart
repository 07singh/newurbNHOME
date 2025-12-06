// services/booking_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/modelofindividual.dart';

/// Service for managing booking-related API operations
class BookingService {
  static const String _base = 'https://realapp.cheenu.in/Api';
  static const Duration _timeout = Duration(seconds: 30);

  /// Fetch bookings for a given phone number
  /// 
  /// Returns a list of [Booking] objects associated with the phone number.
  /// Throws [Exception] if the request fails or network error occurs.
  Future<List<Booking>> fetchBookingsForPhone(String phone) async {
    if (phone.trim().isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }

    final url = Uri.parse('$_base/MyBookingIndividualRecord?phone=${Uri.encodeComponent(phone)}');
    
    try {
      final response = await http.get(url).timeout(_timeout);
      
      if (response.statusCode == 200) {
        try {
          final jsonBody = json.decode(response.body) as Map<String, dynamic>;
          final resp = MyBookingResponse.fromJson(jsonBody);
          return resp.data;
        } catch (parseError) {
          print('Parse error in fetchBookingsForPhone: $parseError');
          print('Response body: ${response.body}');
          throw Exception('Failed to parse booking data');
        }
      } else {
        throw Exception('Failed to load bookings: HTTP ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('Network error in fetchBookingsForPhone: $e');
      throw Exception('Network error: ${e.message}');
    } on Exception {
      rethrow;
    } catch (e) {
      print('Unexpected error in fetchBookingsForPhone: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Add Payment - Submits a payment for a booking
  /// 
  /// API Endpoint: POST https://realapp.cheenu.in/Api/AddPayment/Add
  /// 
  /// Request Body Format:
  /// {
  ///   "Booking_Id": 7,
  ///   "Paid_Amount": 100.00,
  ///   "Paid_Through": "Bank Transfer",
  ///   "Screenshot": "base64_string_or_empty",
  ///   "Payment_Date": "2025-02-14"
  /// }
  /// 
  /// [bookingId] - The ID of the booking
  /// [paidAmount] - The amount being paid (must be > 0)
  /// [paidThrough] - Payment method (e.g., "UPI Payment", "NEFT", "Cash", "Bank Transfer")
  /// [screenshotBase64] - Optional base64 encoded image of payment proof
  /// [paymentDate] - Payment date in format "YYYY-MM-DD"
  /// 
  /// Returns [PaymentResponse] with payment details including status, pending amount, etc.
  /// Throws [Exception] on network errors or API errors (400, 500, etc.).
  Future<PaymentResponse?> addPayment({
    required int bookingId,
    required double paidAmount,
    required String paidThrough,
    required String? screenshotBase64,
    required String paymentDate,
  }) async {
    // Input validation
    if (bookingId <= 0) {
      throw ArgumentError('Booking ID must be greater than 0');
    }
    if (paidAmount <= 0) {
      throw ArgumentError('Paid amount must be greater than 0');
    }
    if (paidThrough.trim().isEmpty) {
      throw ArgumentError('Payment method cannot be empty');
    }
    if (paymentDate.trim().isEmpty) {
      throw ArgumentError('Payment date cannot be empty');
    }

    final url = Uri.parse('$_base/AddPayment/Add');

    // Validate payment date - should not be in the future
    try {
      final parsedDate = DateTime.parse(paymentDate.trim());
      final now = DateTime.now();
      if (parsedDate.isAfter(now)) {
        throw ArgumentError('Payment date cannot be in the future');
      }
    } catch (e) {
      if (e is ArgumentError) rethrow;
      throw ArgumentError('Invalid payment date format. Expected YYYY-MM-DD');
    }

    // Build request body matching API specification exactly:
    // {
    //   "Booking_Id": 7,
    //   "Paid_Amount": 100.00,
    //   "Paid_Through": "Bank Transfer",
    //   "Screenshot": "base64_string_or_empty",
    //   "Payment_Date": "2025-02-14"
    // }
    final body = {
      "Booking_Id": bookingId,
      "Paid_Amount": paidAmount,
      "Paid_Through": paidThrough.trim(),
      "Screenshot": screenshotBase64?.trim() ?? "",
      "Payment_Date": paymentDate.trim(),
    };

    // Debug logging
    print('📤 AddPayment Request:');
    print('   URL: $url');
    print('   Booking_Id: ${body["Booking_Id"]}');
    print('   Paid_Amount: ${body["Paid_Amount"]}');
    print('   Paid_Through: ${body["Paid_Through"]}');
    print('   Screenshot length: ${(body["Screenshot"] as String).length} chars');
    print('   Payment_Date: ${body["Payment_Date"]}');
    print('   Request Body: ${json.encode(body)}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final result = json.decode(response.body) as Map<String, dynamic>;
          return PaymentResponse.fromJson(result);
        } catch (parseError) {
          print('AddPayment parse error: $parseError');
          print('Response body: ${response.body}');
          
          // Try to extract message from response if possible
          String message = 'Payment submitted';
          try {
            final fallbackJson = json.decode(response.body) as Map<String, dynamic>;
            message = fallbackJson['message']?.toString() ?? message;
          } catch (_) {
            // If response is not JSON, use raw body
            message = response.body.isNotEmpty ? response.body : message;
          }
          
          // Fallback: create response from available data
          return PaymentResponse(
            message: message,
            paymentStatus: 'Unknown',
            pendingAmount: 0.0,
            totalReceived: 0.0,
            paidAmount: paidAmount,
          );
        }
      }
      
      // Handle error responses (400, 500, etc.)
      print('AddPayment failed: Status ${response.statusCode}, Body: ${response.body}');
      
      // Try to extract error message from response body
      String errorMessage = 'Payment submission failed';
      String? detailedError;
      Map<String, dynamic>? errorJson;
      
      try {
        errorJson = json.decode(response.body) as Map<String, dynamic>;
        errorMessage = errorJson['Message']?.toString() ?? 
                      errorJson['message']?.toString() ?? 
                      errorJson['error']?.toString() ?? 
                      errorMessage;
        
        // Try to get more detailed error information
        detailedError = errorJson['ExceptionMessage']?.toString() ?? 
                       errorJson['exceptionMessage']?.toString() ??
                       errorJson['detail']?.toString() ??
                       errorJson['StackTrace']?.toString();
      } catch (_) {
        // If response is not JSON, try to use raw body if it's meaningful
        if (response.body.isNotEmpty && response.body.length < 200) {
          errorMessage = response.body;
        }
      }
      
      // Provide more helpful messages based on status code
      if (response.statusCode >= 500) {
        // Server error - provide user-friendly message with retry suggestion
        if (errorMessage.toLowerCase().contains('error has occurred') || 
            errorMessage.toLowerCase().contains('an error has occurred')) {
          // Check for common server-side issues
          String helpfulMessage = 'Server error occurred. ';
          
          // Check if it might be a date validation issue
          final paymentDateStr = body['Payment_Date']?.toString() ?? '';
          try {
            final paymentDate = DateTime.parse(paymentDateStr);
            final now = DateTime.now();
            if (paymentDate.isAfter(now)) {
              helpfulMessage += 'Payment date cannot be in the future. Please select today or a past date.';
            } else {
              helpfulMessage += 'Please check:\n';
              helpfulMessage += '• Payment date is valid (not in future)\n';
              helpfulMessage += '• Amount does not exceed pending amount\n';
              helpfulMessage += '• Booking ID is valid\n';
              helpfulMessage += '\nIf the problem persists, contact support.';
            }
          } catch (_) {
            helpfulMessage += 'Please verify all payment details and try again. If the problem persists, contact support.';
          }
          
          errorMessage = helpfulMessage;
        } else {
          errorMessage = 'Server error: $errorMessage. Please try again.';
        }
      } else if (response.statusCode == 400) {
        // Client error - show the actual error message
        if (errorMessage.toLowerCase().contains('exceeds') || 
            errorMessage.toLowerCase().contains('pending amount')) {
          // Keep the original message for validation errors
          // errorMessage is already set correctly
        } else {
          errorMessage = 'Invalid request: $errorMessage';
        }
      }
      
      // Log detailed error for debugging if available
      if (detailedError != null && detailedError.isNotEmpty) {
        print('AddPayment detailed error: $detailedError');
      }
      
      // Log full error response for debugging
      print('AddPayment full error response: $errorJson');
      
      // Throw exception with the extracted error message
      throw Exception(errorMessage);
    } on http.ClientException catch (e) {
      print('AddPayment network error: $e');
      throw Exception('Network error: ${e.message}');
    } on Exception {
      rethrow;
    } catch (e) {
      print('AddPayment unexpected error: $e');
      throw Exception('Unexpected error: $e');
    }
  }
}