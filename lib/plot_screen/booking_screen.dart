import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BookingDialog extends StatefulWidget {
  final Map<String, dynamic> plot;
  final Function(Map<String, dynamic>) onSave;

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
  bool _status = true;
  File? _uploadedPhoto;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _clientController = TextEditingController(text: widget.plot['clientName'] ?? '');
    _areaController = TextEditingController(text: widget.plot['area']?.replaceAll(' Sq.Yds', '') ?? '');
    _bookedAreaController = TextEditingController(text: (widget.plot['bookedArea'] ?? 0).toString());
    _fareController = TextEditingController(text: (widget.plot['fare'] ?? 0).toString());
    _paidController = TextEditingController(text: (widget.plot['paidAmount'] ?? 0).toString());
    _projectController = TextEditingController(text: widget.plot['projectName'] ?? '');
    _purchasePriceController = TextEditingController(text: (widget.plot['purchasePrice'] ?? 0).toString());
    _receivingController = TextEditingController(text: (widget.plot['receivingAmount'] ?? 0).toString());
    _pendingController = TextEditingController(text: (widget.plot['pendingAmount'] ?? 0).toString());
    _paidThroughController = TextEditingController(text: widget.plot['paidThrough'] ?? '');
    _bookedByController = TextEditingController(text: widget.plot['bookedByDealer'] ?? '');
    _customerPhoneController = TextEditingController(text: widget.plot['customerPhone'] ?? '');
    _dealerPhoneController = TextEditingController(text: widget.plot['dealerPhone'] ?? '');
    _bookingDateController = TextEditingController(
        text: (widget.plot['bookingDate'] ?? DateTime.now()).toString().split(' ')[0]);
    _status = widget.plot['status'] ?? true;
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _uploadedPhoto = File(image.path);
      });
    }
  }

  Color getColor(double paid, double total) {
    if (paid == 0) return Colors.green.shade200;
    if (paid >= total * 0.5) return Colors.yellow.shade300;
    return Colors.red.shade300;
  }

  double getBookedPercentage(double booked, double total) {
    if (total == 0) return 0;
    return booked / total;
  }

  Future<void> _submitBookingAPI(Map<String, dynamic> plot) async {
    final url = Uri.parse('https://realapp.cheenu.in/api/booking/add/');
    final body = Map<String, dynamic>.from(plot);

    if (_uploadedPhoto != null) {
      body['photo'] = base64Encode(await _uploadedPhoto!.readAsBytes());
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${response.body}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fare = double.tryParse(_fareController.text) ?? 0;
    final paidAmount = double.tryParse(_paidController.text) ?? 0;
    final totalAmount = fare * 100;
    final bookedArea = double.tryParse(_bookedAreaController.text) ?? 0;
    final totalArea = double.tryParse(_areaController.text) ?? 0;

    return Dialog(
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 800),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Plot Booking',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Project Name
                TextField(
                  controller: _projectController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.apartment),
                  ),
                ),
                const SizedBox(height: 16),
                // Client Name
                TextField(
                  controller: _clientController,
                  decoration: const InputDecoration(
                    labelText: 'Client Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                // Customer Phone
                TextField(
                  controller: _customerPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Customer Phone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                // Booked By Dealer
                TextField(
                  controller: _bookedByController,
                  decoration: const InputDecoration(
                    labelText: 'Booked By Dealer',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_pin),
                  ),
                ),
                const SizedBox(height: 16),
                // Dealer Phone
                TextField(
                  controller: _dealerPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Dealer Phone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                // Plot Area
                TextField(
                  controller: _areaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Plot Area (Sq.Yds)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.square_foot),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                // Booked Area
                TextField(
                  controller: _bookedAreaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Booked Area (Sq.Yds)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.crop_square),
                    errorText: bookedArea > totalArea ? 'Booked area cannot exceed total area' : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                // Plot Fare
                TextField(
                  controller: _fareController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Plot Fare (₹)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                // Paid Amount
                TextField(
                  controller: _paidController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Paid Amount (₹)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payment),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                // Upload Photo
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo),
                      label: const Text('Upload Photo'),
                    ),
                    const SizedBox(width: 12),
                    _uploadedPhoto != null
                        ? SizedBox(width: 50, height: 50, child: Image.file(_uploadedPhoto!, fit: BoxFit.cover))
                        : const Text('No Photo'),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Update the plot map
                    widget.plot['projectName'] = _projectController.text;
                    widget.plot['clientName'] = _clientController.text;
                    widget.plot['customerPhone'] = _customerPhoneController.text;
                    widget.plot['bookedByDealer'] = _bookedByController.text;
                    widget.plot['dealerPhone'] = _dealerPhoneController.text;
                    widget.plot['area'] = double.tryParse(_areaController.text) ?? 0;
                    widget.plot['bookedArea'] = double.tryParse(_bookedAreaController.text) ?? 0;
                    widget.plot['fare'] = double.tryParse(_fareController.text) ?? 0;
                    widget.plot['paidAmount'] = double.tryParse(_paidController.text) ?? 0;
                    widget.plot['status'] = _status;
                    widget.plot['photo'] = _uploadedPhoto;

                    widget.onSave(widget.plot); // Update parent
                    _submitBookingAPI(widget.plot); // Submit to API
                    Navigator.pop(context);
                  },
                  child: const Text('Save & Submit'),
                ),
              ],
            ),
          ),
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
  Map<String, Map<String, dynamic>> plots = {
    '48': {
      'area': 85,
      'fare': 0,
      'paidAmount': 0,
      'bookedArea': 0,
      'projectName': 'Test Project',
      'purchasePrice': 0,
      'receivingAmount': 0,
      'pendingAmount': 0,
      'paidThrough': 'Online Transfer',
      'bookedByDealer': '',
      'customerPhone': '',
      'dealerPhone': '',
      'bookingDate': DateTime.now(),
      'status': true,
      'photo': null,
    },
    '49': {
      'area': 90,
      'fare': 0,
      'paidAmount': 0,
      'bookedArea': 0,
      'projectName': 'Test Project',
      'purchasePrice': 0,
      'receivingAmount': 0,
      'pendingAmount': 0,
      'paidThrough': 'Online Transfer',
      'bookedByDealer': '',
      'customerPhone': '',
      'dealerPhone': '',
      'bookingDate': DateTime.now(),
      'status': false,
      'photo': null,
    },
  };

  void _openBookingDialog(String plotId) {
    showDialog(
      context: context,
      builder: (context) => BookingDialog(
        plot: plots[plotId]!,
        onSave: (updatedPlot) {
          setState(() {
            plots[plotId] = updatedPlot;
          });
        },
      ),
    );
  }

  Color getColor(double paid, double total) {
    if (paid == 0) return Colors.green.shade200;
    if (paid >= total * 0.5) return Colors.yellow.shade300;
    return Colors.red.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plot Layout')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: plots.length,
        itemBuilder: (context, index) {
          final plotId = plots.keys.elementAt(index);
          final plot = plots[plotId]!;
          final totalFare = (plot['fare'] ?? 0) * 100;
          final paidAmount = plot['paidAmount'] ?? 0;

          return GestureDetector(
            onTap: () => _openBookingDialog(plotId),
            child: Container(
              decoration: BoxDecoration(
                color: getColor(paidAmount, totalFare),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Plot $plotId\n₹${paidAmount.toString()}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

