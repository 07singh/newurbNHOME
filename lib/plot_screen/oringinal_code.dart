import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

enum AreaUnit { sqYds, sqFt }
enum BookingStatus { available, pending, booked, sellout }

class PlotInfo {
  final String id;
  String area;
  AreaUnit areaUnit;
  double fare;
  double paidAmount;
  double totalAmount;
  String clientName;
  String? photoPath;
  double bookedArea;
  String projectName;
  double purchasePrice;
  double receivingAmount;
  double pendingAmount;
  String paidThrough;
  DateTime bookingDate;
  String bookedByDealer;
  String customerPhone;
  String dealerPhone;
  bool status;
  BookingStatus bookingStatus;
  String plotType;

  PlotInfo({
    required this.id,
    required this.area,
    this.areaUnit = AreaUnit.sqYds,
    required this.fare,
    this.paidAmount = 0,
    this.totalAmount = 0,
    this.clientName = '',
    this.photoPath,
    this.bookedArea = 0,
    required this.projectName,
    this.purchasePrice = 0,
    this.receivingAmount = 0,
    this.pendingAmount = 0,
    this.paidThrough = 'Online Transfer',
    DateTime? bookingDate,
    this.bookedByDealer = '',
    this.customerPhone = '',
    this.dealerPhone = '',
    this.status = true,
    this.bookingStatus = BookingStatus.available,
    required this.plotType,
  }) : bookingDate = bookingDate ?? DateTime.now() {
    totalAmount = fare * 100; // Fixed multiplier of 100
  }

  double _parseArea(String area, AreaUnit unit) {
    final value = double.tryParse(area.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    return unit == AreaUnit.sqFt ? value / 9 : value;
  }

  Color get color {
    switch (bookingStatus) {
      case BookingStatus.available:
        return Colors.green.shade200;
      case BookingStatus.pending:
        return paidPercentage < 50 ? Colors.red.shade300 : Colors.yellow.shade300;
      case BookingStatus.booked:
        return Colors.blue.shade300;
      case BookingStatus.sellout:
        return Colors.grey.shade300;
    }
  }

  String get statusText {
    switch (bookingStatus) {
      case BookingStatus.available:
        return "Available";
      case BookingStatus.pending:
        return paidPercentage < 50 ? "Pending (<50%)" : "Pending (≥50%)";
      case BookingStatus.booked:
        return "Booked";
      case BookingStatus.sellout:
        return "Sold Out";
    }
  }

  double get remainingAmount => totalAmount - paidAmount;

  double get paidPercentage => totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;

  double get bookedPercentage {
    final totalArea = _parseArea(area, areaUnit);
    return bookedArea > 0 && totalArea > 0 ? bookedArea / totalArea : 0;
  }

  Map<String, dynamic> toJson() {
    final cleanedArea = area.replaceAll(RegExp(r'\s*Sq\.Yds\s*Sq\.Yds$|\s*sq ft\s*sq ft$'), '');
    final totalArea = double.tryParse(cleanedArea.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final remaining = totalArea - bookedArea;

    return {
      'Project_Name': projectName,
      'Purchase_price': purchasePrice,
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
      'Total_Area': cleanedArea.isEmpty ? '$area ${areaUnit == AreaUnit.sqYds ? 'Sq.Yds' : 'sq ft'}' : cleanedArea,
      'Booking_Area': '$bookedArea ${areaUnit == AreaUnit.sqYds ? 'Sq.Yds' : 'sq ft'}',
      'Screenshot': photoPath,
      'Total_Amount': totalAmount.toStringAsFixed(2),
      'Booking_Status': bookingStatus.toString().split('.').last.capitalize(),
      'Plot_Type': plotType,
      'Remaining_Area': remaining.toStringAsFixed(0), // ADDED
    };
  }

  factory PlotInfo.fromJson(Map<String, dynamic> json) {
    final area = json['Total_Area'] as String? ?? '0 Sq.Yds';
    final areaUnit = area.contains('sq ft') ? AreaUnit.sqFt : AreaUnit.sqYds;
    final totalAmount = (json['Total_Amount'] is num
        ? (json['Total_Amount'] as num).toDouble()
        : double.tryParse(json['Total_Amount']?.toString() ?? '0') ?? 0.0);
    final fare = totalAmount / 100;

    final statusString = (json['Booking_Status'] as String?)?.toLowerCase();
    BookingStatus bookingStatus;
    switch (statusString) {
      case 'pending':
        bookingStatus = BookingStatus.pending;
        break;
      case 'booked':
        bookingStatus = BookingStatus.booked;
        break;
      case 'sellout':
        bookingStatus = BookingStatus.sellout;
        break;
      default:
        bookingStatus = BookingStatus.available;
    }

    return PlotInfo(
      id: json['Plot_Number']?.toString() ?? '',
      area: area,
      areaUnit: areaUnit,
      fare: fare,
      paidAmount: (json['Receiving_Amount'] is num
          ? (json['Receiving_Amount'] as num).toDouble()
          : double.tryParse(json['Receiving_Amount']?.toString() ?? '0') ?? 0.0),
      totalAmount: totalAmount,
      clientName: json['Customer_Name']?.toString() ?? '',
      photoPath: json['Screenshot']?.toString(),
      bookedArea: double.tryParse(
        (json['Booking_Area'] as String?)?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '0',
      ) ?? 0.0,
      projectName: json['Project_Name']?.toString() ?? 'Unknown',
      purchasePrice: (json['Purchase_price'] is num
          ? (json['Purchase_price'] as num).toDouble()
          : double.tryParse(json['Purchase_price']?.toString() ?? '0') ?? 0.0),
      receivingAmount: (json['Receiving_Amount'] is num
          ? (json['Receiving_Amount'] as num).toDouble()
          : double.tryParse(json['Receiving_Amount']?.toString() ?? '0') ?? 0.0),
      pendingAmount: (json['Pending_Amount'] is num
          ? (json['Pending_Amount'] as num).toDouble()
          : double.tryParse(json['Pending_Amount']?.toString() ?? '0') ?? 0.0),
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
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class BookingDialog extends StatefulWidget {
  final PlotInfo plot;
  final Function(PlotInfo) onSave;

  const BookingDialog({
    Key? key,
    required this.plot,
    required this.onSave,
  }) : super(key: key);

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  late TextEditingController _clientController;
  late TextEditingController _areaController;
  late TextEditingController _bookedAreaController;
  late TextEditingController _remainingAreaController; // <-- NEW
  late TextEditingController _fareController;
  late TextEditingController _paidController;
  late TextEditingController _projectController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _receivingController;
  late TextEditingController _pendingController;
  late TextEditingController _paidThroughController;
  late TextEditingController _bookedByController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _dealerPhoneController;
  late TextEditingController _bookingDateController;
  late TextEditingController _plotTypeController;
  late List<TextEditingController> _controllers;
  bool _status = true;
  File? _uploadedPhoto;
  AreaUnit _areaUnit = AreaUnit.sqYds;
  bool _isLoading = false;
  bool _isSubmitEnabled = true;
  String? _lastErrorMessage;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _clientController = TextEditingController(text: widget.plot.clientName);
    _areaController = TextEditingController(
      text: widget.plot.area.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    _bookedAreaController = TextEditingController(
      text: widget.plot.bookedArea.toStringAsFixed(0),
    );
    _remainingAreaController = TextEditingController(
      text: _calculateRemainingArea().toStringAsFixed(0),
    );
    _fareController = TextEditingController(text: widget.plot.fare.toStringAsFixed(0));
    _paidController = TextEditingController(text: widget.plot.paidAmount.toStringAsFixed(0));
    _projectController = TextEditingController(text: widget.plot.projectName);
    _purchasePriceController = TextEditingController(
      text: widget.plot.purchasePrice.toStringAsFixed(0),
    );
    _receivingController = TextEditingController(
      text: widget.plot.receivingAmount.toStringAsFixed(0),
    );
    _pendingController = TextEditingController(
      text: widget.plot.pendingAmount.toStringAsFixed(0),
    );
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
    _totalAmount = widget.plot.totalAmount;

    _controllers = [
      _clientController,
      _areaController,
      _bookedAreaController,
      _remainingAreaController,
      _fareController,
      _paidController,
      _projectController,
      _purchasePriceController,
      _receivingController,
      _pendingController,
      _paidThroughController,
      _bookedByController,
      _customerPhoneController,
      _dealerPhoneController,
      _bookingDateController,
      _plotTypeController,
    ];
  }

  double _calculateRemainingArea() {
    final total = double.tryParse(_areaController.text) ?? 0;
    final booked = double.tryParse(_bookedAreaController.text) ?? 0;
    return total - booked;
  }

  void _updateRemainingArea() {
    setState(() {
      _remainingAreaController.text = _calculateRemainingArea().toStringAsFixed(0);
    });
  }

  void _updateTotalAmount() {
    final fare = double.tryParse(_fareController.text) ?? 0;
    setState(() {
      _totalAmount = fare * 100;
      final paid = double.tryParse(_paidController.text) ?? 0;
      _pendingController.text = (_totalAmount - paid).toStringAsFixed(0);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
        return;
      }
      final fileSize = await File(image.path).length();
      if (fileSize > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image size exceeds 5MB'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() {
        _uploadedPhoto = File(image.path);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<http.Response> _submitBookingAPI(PlotInfo plot) async {
    setState(() {
      _isLoading = true;
      _isSubmitEnabled = false;
      _lastErrorMessage = null;
    });

    final url = Uri.parse('https://realapp.cheenu.in/api/booking/add');
    final body = plot.toJson();
    String? base64String;

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        final errorMessage = 'No internet connection. Please check your network and try again.';
        setState(() => _lastErrorMessage = errorMessage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      setState(() => _lastErrorMessage = 'Failed to check network connectivity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking connectivity: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      throw e;
    }

    if (_uploadedPhoto != null) {
      try {
        final bytes = await _uploadedPhoto!.readAsBytes();
        base64String = base64Encode(bytes);
        body['Screenshot'] = base64String;
      } catch (e) {
        setState(() => _lastErrorMessage = 'Failed to encode image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
        rethrow;
      }
    }

    final jsonBody = jsonEncode(body);
    print('Submitting booking to: $url');
    print('Payload: $jsonBody');

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonBody,
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking submitted successfully!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
          );
          return response;
        } else {
          String errorMessage;
          try {
            final responseBody = jsonDecode(response.body);
            errorMessage = responseBody['message'] ?? responseBody['error'] ?? response.body;
          } catch (_) {
            errorMessage = 'Server error: ${response.statusCode}';
          }
          setState(() => _lastErrorMessage = errorMessage);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $errorMessage'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
          if (attempt == 3) return response;
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      } catch (e) {
        String errorMessage = e.toString();
        if (e is TimeoutException) {
          errorMessage = 'Request timed out after 30 seconds.';
        } else if (e is SocketException) {
          errorMessage = 'Network error: Unable to connect to server.';
        }
        setState(() => _lastErrorMessage = errorMessage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
        if (attempt == 3) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final fare = double.tryParse(_fareController.text) ?? 0;
    final paidAmount = double.tryParse(_paidController.text) ?? 0;
    final bookedArea = double.tryParse(_bookedAreaController.text) ?? 0;
    final totalArea = double.tryParse(_areaController.text) ?? 0;
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.9;
    final dialogMaxHeight = screenSize.height * 0.8;

    return Dialog(
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: dialogMaxHeight),
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
                        validator: (value) => value!.isEmpty ? 'Project name is required' : null,
                      ),
                      _buildTextField(
                        controller: _plotTypeController,
                        label: 'Plot Type',
                        icon: Icons.category,
                        validator: (value) => value!.isEmpty ? 'Plot type is required' : null,
                      ),
                      _buildTextField(
                        controller: _clientController,
                        label: 'Client Name',
                        icon: Icons.person,
                        validator: (value) => value!.isEmpty ? 'Client name is required' : null,
                      ),
                      _buildTextField(
                        controller: _customerPhoneController,
                        label: 'Customer Phone',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) => value!.length != 10 ? 'Enter a valid 10-digit phone number' : null,
                      ),
                      _buildTextField(
                        controller: _bookedByController,
                        label: 'Booked By Dealer',
                        icon: Icons.person_pin,
                      ),
                      _buildTextField(
                        controller: _dealerPhoneController,
                        label: 'Dealer Phone',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) => value!.isEmpty || value.length != 10 ? 'Enter a valid 10-digit phone number' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _areaController,
                              label: 'Plot Area',
                              icon: Icons.square_foot,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _updateRemainingArea(),
                              validator: (value) => value!.isEmpty || (double.tryParse(value) ?? 0) <= 0 ? 'Valid plot area is required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<AreaUnit>(
                            value: _areaUnit,
                            items: AreaUnit.values
                                .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit == AreaUnit.sqYds ? 'Sq.Yds' : 'sq ft'),
                            ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _areaUnit = value;
                                  _updateRemainingArea();
                                });
                              }
                            },
                          ),
                        ],
                      ),
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
                                setState(() {});
                              },
                              validator: (value) {
                                if (value!.isEmpty || (double.tryParse(value) ?? 0) < 0) return 'Valid booked area is required';
                                if (bookedArea > totalArea) {
                                  return 'Booked area cannot exceed total area';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_areaUnit == AreaUnit.sqYds ? 'Sq.Yds' : 'sq ft'),
                        ],
                      ),
                      // REMAINING AREA FIELD
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _remainingAreaController,
                              label: 'Remaining Area',
                              icon: Icons.space_bar,
                              keyboardType: TextInputType.number,
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_areaUnit == AreaUnit.sqYds ? 'Sq.Yds' : 'sq ft'),
                        ],
                      ),
                      _buildTextField(
                        controller: _fareController,
                        label: 'Fare per Sq.Yd (₹)',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _updateTotalAmount(),
                        validator: (value) => value!.isEmpty || (double.tryParse(value) ?? 0) <= 0 ? 'Valid fare is required' : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Total Amount: ₹${_totalAmount.toStringAsFixed(0)} (based on 100 Sq.Yds)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildTextField(
                        controller: _paidController,
                        label: 'Paid Amount (₹)',
                        icon: Icons.payment,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final paid = double.tryParse(value) ?? 0;
                          setState(() {
                            _pendingController.text = (_totalAmount - paid).toStringAsFixed(0);
                          });
                        },
                        validator: (value) {
                          final paid = double.tryParse(value ?? '') ?? 0;
                          if (paid < 0) return 'Paid amount cannot be negative';
                          if (paid > _totalAmount) return 'Paid amount cannot exceed total amount';
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _pendingController,
                        label: 'Pending Amount (₹)',
                        icon: Icons.money_off,
                        keyboardType: TextInputType.number,
                        readOnly: true,
                      ),
                      _buildTextField(
                        controller: _purchasePriceController,
                        label: 'Purchase Price (₹)',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final price = double.tryParse(value ?? '') ?? 0;
                          if (price <= 0) return 'Purchase price must be greater than 0';
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _receivingController,
                        label: 'Receiving Amount (₹)',
                        icon: Icons.payment,
                        keyboardType: TextInputType.number,
                      ),
                      _buildTextField(
                        controller: _paidThroughController,
                        label: 'Paid Through',
                        icon: Icons.payment,
                        hintText: 'e.g., Online Transfer, Cash',
                      ),
                      _buildTextField(
                        controller: _bookingDateController,
                        label: 'Booking Date',
                        icon: Icons.calendar_today,
                        hintText: 'YYYY-MM-DD',
                        onChanged: (value) {
                          if (DateTime.tryParse(value) == null) {
                            _bookingDateController.text = DateTime.now().toIso8601String().split('T')[0];
                          }
                        },
                        validator: (value) => DateTime.tryParse(value!) == null ? 'Invalid date format' : null,
                      ),
                      Row(
                        children: [
                          const Text('Status:'),
                          Checkbox(
                            value: _status,
                            onChanged: (value) {
                              setState(() {
                                _status = value ?? false;
                              });
                            },
                          ),
                          const Text('Active'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.plot.color.withOpacity(0.1),
                          border: Border.all(color: widget.plot.color, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.plot.statusText.contains('Available')
                                  ? Icons.check_circle
                                  : widget.plot.statusText.contains('Pending')
                                  ? Icons.warning
                                  : Icons.info,
                              color: widget.plot.color,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Payment Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.plot.statusText,
                                    style: TextStyle(fontSize: 14, color: widget.plot.color, fontWeight: FontWeight.bold),
                                  ),
                                  if (widget.plot.statusText.contains('Pending'))
                                    Text(
                                      '(${widget.plot.paidPercentage.toStringAsFixed(1)}%) – ${_calculateRemainingArea().toStringAsFixed(0)} ${_areaUnit == AreaUnit.sqYds ? 'Sq.Yds' : 'sq ft'} left',
                                      style: TextStyle(fontSize: 12, color: widget.plot.color),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Upload Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Select Photo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Take Photo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_uploadedPhoto != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(_uploadedPhoto!, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isLoading || !_isSubmitEnabled || bookedArea > totalArea || _totalAmount <= 0)
                              ? null
                              : () async {
                            if (_formKey.currentState!.validate()) {
                              if (_totalAmount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Total amount must be greater than 0'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              final originalPlot = PlotInfo(
                                id: widget.plot.id,
                                area: widget.plot.area,
                                areaUnit: widget.plot.areaUnit,
                                fare: widget.plot.fare,
                                paidAmount: widget.plot.paidAmount,
                                totalAmount: widget.plot.totalAmount,
                                clientName: widget.plot.clientName,
                                photoPath: widget.plot.photoPath,
                                bookedArea: widget.plot.bookedArea,
                                projectName: widget.plot.projectName,
                                purchasePrice: widget.plot.purchasePrice,
                                receivingAmount: widget.plot.receivingAmount,
                                pendingAmount: widget.plot.pendingAmount,
                                paidThrough: widget.plot.paidThrough,
                                bookingDate: widget.plot.bookingDate,
                                bookedByDealer: widget.plot.bookedByDealer,
                                customerPhone: widget.plot.customerPhone,
                                dealerPhone: widget.plot.dealerPhone,
                                status: widget.plot.status,
                                bookingStatus: widget.plot.bookingStatus,
                                plotType: widget.plot.plotType,
                              );

                              widget.plot.clientName = _clientController.text;
                              widget.plot.fare = fare;
                              widget.plot.paidAmount = paidAmount;
                              widget.plot.totalAmount = _totalAmount;
                              widget.plot.bookedArea = bookedArea;
                              widget.plot.area = '${_areaController.text} ${_areaUnit == AreaUnit.sqYds ? 'Sq.Yds' : 'sq ft'}';
                              widget.plot.areaUnit = _areaUnit;
                              widget.plot.photoPath = _uploadedPhoto?.path;
                              widget.plot.projectName = _projectController.text;
                              widget.plot.purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
                              widget.plot.receivingAmount = double.tryParse(_receivingController.text) ?? 0;
                              widget.plot.pendingAmount = double.tryParse(_pendingController.text) ?? 0;
                              widget.plot.paidThrough = _paidThroughController.text;
                              widget.plot.bookedByDealer = _bookedByController.text;
                              widget.plot.customerPhone = _customerPhoneController.text;
                              widget.plot.dealerPhone = _dealerPhoneController.text;
                              widget.plot.status = _status;
                              widget.plot.bookingDate = DateTime.tryParse(_bookingDateController.text) ?? DateTime.now();
                              widget.plot.plotType = _plotTypeController.text;

                              if (bookedArea == 0 && paidAmount == 0) {
                                widget.plot.bookingStatus = BookingStatus.available;
                              } else if (paidAmount >= _totalAmount) {
                                widget.plot.bookingStatus = BookingStatus.sellout;
                              } else {
                                widget.plot.bookingStatus = BookingStatus.pending;
                              }

                              try {
                                final response = await _submitBookingAPI(widget.plot);
                                if (response.statusCode == 200 || response.statusCode == 201) {
                                  widget.onSave(widget.plot);
                                  Navigator.pop(context);
                                } else {
                                  widget.plot
                                    ..clientName = originalPlot.clientName
                                    ..fare = originalPlot.fare
                                    ..paidAmount = originalPlot.paidAmount
                                    ..totalAmount = originalPlot.totalAmount
                                    ..bookedArea = originalPlot.bookedArea
                                    ..area = originalPlot.area
                                    ..areaUnit = originalPlot.areaUnit
                                    ..photoPath = originalPlot.photoPath
                                    ..projectName = originalPlot.projectName
                                    ..purchasePrice = originalPlot.purchasePrice
                                    ..receivingAmount = originalPlot.receivingAmount
                                    ..pendingAmount = originalPlot.pendingAmount
                                    ..paidThrough = originalPlot.paidThrough
                                    ..bookedByDealer = originalPlot.bookedByDealer
                                    ..customerPhone = originalPlot.customerPhone
                                    ..dealerPhone = originalPlot.dealerPhone
                                    ..status = originalPlot.status
                                    ..bookingStatus = originalPlot.bookingStatus
                                    ..plotType = originalPlot.plotType;
                                }
                              } catch (e) {
                                widget.plot
                                  ..clientName = originalPlot.clientName
                                  ..fare = originalPlot.fare
                                  ..paidAmount = originalPlot.paidAmount
                                  ..totalAmount = originalPlot.totalAmount
                                  ..bookedArea = originalPlot.bookedArea
                                  ..area = originalPlot.area
                                  ..areaUnit = originalPlot.areaUnit
                                  ..photoPath = originalPlot.photoPath
                                  ..projectName = originalPlot.projectName
                                  ..purchasePrice = originalPlot.purchasePrice
                                  ..receivingAmount = originalPlot.receivingAmount
                                  ..pendingAmount = originalPlot.pendingAmount
                                  ..paidThrough = originalPlot.paidThrough
                                  ..bookedByDealer = originalPlot.bookedByDealer
                                  ..customerPhone = originalPlot.customerPhone
                                  ..dealerPhone = originalPlot.dealerPhone
                                  ..status = originalPlot.status
                                  ..bookingStatus = originalPlot.bookingStatus
                                  ..plotType = originalPlot.plotType;
                              } finally {
                                setState(() => _isSubmitEnabled = true);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                            'SUBMIT BOOKING',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

class PlotLayoutScreen extends StatefulWidget {
  const PlotLayoutScreen({Key? key}) : super(key: key);

  @override
  State<PlotLayoutScreen> createState() => _PlotLayoutScreenState();
}

class _PlotLayoutScreenState extends State<PlotLayoutScreen> {
  final TransformationController _transformationController = TransformationController();
  late Map<String, PlotInfo> plots;
  bool _isLoading = false;
  String? _errorMessage;
  final String projectName = 'Defence phase 2';

  @override
  void initState() {
    super.initState();
    _initializePlots();
    _fetchPlotData();
  }

  void _initializePlots() {
    plots = {};
    for (int i = 2; i <= 21; i++) {
      plots[i.toString()] = PlotInfo(id: i.toString(), area: '100 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    }
    for (int i = 49; i <= 67; i++) {
      plots[i.toString()] = PlotInfo(id: i.toString(), area: '100 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    }
    plots['1'] = PlotInfo(id: '1', area: '178 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['48'] = PlotInfo(id: '48', area: '85 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['47'] = PlotInfo(id: '47', area: '150 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['46'] = PlotInfo(id: '46', area: '150 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['45'] = PlotInfo(id: '45', area: '150 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['44'] = PlotInfo(id: '44', area: '150 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['43'] = PlotInfo(id: '43', area: '150 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['42'] = PlotInfo(id: '42', area: '200 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['41'] = PlotInfo(id: '41', area: '200 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['40'] = PlotInfo(id: '40', area: '152 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['39'] = PlotInfo(id: '39', area: '152 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['38'] = PlotInfo(id: '38', area: '152 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['37'] = PlotInfo(id: '37', area: '152 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['36'] = PlotInfo(id: '36', area: '152 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['35'] = PlotInfo(id: '35', area: '200 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['22'] = PlotInfo(id: '22', area: '150 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['23'] = PlotInfo(id: '23', area: '150 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['24'] = PlotInfo(id: '24', area: '150 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['25'] = PlotInfo(id: '25', area: '150 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['26'] = PlotInfo(id: '26', area: '150 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['27'] = PlotInfo(id: '27', area: '200 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['28'] = PlotInfo(id: '28', area: '200 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['29'] = PlotInfo(id: '29', area: '152 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['30'] = PlotInfo(id: '30', area: '152 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['31'] = PlotInfo(id: '31', area: '152 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['32'] = PlotInfo(id: '32', area: '152 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['33'] = PlotInfo(id: '33', area: '152 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['34'] = PlotInfo(id: '34', area: '200 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    plots['68'] = PlotInfo(id: '68', area: '178 Sq.Yds', fare: 0.0, projectName: projectName, plotType: projectName);
    print('Initialized ${plots.length} plots');
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
    showDialog(
      context: context,
      builder: (context) => BookingDialog(
        plot: plots[plotId]!,
        onSave: (updatedPlot) {
          setState(() {
            plots[plotId] = updatedPlot;
            print('Updated plot $plotId: ${updatedPlot.toJson()}');
          });
        },
      ),
    );
  }

  Widget _buildPlot(String plotId, {required double width, required double height}) {
    if (!plots.containsKey(plotId)) {
      print('Plot $plotId not found, returning empty container');
      return Container(width: width, height: height, color: Colors.grey);
    }

    final plot = plots[plotId]!;
    final int id = int.parse(plotId);

    final Map<String, Map<String, String>> plotMeasurements = {
      '47': {'left': "36'-7\""},
      '46': {'left': "36'-2\""},
      '45': {'left': "35'-7\""},
      '44': {'left': "34'-0\""},
      '43': {'left': "45'-0\""},
      '42': {'left': "45'-0\""},
      '41': {'left': "44'-1\"", 'top': "40'-8\""},
      '40': {'left': "32'-7\"", 'top': "41'-4\""},
      '39': {'left': "32'-1\"", 'top': "41'-11\""},
      '38': {'left': "31'-11\"", 'top': "42'-6\""},
      '37': {'left': "31'-4\"", 'top': "43'-0\""},
      '36': {'left': "31'-0\"", 'top': "43'-6\""},
      '35': {'left': "40'-9\""},
      '34': {'left': "40'-9\""},
      '32': {'right': "44'-1\"", 'top': "40'-8\""},
      '31': {'right': "32'-7\"", 'top': "41'-4\""},
      '30': {'right': "32'-1\"", 'top': "41'-11\""},
      '29': {'right': "31'-11\"", 'top': "42'-6\""},
      '28': {'right': "31'-4\"", 'top': "43'-0\""},
      '27': {'right': "45'-0\""},
      '26': {'right': "45'-0\""},
      '25': {'right': "34'-0\""},
      '24': {'right': "35'-7\""},
      '23': {'right': "36'-2\""},
      '22': {'right': "36'-7\""},
    };

    final measurements = plotMeasurements[plotId] ?? {};
    final String rightLabel = measurements['right'] ?? (id >= 47 && id <= 67 ? "22'-6\"" : "40'-0\"");
    final String? leftLabel = measurements['left'] ?? (id >= 2 && id <= 20 ? "22'-6\"" : null);
    final String? topLabel = measurements['top'];

    return GestureDetector(
      onTap: () => _showBookingDialog(plotId),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Row(
              children: [
                if (plot.bookedArea > 0 && plot.bookedArea < plot._parseArea(plot.area, plot.areaUnit))
                  Container(
                    width: width * plot.bookedPercentage,
                    height: height,
                    color: Colors.blue.shade300,
                  ),
                Container(
                  width: width * (1 - plot.bookedPercentage),
                  height: height,
                  color: plot.color,
                ),
              ],
            ),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      plotId,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      plot.area,
                      style: const TextStyle(fontSize: 7),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      plot.statusText,
                      style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 2.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    rightLabel,
                    style: const TextStyle(fontSize: 7, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
            if (leftLabel != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      leftLabel,
                      style: const TextStyle(fontSize: 7, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            if (topLabel != null)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      topLabel,
                      style: const TextStyle(fontSize: 7, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoad(String label, {bool isVertical = false, required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade600,
      child: Center(
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
              if (label.contains('WIDE'))
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  height: 2,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final plotWidth = screenSize.width * 0.11;
    final plotHeight = screenSize.height * 0.07;
    final largePlotHeight = screenSize.height * 0.09;
    final roadWidth = screenSize.width * 0.06;
    final roadHeight = screenSize.height * 0.8;
    final smallRoadHeight = screenSize.height * 0.06;
    final legendWidth = screenSize.width * 0.25;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Defence Land Layout'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              setState(() {
                final Matrix4 matrix = _transformationController.value.clone();
                matrix.scale(1.2);
                _transformationController.value = matrix;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                final Matrix4 matrix = _transformationController.value.clone();
                matrix.scale(0.8);
                _transformationController.value = matrix;
              });
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
            const Center(
              child: CircularProgressIndicator(),
            )
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
                    padding: const EdgeInsets.all(6),
                    color: Colors.white,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: List.generate(21, (index) {
                            final plotId = (index == 20) ? '68' : (48 + index).toString();
                            return _buildPlot(plotId, width: plotWidth, height: index == 20 ? largePlotHeight : plotHeight);
                          }),
                        ),
                        _buildRoad('27.5\' WIDE ROAD', isVertical: true, width: roadWidth, height: roadHeight),
                        Column(
                          children: [
                            _buildPlot('47', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('46', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('45', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('44', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('43', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('42', width: plotWidth * 1.2, height: largePlotHeight),
                            _buildRoad('20\' WIDE ROAD', width: plotWidth * 1.2, height: smallRoadHeight),
                            _buildPlot('41', width: plotWidth * 1.2, height: largePlotHeight),
                            _buildPlot('40', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('39', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('38', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('37', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('36', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('35', width: plotWidth * 1.2, height: largePlotHeight),
                          ],
                        ),
                        _buildRoad('27.5\' WIDE ROAD', isVertical: true, width: roadWidth, height: roadHeight),
                        Column(
                          children: [
                            _buildPlot('22', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('23', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('24', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('25', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('26', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('27', width: plotWidth * 1.2, height: largePlotHeight),
                            _buildRoad('20\' WIDE ROAD', width: plotWidth * 1.2, height: smallRoadHeight),
                            _buildPlot('28', width: plotWidth * 1.2, height: largePlotHeight),
                            _buildPlot('29', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('30', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('31', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('32', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('33', width: plotWidth * 1.2, height: plotHeight),
                            _buildPlot('34', width: plotWidth * 1.2, height: largePlotHeight),
                          ],
                        ),
                        _buildRoad('27.5\' WIDE ROAD', isVertical: true, width: roadWidth, height: roadHeight),
                        Column(
                          children: List.generate(21, (index) {
                            final plotId = (index == 20) ? '1' : (21 - index).toString();
                            return _buildPlot(plotId, width: plotWidth, height: index == 20 ? largePlotHeight : plotHeight);
                          }),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: legendWidth,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'LEGEND',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildLegendItem('200Sq.Yrd', Colors.white),
                              _buildLegendItem('178Sq.Yrd', const Color(0xFFE6D5E6)),
                              _buildLegendItem('152Sq.Yrd', Colors.white),
                              _buildLegendItem('150Sq.Yrd', const Color(0xFFE8E8D5)),
                              _buildLegendItem('100Sq.Yrd', const Color(0xFFD5E8E8)),
                              _buildLegendItem('85Sq.Yrd', Colors.white),
                              _buildLegendItem('Booked Area', Colors.blue.shade300),
                              const SizedBox(height: 8),
                              const Text(
                                'AREA DETAILS:-',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildAreaDetail('Land Area', '11671.07', 'Sq.Yds'),
                              _buildAreaDetail('', '9758.50', 'Sq. Mtr.'),
                              _buildAreaDetail('', '11.57', 'Bigha'),
                              const SizedBox(height: 6),
                              _buildAreaDetail('Plot Area', '8531.03', 'Sq.Yds.'),
                              _buildAreaDetail('', '7133.03', 'Sq.Mts.'),
                              _buildAreaDetail('', '8.46', 'Bigha'),
                              const SizedBox(height: 6),
                              _buildAreaDetail('Road Area', '3140.04', 'SqYds.'),
                              _buildAreaDetail('', '2625.47', 'Sq. Mts.'),
                              _buildAreaDetail('', '3.11', 'Bigha'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusItem(Colors.green.shade200, 'Available'),
                  _buildStatusItem(Colors.red.shade300, 'Pending (<50%)'),
                  _buildStatusItem(Colors.yellow.shade300, 'Pending (≥50%)'),
                  _buildStatusItem(Colors.blue.shade300, 'Booked'),
                  _buildStatusItem(Colors.grey.shade300, 'Sold Out'),
                  _buildStatusItem(Colors.blue.shade300, 'Booked Area'),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _transformationController.value = Matrix4.identity();
          });
        },
        child: const Icon(Icons.fit_screen),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.black),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildAreaDetail(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: 50,
              child: Text(
                label,
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
              ),
            )
          else
            const SizedBox(width: 50),
          Container(
            width: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 8),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 3),
          SizedBox(
            width: 40,
            child: Text(
              unit,
              style: const TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.black),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}
