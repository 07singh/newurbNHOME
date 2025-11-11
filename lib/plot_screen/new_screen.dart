import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

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

  @override
  void initState() {
    super.initState();

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

  void _updateTotalAmount() {
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final bookedArea = double.tryParse(_bookedAreaController.text) ?? 0;
    final unitFactor = _areaUnit == AreaUnit.sqFt ? 1 / 9.0 : 1.0;
    final bookedInYds = bookedArea * unitFactor;

    setState(() {
      _totalAmount = purchasePrice * bookedInYds;
      final receiving = double.tryParse(_receivingController.text) ?? 0;
      _pendingController.text = (_totalAmount - receiving).toStringAsFixed(0);
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
          final respJson = jsonDecode(response.body);
          if (respJson['status'] == 'Success') {
            if (!mounted) return response;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${respJson['message'] ?? 'Booking saved!'} '
                      '(Remaining: ${respJson['remaining_area']})',
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
            throw Exception(
                'Server said: ${respJson['message'] ?? 'Unknown error'}');
          }
        } else {
          final respJson = jsonDecode(response.body);
          final error =
              respJson['message'] ?? 'Server error: ${response.statusCode}';
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
                        validator: (v) => v!.isEmpty || v.length != 10 ? '10 digits required' : null,
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

  Widget _buildPlot(String plotId, {required double width, required double height}) {
    if (!plots.containsKey(plotId)) {
      print('Plot $plotId not found, returning empty container');
      return Container(width: width, height: height, color: Colors.grey);
    }

    final plot = plots[plotId]!;
    final int id = int.parse(plotId);
    final bool isLarge = height > 80;

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
              Container(
                width: width,
                height: height,
                color: plot.color,
              ),

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
                      style: const TextStyle(
                        fontSize: 7,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
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
                              _buildLegendItem('Partially Booked', Colors.orange.shade300),

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