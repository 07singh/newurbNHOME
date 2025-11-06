import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PlotInfo {
  final String id;
  final String area;
  double fare;
  double paidAmount;
  double totalAmount;
  String clientName;
  String? photoPath;

  PlotInfo({
    required this.id,
    required this.area,
    required this.fare,
    this.paidAmount = 0,
    this.totalAmount = 0,
    this.clientName = '',
    this.photoPath,
  }) {
    totalAmount = fare;
  }

  Color get color {
    if (paidAmount == 0) return const Color(0xFFB8E6B8); // Green (Available)
    if (paidAmount >= fare * 0.5) return const Color(0xFFFFEB3B); // Yellow (50% Paid)
    return const Color(0xFFFFCDD2); // Red (Below 50% Paid)
  }

  double get remainingAmount => totalAmount - paidAmount;
}

class PlotScreen extends StatefulWidget {
  const PlotScreen({Key? key}) : super(key: key);

  @override
  State<PlotScreen> createState() => _PlotScreenState();
}

class _PlotScreenState extends State<PlotScreen> {
  final TransformationController _transformationController = TransformationController();
  late Map<String, PlotInfo> plots;

  @override
  void initState() {
    super.initState();
    _initializePlots();
  }

  void _initializePlots() {
    plots = {
      // Row A
      'A1': PlotInfo(id: 'A1', area: '90 YD', fare: 0),
      'A2': PlotInfo(id: 'A2', area: '90 YD', fare: 0),
      'A3': PlotInfo(id: 'A3', area: '90 YD', fare: 0),
      'A4': PlotInfo(id: 'A4', area: '90 YD', fare: 0),
      'A5': PlotInfo(id: 'A5', area: '90 YD', fare: 0),
      'A6': PlotInfo(id: 'A6', area: '90 YD', fare: 0),
      'A7': PlotInfo(id: 'A7', area: '100 SQ YD', fare: 0),
      'A8': PlotInfo(id: 'A8', area: '100 SQ YD', fare: 0),
      'A9': PlotInfo(id: 'A9', area: '100 SQ YD', fare: 0),
      'A10': PlotInfo(id: 'A10', area: '177 SQ YD', fare: 0),
      // Row B
      'B1': PlotInfo(id: 'B1', area: '90 YD', fare: 0),
      'B2': PlotInfo(id: 'B2', area: '90 YD', fare: 0),
      'B3': PlotInfo(id: 'B3', area: '90 YD', fare: 0),
      'B4': PlotInfo(id: 'B4', area: '90 YD', fare: 0),
      'B5': PlotInfo(id: 'B5', area: '90 YD', fare: 0),
      'B6': PlotInfo(id: 'B6', area: '90 YD', fare: 0),
      'B7': PlotInfo(id: 'B7', area: '100 SQ YD', fare: 0),
      'B8': PlotInfo(id: 'B8', area: '100 SQ YD', fare: 0),
      'B9': PlotInfo(id: 'B9', area: '100 SQ YD', fare: 0),
      'B10': PlotInfo(id: 'B10', area: '177 SQ YD', fare: 0),
      // Row C
      'C1': PlotInfo(id: 'C1', area: '0.173', fare: 0),
      'C2': PlotInfo(id: 'C2', area: '0.173', fare: 0),
      'C3': PlotInfo(id: 'C3', area: '100 SQ YD', fare: 0),
      'C4': PlotInfo(id: 'C4', area: '100 SQ YD', fare: 0),
      'C5': PlotInfo(id: 'C5', area: '100 SQ YD', fare: 0),
      'C6': PlotInfo(id: 'C6', area: '100 SQ YD', fare: 0),
      'C7': PlotInfo(id: 'C7', area: '100 SQ YD', fare: 0),
      'C8': PlotInfo(id: 'C8', area: '100 SQ YD', fare: 0),
      'C9': PlotInfo(id: 'C9', area: '100 SQ YD', fare: 0),
      'C10': PlotInfo(id: 'C10', area: '177 SQ YD', fare: 0),
      // Row D
      'D1': PlotInfo(id: 'D1', area: '0.173', fare: 0),
      'D2': PlotInfo(id: 'D2', area: '0.173', fare: 0),
      'D3': PlotInfo(id: 'D3', area: '100 SQ YD', fare: 0),
      'D4': PlotInfo(id: 'D4', area: '100 SQ YD', fare: 0),
      'D5': PlotInfo(id: 'D5', area: '100 SQ YD', fare: 0),
      'D6': PlotInfo(id: 'D6', area: '100 SQ YD', fare: 0),
      'D7': PlotInfo(id: 'D7', area: '100 SQ YD', fare: 0),
      'D8': PlotInfo(id: 'D8', area: '100 SQ YD', fare: 0),
      'D9': PlotInfo(id: 'D9', area: '100 SQ YD', fare: 0),
      'D10': PlotInfo(id: 'D10', area: '177 SQ YD', fare: 0),
      // Row E
      'E1': PlotInfo(id: 'E1', area: '0.173', fare: 0),
      'E2': PlotInfo(id: 'E2', area: '0.173', fare: 0),
      'E3': PlotInfo(id: 'E3', area: '100 SQ YD', fare: 0),
      'E4': PlotInfo(id: 'E4', area: '100 SQ YD', fare: 0),
      'E5': PlotInfo(id: 'E5', area: '100 SQ YD', fare:0),
      'E6': PlotInfo(id: 'E6', area: '100 SQ YD', fare: 0),
      'E7': PlotInfo(id: 'E7', area: '100 SQ YD', fare: 0),
      'E8': PlotInfo(id: 'E8', area: '100 SQ YD', fare: 0),
      'E9': PlotInfo(id: 'E9', area: '100 SQ YD', fare: 0),
      'E10': PlotInfo(id: 'E10', area: '177 SQ YD', fare: 0),
      // Row F
      'F1': PlotInfo(id: 'F1', area: '0.173', fare: 0),
      'F2': PlotInfo(id: 'F2', area: '0.173', fare: 0),
      'F3': PlotInfo(id: 'F3', area: '100 SQ YD', fare: 0),
      'F4': PlotInfo(id: 'F4', area: '100 SQ YD', fare: 0),
      'F5': PlotInfo(id: 'F5', area: '100 SQ YD', fare: 0),
      'F6': PlotInfo(id: 'F6', area: '100 SQ YD', fare: 0),
      'F7': PlotInfo(id: 'F7', area: '100 SQ YD', fare: 0),
      'F8': PlotInfo(id: 'F8', area: '100 SQ YD', fare: 0),
      'F9': PlotInfo(id: 'F9', area: '100 SQ YD', fare: 0),
      'F10': PlotInfo(id: 'F10', area: '177 SQ YD', fare: 0),
      // Right Section
      'R1': PlotInfo(id: 'R1', area: '363 SQ YD', fare: 0),
      'R2': PlotInfo(id: 'R2', area: '100 SQ YD', fare: 0),
      'R3': PlotInfo(id: 'R3', area: '100 SQ YD', fare: 0),
      'R4': PlotInfo(id: 'R4', area: '363 SQ YD', fare: 0),
      'R5': PlotInfo(id: 'R5', area: '100 SQ YD', fare: 0),
      'R6': PlotInfo(id: 'R6', area: '100 SQ YD', fare: 0),
      'R7': PlotInfo(id: 'R7', area: '363 SQ YD', fare: 0),
      'R8': PlotInfo(id: 'R8', area: '100 SQ YD', fare: 0),
      'R9': PlotInfo(id: 'R9', area: '100 SQ YD', fare: 0),
    };
  }

  void _showBookingDialog(String plotId) {
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

  Widget _buildPlot(String plotId, {double width = 60, double height = 40}) {
    final plot = plots[plotId]!;
    return GestureDetector(
      onTap: () => _showBookingDialog(plotId),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: plot.color,
          border: Border.all(color: Colors.black87, width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                plotId,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                plot.area,
                style: const TextStyle(fontSize: 7, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoad(String label, {bool isVertical = false}) {
    return Container(
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
          // Trees on top
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
          // Road text and line
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
          // Trees on bottom
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
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('green residency phase 2'),
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
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
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
                  child: Column(
                    children: [
                      // Top Expressway
                      _buildExpressway(),
                      const SizedBox(height: 20),

                      // Main Plot Area
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Section (Main plots)
                          Column(
                            children: [
                              // Row A
                              Row(
                                children: [
                                  ...List.generate(6, (i) => _buildPlot('A${i + 1}', width: 55, height: 45)),
                                  ...List.generate(3, (i) => _buildPlot('A${i + 7}', width: 55, height: 45)),
                                  _buildPlot('A10', width: 90, height: 45),
                                ],
                              ),
                              const SizedBox(height: 2),
                              _buildRoad("22' WIDE ROAD"),
                              const SizedBox(height: 2),

                              // Row B
                              Row(
                                children: [
                                  ...List.generate(6, (i) => _buildPlot('B${i + 1}', width: 55, height: 45)),
                                  ...List.generate(3, (i) => _buildPlot('B${i + 7}', width: 55, height: 45)),
                                  _buildPlot('B10', width: 90, height: 45),
                                ],
                              ),
                              const SizedBox(height: 2),
                              _buildRoad("22' WIDE ROAD"),
                              const SizedBox(height: 2),

                              // Row C
                              Row(
                                children: [
                                  ...List.generate(2, (i) => _buildPlot('C${i + 1}', width: 55, height: 45)),
                                  ...List.generate(7, (i) => _buildPlot('C${i + 3}', width: 55, height: 45)),
                                  _buildPlot('C10', width: 90, height: 45),
                                ],
                              ),
                              const SizedBox(height: 2),
                              _buildRoad("22' WIDE ROAD"),
                              const SizedBox(height: 2),

                              // Row D
                              Row(
                                children: [
                                  ...List.generate(2, (i) => _buildPlot('D${i + 1}', width: 55, height: 45)),
                                  ...List.generate(7, (i) => _buildPlot('D${i + 3}', width: 55, height: 45)),
                                  _buildPlot('D10', width: 90, height: 45),
                                ],
                              ),
                              const SizedBox(height: 2),
                              _buildRoad("22' WIDE ROAD"),
                              const SizedBox(height: 2),

                              // Row E
                              Row(
                                children: [
                                  ...List.generate(2, (i) => _buildPlot('E${i + 1}', width: 55, height: 45)),
                                  ...List.generate(7, (i) => _buildPlot('E${i + 3}', width: 55, height: 45)),
                                  _buildPlot('E10', width: 90, height: 45),
                                ],
                              ),
                              const SizedBox(height: 2),
                              _buildRoad("22' WIDE ROAD"),
                              const SizedBox(height: 2),

                              // Row F
                              Row(
                                children: [
                                  ...List.generate(2, (i) => _buildPlot('F${i + 1}', width: 55, height: 45)),
                                  ...List.generate(7, (i) => _buildPlot('F${i + 3}', width: 55, height: 45)),
                                  _buildPlot('F10', width: 90, height: 45),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Sold Out Section
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

                          // Right Section
                          Column(
                            children: [
                              // R1-R3
                              Row(
                                children: [
                                  _buildPlot('R1', width: 80, height: 93),
                                  const SizedBox(width: 2),
                                  Column(
                                    children: [
                                      _buildPlot('R2', width: 55, height: 45),
                                      const SizedBox(height: 2),
                                      _buildPlot('R3', width: 55, height: 45),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              _buildRoad("22' WIDE ROAD"),
                              const SizedBox(height: 2),

                              // R4-R6
                              Row(
                                children: [
                                  _buildPlot('R4', width: 80, height: 93),
                                  const SizedBox(width: 2),
                                  Column(
                                    children: [
                                      _buildPlot('R5', width: 55, height: 45),
                                      const SizedBox(height: 2),
                                      _buildPlot('R6', width: 55, height: 45),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              _buildRoad("22' WIDE ROAD"),
                              const SizedBox(height: 2),

                              // R7-R9
                              Row(
                                children: [
                                  _buildPlot('R7', width: 80, height: 93),
                                  const SizedBox(width: 2),
                                  Column(
                                    children: [
                                      _buildPlot('R8', width: 55, height: 45),
                                      const SizedBox(height: 2),
                                      _buildPlot('R9', width: 55, height: 45),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Sold Out
                              Container(
                                width: 137,
                                height: 80,
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Text(
                                    'SOLD OUT',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Bottom Road
                      Container(
                        width: 800,
                        padding: const EdgeInsets.all(8),
                        color: Colors.grey.shade700,
                        child: const Center(
                          child: Text(
                            '100 FT WIDE ROAD ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Bottom Expressway
                      _buildExpressway(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Legend
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
                  _buildStatusItem(const Color(0xFFB8E6B8), 'Available'),
                  _buildStatusItem(const Color(0xFFFFEB3B), '50% Paid'),
                  _buildStatusItem(const Color(0xFFFFCDD2), 'Below 50%'),
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
    _transformationController.dispose();
    super.dispose();
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
  late TextEditingController _paidController;
  late TextEditingController _fareController;
  late TextEditingController _areaController; // ✅ Added area controller
  File? _uploadedPhoto;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _clientController = TextEditingController(text: widget.plot.clientName);
    _paidController =
        TextEditingController(text: widget.plot.paidAmount.toStringAsFixed(0));
    _fareController =
        TextEditingController(text: widget.plot.fare.toStringAsFixed(0));
    _areaController = TextEditingController(text: widget.plot.area);
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _uploadedPhoto = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Logic Update
    final fare = double.tryParse(_fareController.text) ?? 0;
    final paidAmount = double.tryParse(_paidController.text) ?? 0;
    final totalAmount = fare * 100; // ✅ Total = fare × 100
    final remaining = (totalAmount - paidAmount).clamp(0, double.infinity); // ✅ Remaining balance

    return Dialog(
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 700),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Plot ${widget.plot.id} - Booking',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

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

                // ✅ Plot Area (Always Visible)
                TextField(
                  controller: _areaController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Plot Area',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.square_foot),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 16),

                // Plot Fare (Editable)
                TextField(
                  controller: _fareController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Plot Fare (₹)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                    hintText: 'Enter plot fare',
                  ),
                  onChanged: (value) => setState(() {}),
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
                    hintText: 'Enter paid amount',
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // ✅ Total Amount (Fare × 100)
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Total Amount (₹)',
                    hintText: '₹${totalAmount.toStringAsFixed(0)}',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Remaining Amount (Total - Paid)
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Remaining Amount (₹)',
                    hintText: '₹${remaining.toStringAsFixed(0)}',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.money_off),
                    filled: true,
                    fillColor:
                    remaining > 0 ? Colors.red.shade50 : Colors.green.shade50,
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: paidAmount >= totalAmount * 0.5
                        ? Colors.yellow.shade50
                        : paidAmount > 0
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: paidAmount >= totalAmount * 0.5
                          ? Colors.yellow.shade700
                          : paidAmount > 0
                          ? Colors.red.shade700
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        paidAmount >= totalAmount * 0.5
                            ? Icons.check_circle
                            : paidAmount > 0
                            ? Icons.warning
                            : Icons.info,
                        color: paidAmount >= totalAmount * 0.5
                            ? Colors.green.shade700
                            : paidAmount > 0
                            ? Colors.red.shade700
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Status',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              totalAmount > 0
                                  ? paidAmount >= totalAmount * 0.5
                                  ? '50% or More Paid (${((paidAmount / totalAmount) * 100).toStringAsFixed(1)}%)'
                                  : paidAmount > 0
                                  ? 'Below 50% Paid (${((paidAmount / totalAmount) * 100).toStringAsFixed(1)}%)'
                                  : 'No Payment Made'
                                  : 'Enter Plot Fare First',
                              style: TextStyle(
                                fontSize: 14,
                                color: paidAmount >= totalAmount * 0.5
                                    ? Colors.green.shade700
                                    : paidAmount > 0
                                    ? Colors.red.shade700
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Upload Photo Section
                const Text(
                  'Upload Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

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
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_uploadedPhoto != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border:
                      Border.all(color: Colors.grey.shade400, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        _uploadedPhoto!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.plot.clientName = _clientController.text;
                      widget.plot.paidAmount = paidAmount;
                      widget.plot.fare = fare;
                      widget.plot.photoPath = _uploadedPhoto?.path;

                      widget.onSave(widget.plot);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Plot booking saved successfully!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade700,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'SUBMIT BOOKING',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  @override
  void dispose() {
    _clientController.dispose();
    _paidController.dispose();
    _fareController.dispose();
    super.dispose();
  }
}
