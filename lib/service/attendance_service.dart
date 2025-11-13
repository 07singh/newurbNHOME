import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Model/attendance_model.dart';

/// Service for managing attendance check-in and check-out
class AttendanceService {
  static const String _baseUrl = 'https://realapp.cheenu.in/api/attendance/add';

  /// Submit attendance data to the server
  /// 
  /// [attendance] - The attendance model containing check-in/check-out data
  /// 
  /// Returns [AttendanceResponse] on success, throws exception on failure
  static Future<AttendanceResponse> submitAttendance(
    AttendanceModel attendance,
  ) async {
    try {
      // Convert attendance model to JSON
      final jsonBody = attendance.toJson();
      
      // Ensure Action and Status are always set
      if (jsonBody['Action'] == null) {
        jsonBody['Action'] = 'Both';
      }
      if (jsonBody['Status'] == null) {
        jsonBody['Status'] = 'Present';
      }
      
      // Debug: Print what's being sent
      print('📤 Sending attendance data:');
      print('   Action: ${jsonBody['Action']}');
      print('   Status: ${jsonBody['Status']}');
      print('   EmployeeName: ${jsonBody['EmployeeName']}');
      print('   EmpMob: ${jsonBody['EmpMob']}');

      // Make POST request
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(jsonBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      // Parse response
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          return AttendanceResponse.fromJson(responseData);
        } catch (e) {
          // If response is not valid JSON, still return success
          return AttendanceResponse(
            message: 'Attendance submitted successfully',
            status: 'Success',
          );
        }
      } else {
        // Try to parse error response
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(
            errorData['message'] ?? 
            'Failed to submit attendance. Status code: ${response.statusCode}',
          );
        } catch (e) {
          throw Exception(
            'Failed to submit attendance. Status code: ${response.statusCode}\nResponse: ${response.body}',
          );
        }
      }
    } on http.ClientException {
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      if (e.toString().contains('timeout')) {
        rethrow;
      }
      throw Exception('Error submitting attendance: ${e.toString()}');
    }
  }

  /// Submit check-in only
  /// 
  /// [employeeName] - Employee name
  /// [empMob] - Employee mobile number
  /// [checkInTime] - Check-in time in ISO format
  /// [checkInLocation] - Check-in location/address
  /// [checkInImage] - Check-in image as base64 string
  /// [state] - State (optional, can be extracted from location)
  /// [action] - Action type (default: "CheckIn")
  static Future<AttendanceResponse> submitCheckIn({
    required String employeeName,
    required String empMob,
    required String checkInTime,
    required String checkInLocation,
    required String checkInImage,
    String? state,
    String action = 'CheckIn',
  }) async {
    final attendance = AttendanceModel(
      employeeName: employeeName,
      empMob: empMob,
      checkInTime: checkInTime,
      checkInLocation: checkInLocation,
      checkInImage: checkInImage,
      action: action,
      status: 'Present',
      state: state,
    );

    return await submitAttendance(attendance);
  }

  /// Submit check-out only
  /// 
  /// [employeeName] - Employee name
  /// [empMob] - Employee mobile number
  /// [checkOutTime] - Check-out time in ISO format
  /// [checkOutLocation] - Check-out location/address
  /// [checkOutImage] - Check-out image as base64 string
  /// [state] - State (optional, can be extracted from location)
  /// [action] - Action type (default: "CheckOut")
  static Future<AttendanceResponse> submitCheckOut({
    required String employeeName,
    required String empMob,
    required String checkOutTime,
    required String checkOutLocation,
    required String checkOutImage,
    String? state,
    String action = 'CheckOut',
  }) async {
    final attendance = AttendanceModel(
      employeeName: employeeName,
      empMob: empMob,
      checkOutTime: checkOutTime,
      checkOutLocation: checkOutLocation,
      checkOutImage: checkOutImage,
      action: action,
      status: 'Present',
      state: state,
    );

    return await submitAttendance(attendance);
  }

  /// Submit both check-in and check-out
  /// 
  /// [employeeName] - Employee name
  /// [empMob] - Employee mobile number
  /// [checkInTime] - Check-in time in ISO format
  /// [checkOutTime] - Check-out time in ISO format
  /// [checkInLocation] - Check-in location/address
  /// [checkOutLocation] - Check-out location/address
  /// [checkInImage] - Check-in image as base64 string
  /// [checkOutImage] - Check-out image as base64 string
  /// [state] - State (optional, can be extracted from location)
  /// [action] - Action type (default: "Both")
  static Future<AttendanceResponse> submitBoth({
    required String employeeName,
    required String empMob,
    required String checkInTime,
    required String checkOutTime,
    required String checkInLocation,
    required String checkOutLocation,
    required String checkInImage,
    required String checkOutImage,
    String? state,
    String action = 'Both', // Always "Both" for check-out
  }) async {
    // Ensure Action is always "Both" and Status is always "Present" for check-out
    final attendance = AttendanceModel(
      employeeName: employeeName,
      empMob: empMob,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      checkInLocation: checkInLocation,
      checkOutLocation: checkOutLocation,
      checkInImage: checkInImage,
      checkOutImage: checkOutImage,
      action: 'Both', // Explicitly set to "Both" for check-out
      status: 'Present', // Explicitly set to "Present" for check-out
      state: state,
    );

    print('✅ Check-out data prepared:');
    print('   Action: ${attendance.action}');
    print('   Status: ${attendance.status}');

    return await submitAttendance(attendance);
  }
}
