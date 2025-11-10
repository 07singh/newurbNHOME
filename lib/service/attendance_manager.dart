import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

/// Manages attendance check-in/check-out state persistently
class AttendanceManager {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Storage keys
  static const String _keyIsCheckedIn = 'attendance_is_checked_in';
  static const String _keyCheckInTime = 'attendance_check_in_time';
  static const String _keyCheckInPhotoPath = 'attendance_check_in_photo_path';
  static const String _keyCheckInLatitude = 'attendance_check_in_latitude';
  static const String _keyCheckInLongitude = 'attendance_check_in_longitude';
  static const String _keyCheckInAddress = 'attendance_check_in_address';

  /// Check if user is currently checked in
  static Future<bool> isCheckedIn() async {
    try {
      String? value = await _storage.read(key: _keyIsCheckedIn);
      return value == 'true';
    } catch (e) {
      print('Error checking attendance status: $e');
      return false;
    }
  }

  /// Save check-in data
  static Future<bool> saveCheckIn({
    required DateTime checkInTime,
    File? checkInPhoto,
    Position? checkInPosition,
    String? checkInAddress,
  }) async {
    try {
      await _storage.write(key: _keyIsCheckedIn, value: 'true');
      await _storage.write(key: _keyCheckInTime, value: checkInTime.toIso8601String());
      
      if (checkInPhoto != null) {
        await _storage.write(key: _keyCheckInPhotoPath, value: checkInPhoto.path);
      }
      
      if (checkInPosition != null) {
        await _storage.write(key: _keyCheckInLatitude, value: checkInPosition.latitude.toString());
        await _storage.write(key: _keyCheckInLongitude, value: checkInPosition.longitude.toString());
      }
      
      if (checkInAddress != null) {
        await _storage.write(key: _keyCheckInAddress, value: checkInAddress);
      }
      
      print('Check-in data saved successfully');
      return true;
    } catch (e) {
      print('Error saving check-in data: $e');
      return false;
    }
  }

  /// Retrieve check-in data
  static Future<Map<String, dynamic>?> getCheckInData() async {
    try {
      String? isCheckedIn = await _storage.read(key: _keyIsCheckedIn);
      if (isCheckedIn != 'true') {
        return null;
      }

      String? timeStr = await _storage.read(key: _keyCheckInTime);
      String? photoPath = await _storage.read(key: _keyCheckInPhotoPath);
      String? latitude = await _storage.read(key: _keyCheckInLatitude);
      String? longitude = await _storage.read(key: _keyCheckInLongitude);
      String? address = await _storage.read(key: _keyCheckInAddress);

      DateTime? checkInTime;
      if (timeStr != null) {
        try {
          checkInTime = DateTime.parse(timeStr);
        } catch (e) {
          print('Error parsing check-in time: $e');
        }
      }

      File? checkInPhoto;
      if (photoPath != null && photoPath.isNotEmpty) {
        checkInPhoto = File(photoPath);
        // Verify file exists
        if (!await checkInPhoto.exists()) {
          checkInPhoto = null;
        }
      }

      Position? checkInPosition;
      if (latitude != null && longitude != null) {
        try {
          checkInPosition = Position(
            latitude: double.parse(latitude),
            longitude: double.parse(longitude),
            timestamp: checkInTime ?? DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        } catch (e) {
          print('Error parsing position: $e');
        }
      }

      return {
        'checkInTime': checkInTime,
        'checkInPhoto': checkInPhoto,
        'checkInPosition': checkInPosition,
        'checkInAddress': address,
      };
    } catch (e) {
      print('Error retrieving check-in data: $e');
      return null;
    }
  }

  /// Clear check-in data (called after check-out or logout)
  static Future<void> clearCheckIn() async {
    try {
      await _storage.delete(key: _keyIsCheckedIn);
      await _storage.delete(key: _keyCheckInTime);
      await _storage.delete(key: _keyCheckInPhotoPath);
      await _storage.delete(key: _keyCheckInLatitude);
      await _storage.delete(key: _keyCheckInLongitude);
      await _storage.delete(key: _keyCheckInAddress);
      print('Check-in data cleared successfully');
    } catch (e) {
      print('Error clearing check-in data: $e');
    }
  }
}

