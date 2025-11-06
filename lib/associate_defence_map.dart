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
    if (paidAmount == 0) return Colors.green.shade200;
    if (paidAmount >= fare * 0.5) return Colors.yellow.shade300;
    return Colors.red.shade300;
  }

  double get remainingAmount => totalAmount - paidAmount;
  double get paidPercentage => (paidAmount / totalAmount) * 100;
}

class PlotLayoutScreen extends StatefulWidget {
  const PlotLayoutScreen({Key? key}) : super(key: key);

  @override
  State<PlotLayoutScreen> createState() => _PlotLayoutScreenState();
}

class _PlotLayoutScreenState extends State<PlotLayoutScreen> {
  final TransformationController _transformationController = TransformationController();
  late Map<String, PlotInfo> plots;

  @override
  void initState() {
    super.initState();
    _initializePlots();
  }

  void _initializePlots() {
    plots = {
      // Left column
      '48': PlotInfo(id: '48', area: '85 Sq.Yds', fare: 0),
      '49': PlotInfo(id: '49', area: '100 Sq.Yds', fare: 0),
      '50': PlotInfo(id: '50', area: '100 Sq.Yds', fare: 0),
      '51': PlotInfo(id: '51', area: '100 Sq.Yds', fare: 0),
      '52': PlotInfo(id: '52', area: '100 Sq.Yds', fare: 0),
      '53': PlotInfo(id: '53', area: '100 Sq.Yds', fare: 0),
      '54': PlotInfo(id: '54', area: '100 Sq.Yds', fare: 0),
      '55': PlotInfo(id: '55', area: '100 Sq.Yds', fare: 0),
      '56': PlotInfo(id: '56', area: '100 Sq.Yds', fare: 0),
      '57': PlotInfo(id: '57', area: '100 Sq.Yds', fare: 0),
      '58': PlotInfo(id: '58', area: '100 Sq.Yds', fare: 0),
      '59': PlotInfo(id: '59', area: '100 Sq.Yds', fare: 0),
      '60': PlotInfo(id: '60', area: '100 Sq.Yds', fare: 0),
      '61': PlotInfo(id: '61', area: '100 Sq.Yds', fare: 0),
      '62': PlotInfo(id: '62', area: '100 Sq.Yds', fare: 0),
      '63': PlotInfo(id: '63', area: '100 Sq.Yds', fare: 0),
      '64': PlotInfo(id: '64', area: '100 Sq.Yds', fare: 0),
      '65': PlotInfo(id: '65', area: '100 Sq.Yds', fare: 0),
      '66': PlotInfo(id: '66', area: '100 Sq.Yds', fare: 0),
      '67': PlotInfo(id: '67', area: '100 Sq.Yds', fare: 0),
      '68': PlotInfo(id: '68', area: '178 Sq.Yds', fare: 0),

      // Middle left column
      '47': PlotInfo(id: '47', area: '150 Sq.Yds', fare: 0),
      '46': PlotInfo(id: '46', area: '150 Sq.Yds', fare: 0),
      '45': PlotInfo(id: '45', area: '150 Sq.Yds', fare: 0),
      '44': PlotInfo(id: '44', area: '150 Sq.Yds', fare: 0),
      '43': PlotInfo(id: '43', area: '150 Sq.Yds', fare: 0),
      '42': PlotInfo(id: '42', area: '200 Sq.Yds', fare: 0),
      '41': PlotInfo(id: '41', area: '200 Sq.Yds', fare: 0),
      '40': PlotInfo(id: '40', area: '152 Sq.Yds', fare: 0),
      '39': PlotInfo(id: '39', area: '152 Sq.Yds', fare: 0),
      '38': PlotInfo(id: '38', area: '152 Sq.Yds', fare: 0),
      '37': PlotInfo(id: '37', area: '152 Sq.Yds', fare: 0),
      '36': PlotInfo(id: '36', area: '152 Sq.Yds', fare: 0),
      '35': PlotInfo(id: '35', area: '200 Sq.Yds', fare: 0),

      // Middle right column
      '22': PlotInfo(id: '22', area: '150 Sq.Yds', fare: 0),
      '23': PlotInfo(id: '23', area: '150 Sq.Yds', fare: 0),
      '24': PlotInfo(id: '24', area: '150 Sq.Yds', fare: 0),
      '25': PlotInfo(id: '25', area: '150 Sq.Yds', fare: 0),
      '26': PlotInfo(id: '26', area: '150 Sq.Yds', fare: 0),
      '27': PlotInfo(id: '27', area: '200 Sq.Yds', fare: 0),
      '28': PlotInfo(id: '28', area: '200 Sq.Yds', fare: 0),
      '29': PlotInfo(id: '29', area: '152 Sq.Yds', fare: 0),
      '30': PlotInfo(id: '30', area: '152 Sq.Yds', fare: 0),
      '31': PlotInfo(id: '31', area: '152 Sq.Yds', fare: 0),
      '32': PlotInfo(id: '32', area: '152 Sq.Yds', fare: 0),
      '33': PlotInfo(id: '33', area: '152 Sq.Yds', fare: 0),
      '34': PlotInfo(id: '34', area: '200 Sq.Yds', fare: 0),

      // Right column
      '21': PlotInfo(id: '21', area: '100 Sq.Yds', fare: 0),
      '20': PlotInfo(id: '20', area: '100 Sq.Yds', fare: 0),
      '19': PlotInfo(id: '19', area: '100 Sq.Yds', fare: 0),
      '18': PlotInfo(id: '18', area: '100 Sq.Yds', fare: 0),
      '17': PlotInfo(id: '17', area: '100 Sq.Yds', fare: 0),
      '16': PlotInfo(id: '16', area: '100 Sq.Yds', fare: 0),
      '15': PlotInfo(id: '15', area: '100 Sq.Yds', fare: 0),
      '14': PlotInfo(id: '14', area: '100 Sq.Yds', fare: 0),
      '13': PlotInfo(id: '13', area: '100 Sq.Yds', fare: 0),
      '12': PlotInfo(id: '12', area: '100 Sq.Yds', fare: 0),
      '11': PlotInfo(id: '11', area: '100 Sq.Yds', fare: 0),
      '10': PlotInfo(id: '10', area: '100 Sq.Yds', fare: 0),
      '9': PlotInfo(id: '9', area: '100 Sq.Yds', fare: 0),
      '8': PlotInfo(id: '8', area: '100 Sq.Yds', fare: 0),
      '7': PlotInfo(id: '7', area: '100 Sq.Yds', fare: 0),
      '6': PlotInfo(id: '6', area: '100 Sq.Yds', fare: 0),
      '5': PlotInfo(id: '5', area: '100 Sq.Yds', fare: 0),
      '4': PlotInfo(id: '4', area: '100 Sq.Yds', fare: 0),
      '3': PlotInfo(id: '3', area: '100 Sq.Yds', fare: 0),
      '2': PlotInfo(id: '2', area: '100 Sq.Yds', fare: 0),
      '1': PlotInfo(id: '1', area: '178 Sq.Yds', fare: 0),
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

  Widget _buildPlot(String plotId, {double? width, double? height}) {
    final plot = plots[plotId]!;
    return GestureDetector(
      onTap: () => _showBookingDialog(plotId),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: plot.color,
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    plotId,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    plot.area,
                    style: const TextStyle(fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // "40'-0'" on the right side
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 2.0),
                child: Text(
                  "40'-0\"",
                  style: TextStyle(fontSize: 8, color: Colors.black),
                ),
              ),
            ),
            // "40'-0'" on the bottom side
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(
                  "40'-0\"",
                  style: TextStyle(fontSize: 8, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoad(String label, {bool isVertical = false, double? width, double? height}) {
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
                  fontSize: 9,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposed Land Layout'),
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
            onPressed: () {
              setState(() {
                _transformationController.value = Matrix4.identity();
              });
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      Column(
                        children: [
                          _buildPlot('48', width: 60, height: 50),
                          _buildPlot('49', width: 60, height: 50),
                          _buildPlot('50', width: 60, height: 50),
                          _buildPlot('51', width: 60, height: 50),
                          _buildPlot('52', width: 60, height: 50),
                          _buildPlot('53', width: 60, height: 50),
                          _buildPlot('54', width: 60, height: 50),
                          _buildPlot('55', width: 60, height: 50),
                          _buildPlot('56', width: 60, height: 50),
                          _buildPlot('57', width: 60, height: 50),
                          _buildPlot('58', width: 60, height: 50),
                          _buildPlot('59', width: 60, height: 50),
                          _buildPlot('60', width: 60, height: 50),
                          _buildPlot('61', width: 60, height: 50),
                          _buildPlot('62', width: 60, height: 50),
                          _buildPlot('63', width: 60, height: 50),
                          _buildPlot('64', width: 60, height: 50),
                          _buildPlot('65', width: 60, height: 50),
                          _buildPlot('66', width: 60, height: 50),
                          _buildPlot('67', width: 60, height: 50),
                          _buildPlot('68', width: 60, height: 65),
                        ],
                      ),

                      // First Vertical Road
                      _buildRoad('27.5\' WIDE ROAD', isVertical: true, width: 40, height: 1115),

                      // Middle Left Column
                      Column(
                        children: [
                          _buildPlot('47', width: 70, height: 55),
                          _buildPlot('46', width: 70, height: 55),
                          _buildPlot('45', width: 70, height: 55),
                          _buildPlot('44', width: 70, height: 55),
                          _buildPlot('43', width: 70, height: 55),
                          _buildPlot('42', width: 70, height: 75),
                          _buildRoad('20\' WIDE ROAD', width: 70, height: 30),
                          _buildPlot('41', width: 70, height: 75),
                          _buildPlot('40', width: 70, height: 58),
                          _buildPlot('39', width: 70, height: 58),
                          _buildPlot('38', width: 70, height: 58),
                          _buildPlot('37', width: 70, height: 58),
                          _buildPlot('36', width: 70, height: 58),
                          _buildPlot('35', width: 70, height: 75),
                        ],
                      ),

                      // Center Road
                      _buildRoad('27.5\' WIDE ROAD', isVertical: true, width: 40, height: 1115),

                      // Middle Right Column
                      Column(
                        children: [
                          _buildPlot('22', width: 70, height: 55),
                          _buildPlot('23', width: 70, height: 55),
                          _buildPlot('24', width: 70, height: 55),
                          _buildPlot('25', width: 70, height: 55),
                          _buildPlot('26', width: 70, height: 55),
                          _buildPlot('27', width: 70, height: 75),
                          _buildRoad('20\' WIDE ROAD', width: 70, height: 30),
                          _buildPlot('28', width: 70, height: 75),
                          _buildPlot('29', width: 70, height: 58),
                          _buildPlot('30', width: 70, height: 58),
                          _buildPlot('31', width: 70, height: 58),
                          _buildPlot('32', width: 70, height: 58),
                          _buildPlot('33', width: 70, height: 58),
                          _buildPlot('34', width: 70, height: 75),
                        ],
                      ),

                      // Right Road
                      _buildRoad('27.5\' WIDE ROAD', isVertical: true, width: 40, height: 1115),

                      // Right Column
                      Column(
                        children: [
                          _buildPlot('21', width: 60, height: 50),
                          _buildPlot('20', width: 60, height: 50),
                          _buildPlot('19', width: 60, height: 50),
                          _buildPlot('18', width: 60, height: 50),
                          _buildPlot('17', width: 60, height: 50),
                          _buildPlot('16', width: 60, height: 50),
                          _buildPlot('15', width: 60, height: 50),
                          _buildPlot('14', width: 60, height: 50),
                          _buildPlot('13', width: 60, height: 50),
                          _buildPlot('12', width: 60, height: 50),
                          _buildPlot('11', width: 60, height: 50),
                          _buildPlot('10', width: 60, height: 50),
                          _buildPlot('9', width: 60, height: 50),
                          _buildPlot('8', width: 60, height: 50),
                          _buildPlot('7', width: 60, height: 50),
                          _buildPlot('6', width: 60, height: 50),
                          _buildPlot('5', width: 60, height: 50),
                          _buildPlot('4', width: 60, height: 50),
                          _buildPlot('3', width: 60, height: 50),
                          _buildPlot('2', width: 60, height: 50),
                          _buildPlot('1', width: 60, height: 65),
                        ],
                      ),

                      const SizedBox(width: 20),

                      // Legend
                      Container(
                        padding: const EdgeInsets.all(12),
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
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildLegendItem('200 Sq.Yrd', Colors.white),
                            _buildLegendItem('178 Sq.Yrd', const Color(0xFFE6D5E6)),
                            _buildLegendItem('152 Sq.Yrd', Colors.white),
                            _buildLegendItem('150 Sq.Yrd', const Color(0xFFE8E8D5)),
                            _buildLegendItem('100 Sq.Yrd', const Color(0xFFD5E8E8)),
                            _buildLegendItem('86 Sq.Yrd', Colors.white),
                            const SizedBox(height: 16),
                            const Text(
                              'AREA DETAILS:-',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildAreaDetail('Land Area', '11671.07', 'Sq. Yds'),
                            _buildAreaDetail('', '9758.50', 'Sq. Mtr.'),
                            _buildAreaDetail('', '11.57', 'Bigha'),
                            const SizedBox(height: 12),
                            _buildAreaDetail('Plot Area', '8531.03', 'Sq. Yds.'),
                            _buildAreaDetail('', '7133.03', 'Sq.Mts.'),
                            _buildAreaDetail('', '8.46', 'Bigha'),
                            const SizedBox(height: 12),
                            _buildAreaDetail('Road Area', '3140.04', 'Sq.Yds.'),
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

          // Legend in corner
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
                  _buildStatusItem(Colors.yellow.shade300, '50% Paid'),
                  _buildStatusItem(Colors.red.shade300, 'Below 50%'),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
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
              width: 70,
              child: Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          else
            const SizedBox(width: 70),
          Container(
            width: 60,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 55,
            child: Text(
              unit,
              style: const TextStyle(fontSize: 10),
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
                    labelText: 'Name',
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
