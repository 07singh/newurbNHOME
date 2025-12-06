import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../Model/associate_model.dart';
import 'plot_refresh_notifier.dart';
import '../service/associate_list_service.dart';
import '../service/auth_manager.dart';

enum AreaUnit { sqYds, sqFt }
enum BookingStatus { available, pending, booked, sellout }

class PlotInfo {
  final String id;
  String area;
  AreaUnit areaUnit;
  double fare;
  double _receivingAmount = 0;
  double totalAmount = 0;
  double pendingAmount = 0;
  String clientName = '';
  String? photoPath;
  double bookedArea = 0;
  String projectName;
  double purchasePrice = 0;
  String paidThrough = 'Online Transfer';
  DateTime bookingDate;
  String bookedByDealer = '';
  String customerPhone = '';
  String dealerPhone = '';
  bool status = true;
  BookingStatus bookingStatus = BookingStatus.available;
  String plotType;


  // मुख्य कंस्ट्रक्टर
  PlotInfo({
    required this.id,
    required this.area,
    this.areaUnit = AreaUnit.sqYds,
    required this.fare,
    double receivingAmount = 0,
    this.totalAmount = 0,
    this.pendingAmount = 0,
    this.clientName = '',
    this.photoPath,
    this.bookedArea = 0,
    required this.projectName,
    this.purchasePrice = 0,
    this.paidThrough = 'Online Transfer',
    DateTime? bookingDate,
    this.bookedByDealer = '',
    this.customerPhone = '',
    this.dealerPhone = '',
    this.status = true,
    this.bookingStatus = BookingStatus.available,
    required this.plotType,
  }) : bookingDate = bookingDate ?? DateTime.now(),
        _receivingAmount = receivingAmount {
    _updateAmounts();
  }

  // CLONE FACTORY CONSTRUCTOR – यहाँ है!
  factory PlotInfo.clone(PlotInfo other) {
    return PlotInfo(
      id: other.id,
      area: other.area,
      areaUnit: other.areaUnit,
      fare: other.fare,
      receivingAmount: other._receivingAmount,
      totalAmount: other.totalAmount,
      pendingAmount: other.pendingAmount,
      clientName: other.clientName,
      photoPath: other.photoPath,
      bookedArea: other.bookedArea,
      projectName: other.projectName,
      purchasePrice: other.purchasePrice,
      paidThrough: other.paidThrough,
      bookingDate: other.bookingDate,
      bookedByDealer: other.bookedByDealer,
      customerPhone: other.customerPhone,
      dealerPhone: other.dealerPhone,
      status: other.status,
      bookingStatus: other.bookingStatus,
      plotType: other.plotType,
    );
  }

  // GETTER & SETTER
  double get receivingAmount => _receivingAmount;
  set receivingAmount(double value) {
    _receivingAmount = value;
    pendingAmount = totalAmount - value;
  }

  double get paidAmount => receivingAmount; // backward compatibility

  void _updateAmounts() {
    final bookedInYds = _convertToYards(bookedArea, areaUnit);
    totalAmount = fare * bookedInYds;
    pendingAmount = totalAmount - _receivingAmount;
    purchasePrice = fare;
  }

  double _convertToYards(double value, AreaUnit unit) {
    return unit == AreaUnit.sqFt ? value / 9.0 : value;
  }

  double _parseArea(String area, AreaUnit unit) {
    if (area.isEmpty) return 0.0;
    final cleaned = area.replaceAll(RegExp(r'[a-zA-Z]'), '').replaceAll(RegExp(r'[^0-9.]'), '');
    final value = double.tryParse(cleaned);
    return value == null ? 0.0 : (unit == AreaUnit.sqFt ? value / 9.0 : value);
  }

  double get totalAreaValue => _parseArea(area, areaUnit);
  double get remainingArea => totalAreaValue - _convertToYards(bookedArea, areaUnit);
  double get bookedPercentage => totalAreaValue > 0 ? _convertToYards(bookedArea, areaUnit) / totalAreaValue : 0;
  double get paidPercentage => totalAmount > 0 ? (receivingAmount / totalAmount) * 100 : 0;

  void updateCalculations({double? newFare, double? newBookedArea, AreaUnit? newUnit}) {
    if (newFare != null) fare = newFare;
    if (newBookedArea != null) bookedArea = newBookedArea;
    if (newUnit != null) areaUnit = newUnit;
    _updateAmounts();
  }


  // COLOR LOGIC
  Color get color {
    switch (bookingStatus) {
      case BookingStatus.available:
        return Colors.green.shade300;
      case BookingStatus.pending:
        if (paidPercentage < 50) return Colors.red.shade300;
        if (paidPercentage >= 50 && paidPercentage < 100) return Colors.yellow.shade300;
        return Colors.grey.shade400;
      case BookingStatus.booked:
        return Colors.blue.shade300;
      case BookingStatus.sellout:
        return Colors.grey.shade400;
    }
    return Colors.green.shade300;
  }

  // STATUS TEXT
  String get statusText {
    switch (bookingStatus) {
      case BookingStatus.available:
        return "Available";
      case BookingStatus.pending:
        if (paidPercentage < 50) return "Pending (<50%)";
        if (paidPercentage >= 50 && paidPercentage < 100) return "Pending (≥50%)";
        return "Sold Out";
      case BookingStatus.booked:
        return "Booked";
      case BookingStatus.sellout:
        return "Sold Out";
    }
    return "Available";
  }

  // JSON SERIALIZATION
  Map<String, dynamic> toJson() {
    final totalAreaValue = _parseArea(area, areaUnit);
    final bookedAreaInYds = _convertToYards(bookedArea, areaUnit);
    final remaining = (totalAreaValue - bookedAreaInYds).toStringAsFixed(1);

    String screenshot = photoPath ?? '';
    if (photoPath != null && File(photoPath!).existsSync()) {
      final bytes = File(photoPath!).readAsBytesSync();
      screenshot = base64Encode(bytes);
    }

    String statusStr;
    switch (bookingStatus) {
      case BookingStatus.available: statusStr = 'available'; break;
      case BookingStatus.pending:   statusStr = 'pending';   break;
      case BookingStatus.booked:    statusStr = 'booked';    break;
      case BookingStatus.sellout:   statusStr = 'sellout';   break;
    }

    return {
      'Project_Name': projectName,
      'Purchase_price': fare.toStringAsFixed(0),
      'Receiving_Amount': receivingAmount,
      'Pending_Amount': pendingAmount,
      'Paid_Through': paidThrough,
      'Booked_ByDealer': bookedByDealer,
      'Customer_Name': clientName,
      'Customer_Phn_Number': customerPhone,
      'Dealer_Phn_Number': dealerPhone,
      'Bookingdate': bookingDate.toIso8601String().split('T')[0],
      'Status': status,
      'Plot_Number': id,
      'Total_Area': totalAreaValue.toStringAsFixed(1),
      'Booking_Area': bookedAreaInYds.toStringAsFixed(1),
      'Screenshot': screenshot,
      'Total_Amount': totalAmount.toInt(),
      'Booking_Status': statusStr,
      'Plot_Type': plotType,
      'Remaining_Area': remaining,
    };
  }

  // JSON DESERIALIZATION
  factory PlotInfo.fromJson(Map<String, dynamic> json) {
    final areaStr = json['Total_Area']?.toString() ?? '0';
    final unitStr = json['Area_Unit']?.toString() ?? 'Sq.Yds';
    final areaUnit = unitStr.contains('sq ft') ? AreaUnit.sqFt : AreaUnit.sqYds;

    final totalAreaValue = double.tryParse(areaStr) ?? 0;
    final bookedAreaValue = double.tryParse(json['Booking_Area']?.toString() ?? '0') ?? 0;
    final area = '$totalAreaValue ${areaUnit == AreaUnit.sqYds ? 'Sq.Yds' : 'sq ft'}';

    final fare = double.tryParse(json['Purchase_price']?.toString() ?? '0') ?? 0.0;
    final receiving = double.tryParse(json['Receiving_Amount']?.toString() ?? '0') ?? 0.0;
    final totalAmount = fare * bookedAreaValue;

    final statusString = (json['Booking_Status'] as String?)?.toLowerCase();
    BookingStatus bookingStatus;
    switch (statusString) {
      case 'pending': bookingStatus = BookingStatus.pending; break;
      case 'booked':  bookingStatus = BookingStatus.booked;  break;
      case 'sellout': bookingStatus = BookingStatus.sellout; break;
      default:        bookingStatus = BookingStatus.available;
    }

    return PlotInfo(
      id: json['Plot_Number']?.toString() ?? '',
      area: area,
      areaUnit: areaUnit,
      fare: fare,
      receivingAmount: receiving,
      totalAmount: totalAmount,
      pendingAmount: totalAmount - receiving,
      clientName: json['Customer_Name']?.toString() ?? '',
      photoPath: json['Screenshot']?.toString(),
      bookedArea: areaUnit == AreaUnit.sqFt ? bookedAreaValue * 9 : bookedAreaValue,
      projectName: json['Project_Name']?.toString() ?? 'Unknown',
      purchasePrice: fare,
      paidThrough: json['Paid_Through']?.toString() ?? 'Online Transfer',
      bookingDate: DateTime.tryParse(json['Bookingdate']?.toString() ?? '') ?? DateTime.now(),
      bookedByDealer: json['Booked_ByDealer']?.toString() ?? '',
      customerPhone: json['Customer_Phn_Number']?.toString() ?? '',
      dealerPhone: json['Dealer_Phn_Number']?.toString() ?? '',
      status: json['Status'] is bool ? json['Status'] as bool : true,
      bookingStatus: bookingStatus,
      plotType: json['Plot_Type']?.toString() ?? 'Unknown',
    );
  }
}
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}





class PlotScreen extends StatefulWidget {
  const PlotScreen({Key? key}) : super(key: key);
  @override
  State<PlotScreen> createState() => _PlotScreenState();
}

class _PlotScreenState extends State<PlotScreen> {
  final TransformationController _transformationController = TransformationController();
  late Map<String, PlotInfo> plots;
  bool _isLoading = false;
  String? _errorMessage;
  final String projectName = 'Green Residency Phase 2';
  late final VoidCallback _plotRefreshListener;

  @override
  void initState() {
    super.initState();
    _initializePlots();
    _fetchPlotData();
    _plotRefreshListener = () {
      if (mounted) _fetchPlotData();
    };
    PlotRefreshNotifier.instance.addListener(_plotRefreshListener);
  }

  void _initializePlots() {
    plots = {};
    void addPlots(List<String> ids, String area) {
      for (var id in ids) {
        plots[id] = PlotInfo(id: id, area: '$area Sq.Yds', fare: 0, projectName: projectName, plotType: projectName);
      }
    }

    // Plots 1–15 remain unchanged
    addPlots(['1', '2'], '173');
    addPlots(['3', '4', '5', '6', '7', '8', '9'], '100');
    plots['10'] = PlotInfo(id: '10', area: '177 Sq.Yds', fare: 0, projectName: projectName, plotType: projectName);
    addPlots(['11', '12', '13', '14', '15'], '90');

    // New numbering starting from 16
    addPlots(['16', '17', '18', '19', '20', '21'], '90'); // Old 21–26
    addPlots(['22', '23', '24'], '100'); // Old 27–29
    plots['25'] = PlotInfo(id: '25', area: '177 Sq.Yds', fare: 0, projectName: projectName, plotType: projectName); // Old 30
    addPlots(['26', '27', '28', '29', '30', '31'], '90'); // Old 31–36
    addPlots(['32', '33', '34'], '100'); // Old 37–39
    plots['35'] = PlotInfo(id: '35', area: '177 Sq.Yds', fare: 0, projectName: projectName, plotType: projectName); // Old 40
    addPlots(['36', '37'], '173'); // Old 41–42
    addPlots(['38', '39', '40', '41', '42', '43', '44'], '100'); // Old 43–49
    plots['45'] = PlotInfo(id: '45', area: '177 Sq.Yds', fare: 0, projectName: projectName, plotType: projectName); // Old 50
    addPlots(['46', '47'], '173'); // Old 51–52
    addPlots(['48', '49', '50', '51', '52', '53', '54'], '100'); // Old 53–59
    plots['55'] = PlotInfo(id: '55', area: '177 Sq.Yds', fare: 0, projectName: projectName, plotType: projectName); // Old 60
    addPlots(['56', '57'], '173'); // Old 61–62
    addPlots(['58', '59', '60', '61', '62', '63', '64'], '100'); // Old 63–69
    plots['65'] = PlotInfo(id: '65', area: '177 Sq.Yds', fare: 0, projectName: projectName, plotType: projectName); // Old 70
    addPlots(['66', '67'], '173'); // Old 71–72
    addPlots(['68', '69', '70', '71', '72', '73', '74'], '100'); // Old 73–79
    plots['75'] = PlotInfo(id: '75', area: '177 Sq.Yds', fare: 0, projectName: projectName, plotType: projectName); // Old 80
    addPlots(['76', '79', '82', '85', '88', '91'], '363'); // Old 81, 84, 87, 90, 93, 96
    addPlots(['77', '78', '80', '81', '83', '84', '86', '87', '89', '90', '92', '93'], '100'); // Old 82, 83, 85, 86, 88, 89, 91, 92, 94, 95, 97, 98

    print('Initialized ${plots.length} plots'); // Should print 93 plots
  }

  Future<void> _fetchPlotData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _fetchPending(),
        _fetchBooked(),
        _fetchSellout(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch plot data: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPending() async {
    try {
      final response = await http.get(Uri.parse('https://realapp.cheenu.in/Api/PendingBooking?Project_Name=$projectName'));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> data = jsonData['data1'] ?? [];
        for (var item in data) {
          final plot = PlotInfo.fromJson(item);
          if (plots.containsKey(plot.id) && item['Project_Name'] == projectName) {
            final currentStatus = plots[plot.id]!.bookingStatus;
            if (currentStatus == BookingStatus.available) {
              plots[plot.id] = plot;
            }
          }
        }
      } else {
        throw Exception('PendingBooking API returned status ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching pending bookings: $e');
      throw e;
    }
  }

  Future<void> _fetchBooked() async {
    try {
      final response = await http.get(Uri.parse('https://realapp.cheenu.in/Api/BookedPlot?Project_Name=$projectName'));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> data = jsonData['data1'] ?? [];
        for (var item in data) {
          final plot = PlotInfo.fromJson(item);
          if (plots.containsKey(plot.id) && item['Project_Name'] == projectName) {
            final currentStatus = plots[plot.id]!.bookingStatus;
            if (currentStatus == BookingStatus.available || currentStatus == BookingStatus.pending) {
              plots[plot.id] = plot;
            }
          }
        }
      } else {
        throw Exception('BookedPlot API returned status ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching booked plots: $e');
      throw e;
    }
  }

  Future<void> _fetchSellout() async {
    try {
      final response = await http.get(Uri.parse('https://realapp.cheenu.in/Api/SelloutPlot?Project_Name=$projectName'));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> data = jsonData['data1'] ?? [];
        for (var item in data) {
          final plot = PlotInfo.fromJson(item);
          if (plots.containsKey(plot.id) && item['Project_Name'] == projectName) {
            plots[plot.id] = plot;
          }
        }
      } else {
        throw Exception('SelloutPlot API returned status ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching sellout plots: $e');
      throw e;
    }
  }

  void _showBookingDialog(String plotId) {
    if (!plots.containsKey(plotId)) {
      print('Plot ID $plotId not found');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plot not found!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final plot = plots[plotId]!;

    // Don't open dialog if plot is already booked or sold out
    if (plot.bookingStatus == BookingStatus.booked || plot.bookingStatus == BookingStatus.sellout) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plot $plotId is already ${plot.statusText.toLowerCase()}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => BookingDialog(
        plot: PlotInfo.clone(plots[plotId]!),
        onSave: (updatedPlot) {
          setState(() {
            plots[plotId] = updatedPlot;
            print('Updated plot $plotId: ${updatedPlot.toJson()}');
          });
        },
      ),
    );
  }

  // MEASUREMENTS FOR LARGE PLOTS
  final Map<String, Map<String, String>> _measurements = {
    '76': {'left': "60'-0\"", 'top': "60'-0\""},
    '79': {'left': "60'-0\"", 'top': "60'-0\""},
    '82': {'left': "60'-0\"", 'top': "60'-0\""},
    '85': {'left': "60'-0\"", 'top': "60'-0\""},
    '88': {'left': "60'-0\"", 'top': "60'-0\""},
    '91': {'left': "60'-0\"", 'top': "60'-0\""},
  };

  Widget _buildPlot(String plotId, {double width = 55, double height = 45}) {
    if (!plots.containsKey(plotId)) {
      print('Plot $plotId not found, returning empty container');
      return Container(width: width, height: height, color: Colors.grey);
    }
    final plot = plots[plotId]!;
    final isLarge = ['76', '79', '82', '85', '88', '91'].contains(plotId);
    final meas = _measurements[plotId];
    final isBookedOrSoldOut = plot.bookingStatus == BookingStatus.booked ||
        plot.bookingStatus == BookingStatus.sellout;
    return GestureDetector(
      onTap: isBookedOrSoldOut ? null : () => _showBookingDialog(plotId),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: isLarge ? Colors.blue.shade700 : Colors.black87,
            width: isLarge ? 2.5 : 1.5,
          ),
        ),
        child: Stack(
          children: [
            // PARTIAL BOOKING STRIPE
            if (plot.bookedArea > 0 && plot.bookedArea < plot.totalAreaValue)
              Row(
                children: [
                  Container(
                    width: width * plot.bookedPercentage,
                    height: height,
                    color: plot.bookingStatus == BookingStatus.booked
                        ? Colors.blue.shade400
                        : Colors.orange.shade400,
                  ),
                  Container(
                    width: width * (1 - plot.bookedPercentage),
                    height: height,
                    color: plot.color,
                  ),
                ],
              )
            else
              Container(color: plot.color),
            // TEXT
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      plotId,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isLarge ? Colors.blue.shade900 : Colors.black,
                      ),
                    ),
                    Text(
                      plot.area,
                      style: const TextStyle(fontSize: 7, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      plot.statusText,
                      style: const TextStyle(fontSize: 7, color: Colors.black, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // MEASUREMENTS
            if (meas != null) ...[
              if (meas['left'] != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(meas['left']!, style: const TextStyle(fontSize: 6)),
                  ),
                ),
              if (meas['top'] != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(meas['top']!, style: const TextStyle(fontSize: 6)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoad(String label, {bool isVertical = false}) {
    return Container(
      width: isVertical ? 60 : null,
      height: isVertical ? null : 30,
      color: Colors.grey.shade600,
      padding: const EdgeInsets.all(4),
      child: RotatedBox(
        quarterTurns: isVertical ? 3 : 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              height: 1,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpressway() {
    return Container(
      height: 70,
      color: Colors.grey.shade700,
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  12,
                      (index) => Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.yellow, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'YAMUNA EXPRESSWAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 1),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  height: 1,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  12,
                      (index) => Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.yellow, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final plotWidth = screenWidth * 0.1;
    final plotHeight = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('Green Residency Phase 2'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              final matrix = _transformationController.value.clone();
              matrix.scale(1.2);
              _transformationController.value = matrix;
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              final matrix = _transformationController.value.clone();
              matrix.scale(0.8);
              _transformationController.value = matrix;
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPlotData,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchPlotData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(100),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRoad("100 FT WIDE ROAD", isVertical: true),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            _buildExpressway(),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        ...List.generate(
                                          2,
                                              (i) => _buildPlot('${2 - i}', width: plotWidth, height: plotHeight),
                                        ),
                                        ...List.generate(
                                          7,
                                              (i) => _buildPlot('${9 - i}', width: plotWidth, height: plotHeight),
                                        ),
                                        _buildPlot('10', width: plotWidth * 1.5, height: plotHeight),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    _buildRoad("22' WIDE ROAD"),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        ...List.generate(
                                          6,
                                              (i) => _buildPlot('${16 + i}', width: plotWidth, height: plotHeight),
                                        ),
                                        ...List.generate(
                                          3,
                                              (i) => _buildPlot('${24 - i}', width: plotWidth, height: plotHeight),
                                        ),
                                        _buildPlot('25', width: plotWidth * 1.5, height: plotHeight),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        ...List.generate(
                                          6,
                                              (i) => _buildPlot('${26 + i}', width: plotWidth, height: plotHeight),
                                        ),
                                        ...List.generate(
                                          3,
                                              (i) => _buildPlot('${34 - i}', width: plotWidth, height: plotHeight),
                                        ),
                                        _buildPlot('35', width: plotWidth * 1.5, height: plotHeight),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    _buildRoad("22' WIDE ROAD"),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        ...List.generate(
                                          2,
                                              (i) => _buildPlot('${37 - i}', width: plotWidth, height: plotHeight),
                                        ),
                                        ...List.generate(
                                          7,
                                              (i) => _buildPlot('${44 - i}', width: plotWidth, height: plotHeight),
                                        ),
                                        _buildPlot('45', width: plotWidth * 1.5, height: plotHeight),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        ...List.generate(
                                          2,
                                              (i) => _buildPlot('${47 - i}', width: plotWidth, height: plotHeight),
                                        ),
                                        ...List.generate(
                                          7,
                                              (i) => _buildPlot('${54 - i}', width: plotWidth, height: plotHeight),
                                        ),
                                        _buildPlot('55', width: plotWidth * 1.5, height: plotHeight),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    _buildRoad("22' WIDE ROAD"),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        ...List.generate(
                                          2,
                                              (i) => _buildPlot('${57 - i}', width: plotWidth, height: plotHeight),
                                        ),
                                        ...List.generate(
                                          7,
                                              (i) => _buildPlot('${64 - i}', width: plotWidth, height: plotHeight),
                                        ),
                                        _buildPlot('65', width: plotWidth * 1.5, height: plotHeight),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        ...List.generate(
                                          2,
                                              (i) => _buildPlot('${67 - i}', width: plotWidth, height: plotHeight),
                                        ),
                                        ...List.generate(
                                          7,
                                              (i) => _buildPlot('${74 - i}', width: plotWidth, height: plotHeight),
                                        ),
                                        _buildPlot('75', width: plotWidth * 1.5, height: plotHeight),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    _buildRoad("22' WIDE ROAD"),
                                    const SizedBox(height: 2),
                                    // NEW ROW ADDED: Duplicate of 67–75
                                    Row(
                                      children: [
                                        ...List.generate(
                                          2,
                                              (i) => _buildPlot('${67 - i}', width: plotWidth, height: plotHeight),
                                        ),
                                        ...List.generate(
                                          7,
                                              (i) => _buildPlot('${74 - i}', width: plotWidth, height: plotHeight),
                                        ),
                                        _buildPlot('75', width: plotWidth * 1.5, height: plotHeight),
                                      ],
                                    ),

                                    const SizedBox(height: 10),
                                    Container(
                                      width: 600,
                                      height: 80,
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                        child: Text(
                                          'SOLD OUT',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 40),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        _buildPlot('76', width: plotWidth, height: plotHeight),
                                        const SizedBox(width: 2),
                                        _buildPlot('77', width: plotWidth, height: plotHeight),
                                        const SizedBox(width: 2),
                                        _buildPlot('78', width: plotWidth, height: plotHeight),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    _buildRoad("22' WIDE ROAD"),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        _buildPlot('79', width: plotWidth, height: plotHeight),
                                        const SizedBox(width: 2),
                                        _buildPlot('80', width: plotWidth, height: plotHeight),
                                        const SizedBox(width: 2),
                                        _buildPlot('81', width: plotWidth, height: plotHeight),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        _buildPlot('82', width: plotWidth, height: plotHeight),
                                        const SizedBox(width: 2),
                                        _buildPlot('83', width: plotWidth, height: plotHeight),
                                        const SizedBox(width: 2),
                                        _buildPlot('84', width: plotWidth, height: plotHeight),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    _buildRoad("22' WIDE ROAD"),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        _buildPlot('85', width: plotWidth, height: plotHeight),
                                        const SizedBox(width: 2),
                                        _buildPlot('86', width: plotWidth, height: plotHeight),
                                        const SizedBox(width: 2),
                                        _buildPlot('87', width: plotWidth, height: plotHeight),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        _buildPlot('88', width: plotWidth, height: plotHeight),
                                        const SizedBox(width: 2),
                                        _buildPlot('89', width: plotWidth, height: plotHeight),
                                        const SizedBox(width: 2),
                                        _buildPlot('90', width: plotWidth, height: plotHeight),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    _buildRoad("22' WIDE ROAD"),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        _buildPlot('91', width: plotWidth, height: plotHeight),
                                        const SizedBox(width: 2),
                                        _buildPlot('92', width: plotWidth, height: plotHeight),
                                        const SizedBox(width: 2),
                                        _buildPlot('93', width: plotWidth, height: plotHeight),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: 800,
                              padding: const EdgeInsets.all(8),
                              color: Colors.grey.shade700,
                              child: const Center(
                                child: Text(
                                  '100 FT WIDE ROAD',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildExpressway(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STATUS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusItem(Colors.green.shade200, 'Available'),
                  _buildStatusItem(Colors.red.shade300, 'Pending (<50%)'),
                  _buildStatusItem(Colors.yellow.shade300, 'Pending (≥50%)'),
                  _buildStatusItem(Colors.orange.shade300, 'Partially Booked'),
                  _buildStatusItem(Colors.blue.shade300, 'Booked'),
                  _buildStatusItem(Colors.grey.shade300, 'Sold Out'),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _transformationController.value = Matrix4.identity();
        },
        child: const Icon(Icons.fit_screen),
      ),
    );
  }
  Widget _buildStatusItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    PlotRefreshNotifier.instance.removeListener(_plotRefreshListener);
    _transformationController.dispose();
    super.dispose();
  }
}

class BookingDialog extends StatefulWidget {
  final PlotInfo plot;
  final Function(PlotInfo) onSave;

  const BookingDialog({Key? key, required this.plot, required this.onSave}) : super(key: key);

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  late TextEditingController _clientController;
  late TextEditingController _areaController;
  late TextEditingController _bookedAreaController;
  late TextEditingController _remainingAreaController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _receivingController;
  late TextEditingController _projectController;
  late TextEditingController _pendingController;
  late TextEditingController _paidThroughController;
  late TextEditingController _bookedByController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _dealerPhoneController;
  late TextEditingController _bookingDateController;
  late TextEditingController _plotTypeController;
  late TextEditingController _commissionController;

  bool _status = true;
  File? _uploadedPhoto;
  AreaUnit _areaUnit = AreaUnit.sqYds;
  bool _isLoading = false;
  bool _isSubmitEnabled = true;
  String? _lastErrorMessage;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  double _totalAmount = 0;

  final List<String> _paidThroughOptions = ['Cash', 'Online Transfer', 'Cheque','RTGS','NEFT'];
  String _selectedPaidThrough = 'Online Transfer';
  final AssociateService _associateService = AssociateService();
  List<Associate> _associates = [];
  bool _isLoadingAssociates = false;
  Associate? _selectedAssociate;
  double _selectedCommissionRate = 0;
  double _calculatedCommissionAmount = 0;

  @override
  void initState() {
    super.initState();
    _commissionController = TextEditingController(text: '0');
    _initializeControllers();
    _loadUserData();
    _fetchAssociates();
  }

  void _initializeControllers() {
    final totalArea = widget.plot.totalAreaValue;

    _clientController = TextEditingController(text: widget.plot.clientName);
    _areaController = TextEditingController(text: totalArea.toStringAsFixed(0));
    _bookedAreaController = TextEditingController(text: widget.plot.bookedArea.toStringAsFixed(0));
    _remainingAreaController = TextEditingController(
      text: (totalArea - widget.plot.bookedArea).toStringAsFixed(0),
    );
    _purchasePriceController = TextEditingController(text: widget.plot.fare.toStringAsFixed(0));
    _receivingController = TextEditingController(text: widget.plot.paidAmount.toStringAsFixed(0));
    _projectController = TextEditingController(text: widget.plot.projectName);
    _pendingController = TextEditingController(text: widget.plot.pendingAmount.toStringAsFixed(0));
    _paidThroughController = TextEditingController(text: widget.plot.paidThrough);
    _bookedByController = TextEditingController(text: widget.plot.bookedByDealer);
    _customerPhoneController = TextEditingController(text: widget.plot.customerPhone);
    _dealerPhoneController = TextEditingController(text: widget.plot.dealerPhone);
    _bookingDateController = TextEditingController(
      text: widget.plot.bookingDate.toIso8601String().split('T')[0],
    );
    _plotTypeController = TextEditingController(text: widget.plot.plotType);
    _status = widget.plot.status;
    _areaUnit = widget.plot.areaUnit;
    _selectedPaidThrough = widget.plot.paidThrough.isNotEmpty ? widget.plot.paidThrough : 'Online Transfer';

    _updateTotalAmount();
  }

  Future<void> _loadUserData() async {
    try {
      final session = await AuthManager.getCurrentSession();
      if (session != null) {
        // Auto-populate dealer name and phone with current user's data
        // Always populate with current user's info (user can still edit if needed)
        if (session.userName != null && session.userName!.isNotEmpty) {
          _bookedByController.text = session.userName!;
        }
        if (session.userMobile != null && session.userMobile!.isNotEmpty) {
          _dealerPhoneController.text = session.userMobile!;
        }
        // Update UI if widget is still mounted
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _fetchAssociates() async {
    if (_isLoadingAssociates) return;
    setState(() => _isLoadingAssociates = true);

    try {
      final associates = await _associateService.fetchAssociates();
      setState(() {
        _associates = associates;
      });
    } catch (e) {
      print('Error fetching associates: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingAssociates = false);
      }
    }
  }

  // FIXED: Sync area string when unit changes
  void _updateRemainingArea() {
    final total = double.tryParse(_areaController.text) ?? 0;
    final booked = double.tryParse(_bookedAreaController.text) ?? 0;
    final unitFactor = _areaUnit == AreaUnit.sqFt ? 1 / 9.0 : 1.0;
    final totalInYds = total * unitFactor;
    final remaining = totalInYds - booked;

    setState(() {
      _remainingAreaController.text = remaining.toStringAsFixed(0);
      // CRITICAL FIX: Keep area string in sync with current unit
      _areaController.text = total.toStringAsFixed(0);
    });
  }

  void _updateTotalAmount({bool updateCommission = true}) {
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final bookedArea = double.tryParse(_bookedAreaController.text) ?? 0;
    final unitFactor = _areaUnit == AreaUnit.sqFt ? 1 / 9.0 : 1.0;
    final bookedInYds = bookedArea * unitFactor;

    final total = purchasePrice * bookedInYds;
    final receiving = double.tryParse(_receivingController.text) ?? 0;
    final pendingText = (total - receiving).toStringAsFixed(0);

    double commissionAmount = _calculatedCommissionAmount;
    if (updateCommission) {
      final netRate = purchasePrice - _selectedCommissionRate;
      commissionAmount = netRate * bookedArea;
      if (commissionAmount < 0) commissionAmount = 0;
    }

    setState(() {
      _totalAmount = total;
      _pendingController.text = pendingText;
      if (updateCommission) {
        _calculatedCommissionAmount = commissionAmount;
        _commissionController.text = _selectedCommissionRate.toStringAsFixed(0);
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;
      final fileSize = await File(image.path).length();
      if (fileSize > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image size exceeds 5MB'), backgroundColor: Colors.red),
        );
        return;
      }
      setState(() => _uploadedPhoto = File(image.path));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _bookingDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<http.Response> _submitBookingAPI(PlotInfo plot) async {
    print('=== DEBUG: Starting API Submit ===');

    if (!mounted) return Future.error('Widget disposed before API started');

    setState(() {
      _isLoading = true;
      _isSubmitEnabled = false;
      _lastErrorMessage = null;
    });

    final url = Uri.parse('https://realapp.cheenu.in/api/booking/add');
    final body = plot.toJson();
    print('DEBUG: URL = $url');
    print('DEBUG: Payload = ${jsonEncode(body)}');

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No internet connection');
      }
    } catch (e) {
      print('DEBUG: Connectivity Error: $e');
      if (!mounted) return Future.error(e);
      setState(() {
        _lastErrorMessage = e.toString();
        _isLoading = false;
        _isSubmitEnabled = true;
      });
      rethrow;
    }

    final jsonBody = jsonEncode(body);

    for (int i = 1; i <= 3; i++) {
      try {
        final response = await http
            .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonBody,
        )
            .timeout(const Duration(seconds: 30));

        print('DEBUG: Response code: ${response.statusCode}');
        print('DEBUG: Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final respJson = response.body.isNotEmpty
              ? jsonDecode(response.body)
              : <String, dynamic>{};

          // Backend currently returns: {"message":"Booking added successfully"}
          // without a "status" field. Treat any 200/201 as success and just
          // show whatever message is present.
          final successMessage = (respJson['message'] ??
                  respJson['Message'] ??
                  'Booking saved!')
              .toString();
          final remainingArea =
              respJson['remaining_area'] != null ? respJson['remaining_area'] : null;

          if (!mounted) return response;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                remainingArea != null
                    ? '$successMessage (Remaining: $remainingArea)'
                    : successMessage,
              ),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isLoading = false;
            _isSubmitEnabled = true;
          });
          Navigator.of(context).pop();
          return response;
        } else {
          final respJson = response.body.isNotEmpty
              ? jsonDecode(response.body)
              : <String, dynamic>{};
          // Some APIs return {"Message": "..."} with capital M
          final error = (respJson['message'] ??
                  respJson['Message'] ??
                  'Server error: ${response.statusCode}')
              .toString();
          if (!mounted) return Future.error(error);
          setState(() => _lastErrorMessage = error);
          print('DEBUG: Server returned error: $error');

          if (i == 3) {
            setState(() {
              _isLoading = false;
              _isSubmitEnabled = true;
            });
            return response;
          }

          await Future.delayed(Duration(seconds: i * 2));
        }
      } catch (e) {
        print('DEBUG: Exception in attempt $i -> $e');
        if (i == 3) {
          if (!mounted) return Future.error(e);
          setState(() {
            _isLoading = false;
            _isSubmitEnabled = true;
          });
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
          rethrow;
        }
        await Future.delayed(Duration(seconds: i * 2));
      }
    }

    if (!mounted) return Future.error('Failed after 3 attempts');
    setState(() {
      _isLoading = false;
      _isSubmitEnabled = true;
    });
    throw Exception('Failed after 3 attempts');
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    String? hintText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: icon != null ? Icon(icon) : null,
          hintText: hintText,
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAssociateDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<Associate>(
        value: _selectedAssociate,
        decoration: const InputDecoration(
          labelText: 'Select Associate',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person_search),
        ),
        items: _associates
            .map((associate) => DropdownMenuItem(
          value: associate,
          child: Text(associate.fullName),
        ))
            .toList(),
        onChanged: _isLoadingAssociates ? null : _selectAssociate,
        hint: Text(_isLoadingAssociates ? 'Loading associates...' : 'Select Associate'),
      ),
    );
  }

  void _selectAssociate(Associate? associate) {
    setState(() {
      _selectedAssociate = associate;
      if (associate != null) {
        _bookedByController.text = associate.fullName;
        _dealerPhoneController.text = associate.phone;
        _selectedCommissionRate = _determineCommissionRate(associate, _projectController.text);
      } else {
        _selectedCommissionRate = 0;
      }
    });
    _updateTotalAmount();
  }

  void _refreshCommissionFromProject() {
    if (_selectedAssociate == null) return;
    final rate = _determineCommissionRate(_selectedAssociate!, _projectController.text);
    if (rate != _selectedCommissionRate) {
      setState(() => _selectedCommissionRate = rate);
      _updateTotalAmount();
    }
  }

  double _determineCommissionRate(Associate associate, String projectName) {
    final normalizedProject = projectName.trim().toLowerCase();
    final project1 = associate.projectName1?.trim().toLowerCase() ?? '';
    final project2 = associate.projectName2?.trim().toLowerCase() ?? '';

    if (project1.isNotEmpty && normalizedProject.contains(project1)) {
      return (associate.commissionProject1 ?? 0).toDouble();
    }
    if (project2.isNotEmpty && normalizedProject.contains(project2)) {
      return (associate.commissionProject2 ?? 0).toDouble();
    }

    if ((associate.commissionProject1 ?? 0) > 0) return (associate.commissionProject1 ?? 0).toDouble();
    if ((associate.commissionProject2 ?? 0) > 0) return (associate.commissionProject2 ?? 0).toDouble();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.9;
    final dialogMaxHeight = screenSize.height * 0.85;

    return Dialog(
      child: SizedBox(
        width: dialogWidth,
        height: dialogMaxHeight,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Plot ${widget.plot.id} - Booking',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      if (_lastErrorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Last Error: $_lastErrorMessage',
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ],
                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _projectController,
                        label: 'Project Name',
                        icon: Icons.apartment,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                        onChanged: (_) => _refreshCommissionFromProject(),
                      ),
                      _buildTextField(
                        controller: _plotTypeController,
                        label: 'Plot Type',
                        icon: Icons.category,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      _buildTextField(
                        controller: _clientController,
                        label: 'Client Name',
                        icon: Icons.person,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      _buildTextField(
                        controller: _customerPhoneController,
                        label: 'Customer Phone',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.length != 10 ? '10 digits required' : null,
                      ),
                      _buildAssociateDropdown(),
                      _buildTextField(
                        controller: _bookedByController,
                        label: 'Associate Name',
                        icon: Icons.person_pin,
                      ),
                      _buildTextField(
                        controller: _dealerPhoneController,
                        label: 'Associate Phone',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty || v.length != 10 ? '10 digits required' : null,
                      ),
                      _buildTextField(
                        controller: _commissionController,
                        label: 'Associate Commission Rate (₹)',
                        icon: Icons.attach_money,
                        readOnly: true,
                      ),

                      // Plot Area (Fixed – not editable)
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _areaController,
                              label: 'Plot Area',
                              icon: Icons.square_foot,
                              readOnly: true,
                              validator: (v) => (double.tryParse(v!) ?? 0) <= 0 ? 'Invalid' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<AreaUnit>(
                            value: _areaUnit,
                            items: AreaUnit.values
                                .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u == AreaUnit.sqYds ? 'Sq.Yds' : 'sq ft'),
                            ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _areaUnit = v;
                                  _updateRemainingArea(); // Now syncs area string
                                  _updateTotalAmount();
                                });
                              }
                            },
                          ),
                        ],
                      ),

                      // Booked Area
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _bookedAreaController,
                              label: 'Booked Area',
                              icon: Icons.crop_square,
                              keyboardType: TextInputType.number,
                              onChanged: (_) {
                                _updateRemainingArea();
                                _updateTotalAmount();
                              },
                              validator: (v) {
                                final booked = double.tryParse(v!) ?? 0;
                                final total = double.tryParse(_areaController.text) ?? 0;
                                final factor = _areaUnit == AreaUnit.sqFt ? 1 / 9.0 : 1.0;
                                if (booked > total * factor) return 'Exceeds total';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_areaUnit == AreaUnit.sqYds ? 'Sq.Yds' : 'sq ft'),
                        ],
                      ),

                      // Remaining Area (Auto)
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _remainingAreaController,
                              label: 'Remaining Area',
                              icon: Icons.space_bar,
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_areaUnit == AreaUnit.sqYds ? 'Sq.Yds' : 'sq ft'),
                        ],
                      ),

                      // Purchase Price
                      _buildTextField(
                        controller: _purchasePriceController,
                        label: 'Purchase Price ',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _updateTotalAmount(),
                        validator: (v) => (double.tryParse(v!) ?? 0) <= 0 ? 'Required' : null,
                      ),

                      // Total Amount (Auto)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Total Amount: ₹${_totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Associate Commission Amount: ₹${_calculatedCommissionAmount.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                      ),

                      // Receiving Amount
                      _buildTextField(
                        controller: _receivingController,
                        label: 'Receiving Amount (₹)',
                        icon: Icons.payment,
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final rec = double.tryParse(v) ?? 0;
                          setState(() {
                            _pendingController.text = (_totalAmount - rec).toStringAsFixed(0);
                          });
                        },
                        validator: (v) {
                          final rec = double.tryParse(v ?? '') ?? 0;
                          if (rec > _totalAmount) return 'Cannot exceed total';
                          return null;
                        },
                      ),

                      // Pending Amount (Auto)
                      _buildTextField(
                        controller: _pendingController,
                        label: 'Pending Amount (₹)',
                        icon: Icons.money_off,
                        readOnly: true,
                      ),

                      // Paid Through Dropdown
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          value: _selectedPaidThrough,
                          decoration: const InputDecoration(
                            labelText: 'Paid Through',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.payment),
                          ),
                          items: _paidThroughOptions
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedPaidThrough = v!),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),

                      // Booking Date + Calendar
                      // 📅 Booking Date (TextField + Pick Button in same row)
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _bookingDateController,
                              label: 'Booking Date',
                              icon: Icons.calendar_today,
                              readOnly: true,
                              validator: (v) => DateTime.tryParse(v ?? '') == null ? 'Invalid date' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _selectDate,
                            icon: const Icon(Icons.date_range),
                            label: const Text('Pick'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                          ),
                        ],
                      ),

                      // Status
                      Row(
                        children: [
                          const Text('Status:'),
                          Checkbox(
                            value: _status,
                            onChanged: (v) => setState(() => _status = v ?? false),
                          ),
                          const Text('Active'),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Text('Upload Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                            ),
                          ),
                        ],
                      ),
                      if (_uploadedPhoto != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_uploadedPhoto!, height: 150, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            if (_formKey.currentState!.validate()) {
                              final localPlot = PlotInfo.clone(widget.plot);

                              final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
                              final bookedArea = double.tryParse(_bookedAreaController.text) ?? 0;
                              final totalAmountValue = purchasePrice * (bookedArea / (_areaUnit == AreaUnit.sqFt ? 9.0 : 1.0));

                              localPlot.clientName = _clientController.text;
                              localPlot.fare = purchasePrice;
                              localPlot.totalAmount = totalAmountValue;
                              localPlot.receivingAmount = double.tryParse(_receivingController.text) ?? 0;
                              localPlot.bookedArea = bookedArea;
                              localPlot.area = '${_areaController.text} ${_areaUnit == AreaUnit.sqYds ? 'Sq.Yds' : 'sq ft'}';
                              localPlot.areaUnit = _areaUnit;
                              localPlot.photoPath = _uploadedPhoto?.path;
                              localPlot.projectName = _projectController.text;
                              localPlot.pendingAmount = totalAmountValue - localPlot.receivingAmount;
                              localPlot.paidThrough = _selectedPaidThrough;
                              localPlot.bookedByDealer = _bookedByController.text;
                              localPlot.customerPhone = _customerPhoneController.text;
                              localPlot.dealerPhone = _dealerPhoneController.text;
                              localPlot.bookingDate = DateTime.parse(_bookingDateController.text);
                              localPlot.plotType = _plotTypeController.text;
                              localPlot.status = _status;
                              localPlot.bookingStatus = BookingStatus.pending;

                              localPlot.updateCalculations(
                                newFare: purchasePrice,
                                newBookedArea: bookedArea,
                                newUnit: _areaUnit,
                              );

                              try {
                                await _submitBookingAPI(localPlot);
                                widget.onSave(localPlot);
                              } catch (e) {
                                // Error already shown
                              }
                            }
                          },
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Submit Booking', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
