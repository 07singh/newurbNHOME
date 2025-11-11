import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../Model/attendance_model.dart';
import 'package:path/path.dart' as path;

class AttendanceService {
  static const String baseUrl = "https://realapp.cheenu.in";
  static const String addAttendanceEndpoint = "/api/attendance/add";

  /// Submit attendance check-in with all details
  /// 
  /// Parameters:
  /// - [employeeName]: Name of the employee
  /// - [mobile]: Mobile number of the employee
  /// - [checkInTime]: Check-in timestamp (ISO 8601 format)
  /// - [latitude]: GPS latitude
  /// - [longitude]: GPS longitude
  /// - [address]: Human-readable address (optional)
  /// - [imageFile]: Check-in photo file (optional)
  /// 
  /// Returns [AttendanceModel] with server response
  static Future<AttendanceModel?> submitAttendance({
    required String employeeName,
    required String mobile,
    required String checkInTime,
    required double latitude,
    required double longitude,
    String? address,
    File? imageFile,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$addAttendanceEndpoint');

      // Validate data before sending
      if (employeeName.isEmpty) {
        debugPrint('⚠️ Warning: employeeName is empty!');
      }
      if (mobile.isEmpty) {
        debugPrint('⚠️ Warning: mobile is empty!');
      }

      // Prepare location string
      String checkInLocation = address ?? '';
      if (checkInLocation.isEmpty) {
        checkInLocation = 'Lat: ${latitude.toStringAsFixed(6)}, Long: ${longitude.toStringAsFixed(6)}';
      }

      // Prepare JSON payload (matching server's exact model)
      Map<String, dynamic> payload = {
        'EmployeeName': employeeName.trim(),
        'EmpMob': mobile.trim(),
        'CheckInTime': checkInTime,
        'CheckInLocation': checkInLocation,
        'Status': 'Present',
        'Action': 'CheckIn',
      };

      // Encode image to base64 if available
      if (imageFile != null && await imageFile.exists()) {
        try {
          final bytes = await imageFile.readAsBytes();
          final base64Image = base64Encode(bytes);
          
          payload['CheckInImage'] = base64Image;
          
          debugPrint('✅ Image encoded to base64 (${bytes.length} bytes)');
        } catch (e) {
          debugPrint('⚠️ Failed to encode image: $e');
          // Continue without image if encoding fails
        }
      }

      debugPrint('📤 Sending attendance data to: $url');
      debugPrint('📋 Payload keys: ${payload.keys.toList()}');
      debugPrint('📋 EmployeeName: $employeeName');
      debugPrint('📋 EmpMob: $mobile');
      debugPrint('📋 CheckInLocation: $checkInLocation');

      // Send POST request with JSON body
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return AttendanceModel.fromJson(data);
      } else if (response.statusCode == 400) {
        // Try to parse error message from server
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['Message'] ?? errorData['message'] ?? 'Invalid data. Please check all fields.';
          return AttendanceModel(
            message: errorMessage,
            employeeId: null,
            hoursWorked: null,
          );
        } catch (e) {
          return AttendanceModel(
            message: 'Invalid data. Please check all fields.',
            employeeId: null,
            hoursWorked: null,
          );
        }
      } else if (response.statusCode == 404) {
        return AttendanceModel(
          message: 'Server endpoint not found.',
          employeeId: null,
          hoursWorked: null,
        );
      } else if (response.statusCode == 415) {
        return AttendanceModel(
          message: 'Unsupported media type. Server configuration issue.',
          employeeId: null,
          hoursWorked: null,
        );
      } else if (response.statusCode == 500) {
        return AttendanceModel(
          message: 'Server error. Please try again later.',
          employeeId: null,
          hoursWorked: null,
        );
      } else {
        // Try to get error message from response
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['Message'] ?? errorData['message'] ?? 'Failed to submit attendance';
          return AttendanceModel(
            message: '$errorMessage (Status: ${response.statusCode})',
            employeeId: null,
            hoursWorked: null,
          );
        } catch (e) {
          return AttendanceModel(
            message: 'Failed to submit attendance. Status: ${response.statusCode}',
            employeeId: null,
            hoursWorked: null,
          );
        }
      }
    } on SocketException {
      debugPrint('❌ Network error: No internet connection');
      return AttendanceModel(
        message: 'No internet connection. Please check your network.',
        employeeId: null,
        hoursWorked: null,
      );
    } on http.ClientException catch (e) {
      debugPrint('❌ HTTP Client error: $e');
      return AttendanceModel(
        message: 'Network error. Please try again.',
        employeeId: null,
        hoursWorked: null,
      );
    } on FormatException catch (e) {
      debugPrint('❌ JSON parsing error: $e');
      return AttendanceModel(
        message: 'Invalid server response.',
        employeeId: null,
        hoursWorked: null,
      );
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return AttendanceModel(
        message: 'Something went wrong: ${e.toString()}',
        employeeId: null,
        hoursWorked: null,
      );
    }
  }

  /// Submit complete attendance (both check-in and check-out)
  /// 
  /// Parameters:
  /// - [employeeName]: Name of the employee
  /// - [mobile]: Mobile number of the employee
  /// - [checkInTime]: Check-in timestamp (ISO 8601 format)
  /// - [checkOutTime]: Check-out timestamp (ISO 8601 format)
  /// - [checkInLocation]: Check-in location address
  /// - [checkOutLocation]: Check-out location address
  /// - [checkInImageFile]: Check-in photo file (optional)
  /// - [checkOutImageFile]: Check-out photo file (optional)
  /// 
  /// Returns [AttendanceModel] with server response
  static Future<AttendanceModel?> submitCompleteAttendance({
    required String employeeName,
    required String mobile,
    required String checkInTime,
    required String checkOutTime,
    required String checkInLocation,
    required String checkOutLocation,
    File? checkInImageFile,
    File? checkOutImageFile,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$addAttendanceEndpoint');

      // Validate data before sending
      if (employeeName.isEmpty) {
        debugPrint('⚠️ Warning: employeeName is empty!');
      }
      if (mobile.isEmpty) {
        debugPrint('⚠️ Warning: mobile is empty!');
      }

      // Prepare JSON payload (matching server's exact model)
      Map<String, dynamic> payload = {
        'EmployeeName': employeeName.trim(),
        'EmpMob': mobile.trim(),
        'CheckInTime': checkInTime,
        'CheckOutTime': checkOutTime,
        'CheckInLocation': checkInLocation,
        'CheckOutLocation': checkOutLocation,
        'Status': 'Present',
        'Action': 'Both',
      };

      // Encode check-in image to base64 if available
      if (checkInImageFile != null && await checkInImageFile.exists()) {
        try {
          final bytes = await checkInImageFile.readAsBytes();
          final base64Image = base64Encode(bytes);
          payload['CheckInImage'] = base64Image;
          debugPrint('✅ CheckIn image encoded to base64 (${bytes.length} bytes)');
        } catch (e) {
          debugPrint('⚠️ Failed to encode check-in image: $e');
        }
      }

      // Encode check-out image to base64 if available
      if (checkOutImageFile != null && await checkOutImageFile.exists()) {
        try {
          final bytes = await checkOutImageFile.readAsBytes();
          final base64Image = base64Encode(bytes);
          payload['CheckOutImage'] = base64Image;
          debugPrint('✅ CheckOut image encoded to base64 (${bytes.length} bytes)');
        } catch (e) {
          debugPrint('⚠️ Failed to encode check-out image: $e');
        }
      }

      debugPrint('📤 Sending complete attendance data to: $url');
      debugPrint('📋 Payload keys: ${payload.keys.toList()}');
      debugPrint('📋 Action: Both (Check-in + Check-out)');

      // Send POST request with JSON body
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return AttendanceModel.fromJson(data);
      } else if (response.statusCode == 400) {
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['Message'] ?? errorData['message'] ?? 'Invalid data. Please check all fields.';
          return AttendanceModel(
            message: errorMessage,
            employeeId: null,
            hoursWorked: null,
          );
        } catch (e) {
          return AttendanceModel(
            message: 'Invalid data. Please check all fields.',
            employeeId: null,
            hoursWorked: null,
          );
        }
      } else if (response.statusCode == 404) {
        return AttendanceModel(
          message: 'Server endpoint not found.',
          employeeId: null,
          hoursWorked: null,
        );
      } else if (response.statusCode == 415) {
        return AttendanceModel(
          message: 'Unsupported media type. Server configuration issue.',
          employeeId: null,
          hoursWorked: null,
        );
      } else if (response.statusCode == 500) {
        return AttendanceModel(
          message: 'Server error. Please try again later.',
          employeeId: null,
          hoursWorked: null,
        );
      } else {
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['Message'] ?? errorData['message'] ?? 'Failed to submit attendance';
          return AttendanceModel(
            message: '$errorMessage (Status: ${response.statusCode})',
            employeeId: null,
            hoursWorked: null,
          );
        } catch (e) {
          return AttendanceModel(
            message: 'Failed to submit attendance. Status: ${response.statusCode}',
            employeeId: null,
            hoursWorked: null,
          );
        }
      }
    } on SocketException {
      debugPrint('❌ Network error: No internet connection');
      return AttendanceModel(
        message: 'No internet connection. Please check your network.',
        employeeId: null,
        hoursWorked: null,
      );
    } on http.ClientException catch (e) {
      debugPrint('❌ HTTP Client error: $e');
      return AttendanceModel(
        message: 'Network error. Please try again.',
        employeeId: null,
        hoursWorked: null,
      );
    } on FormatException catch (e) {
      debugPrint('❌ JSON parsing error: $e');
      return AttendanceModel(
        message: 'Invalid server response.',
        employeeId: null,
        hoursWorked: null,
      );
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return AttendanceModel(
        message: 'Something went wrong: ${e.toString()}',
        employeeId: null,
        hoursWorked: null,
      );
    }
  }

  /// Validate attendance data before submission
  static bool validateAttendanceData({
    required String employeeName,
    required String mobile,
    required double latitude,
    required double longitude,
  }) {
    if (employeeName.isEmpty) {
      debugPrint('⚠️ Validation failed: Employee name is empty');
      return false;
    }

    if (mobile.isEmpty || mobile.length < 10) {
      debugPrint('⚠️ Validation failed: Invalid mobile number');
      return false;
    }

    if (latitude == 0.0 || longitude == 0.0) {
      debugPrint('⚠️ Validation failed: Invalid location coordinates');
      return false;
    }

    return true;
  }
}

