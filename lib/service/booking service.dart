import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '/Model/booking.dart'; // ← apna model ka correct path lagao

class PlotService {
  static const String _baseUrl = "https://realapp.cheenu.in/api/booking";

  /// ✅ Check internet connection
  static Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// ✅ Add new plot booking
  static Future<bool> addPlot(PlotInfo plot) async {
    if (!await _hasInternet()) {
      print("⚠️ No internet connection");
      return false;
    }

    final url = Uri.parse("$_baseUrl/add");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(plot.toJson()),
      );

      if (response.statusCode == 200) {
        print("✅ Plot booking added successfully!");
        return true;
      } else {
        print("❌ Failed to add booking: ${response.statusCode}");
        print("Response body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("🚨 Error in addPlot(): $e");
      return false;
    }
  }

  /// ✅ Get pending bookings
  static Future<List<PlotInfo>> getPendingPlots() async {
    return _fetchPlots("$_baseUrl/pending");
  }

  /// ✅ Get booked plots
  static Future<List<PlotInfo>> getBookedPlots() async {
    return _fetchPlots("$_baseUrl/booked");
  }

  /// ✅ Get sellout plots
  static Future<List<PlotInfo>> getSelloutPlots() async {
    return _fetchPlots("$_baseUrl/sellout");
  }

  /// ✅ Common function to fetch and parse plots
  static Future<List<PlotInfo>> _fetchPlots(String url) async {
    if (!await _hasInternet()) {
      print("⚠️ No internet connection");
      return [];
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data.map((e) => PlotInfo.fromJson(e)).toList();
        } else if (data['data'] is List) {
          return (data['data'] as List)
              .map((e) => PlotInfo.fromJson(e))
              .toList();
        } else {
          print("⚠️ Unexpected response format");
          return [];
        }
      } else {
        print("❌ Failed to fetch: ${response.statusCode}");
        print("Response: ${response.body}");
        return [];
      }
    } catch (e) {
      print("🚨 Error in _fetchPlots(): $e");
      return [];
    }
  }
}
