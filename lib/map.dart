import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Property {
  final int id;
  final String plotNo;
  final String size;
  String status; // available | booked
  String? ownerName;
  String? ownerPhone;
  String? ownerEmail;

  Property({
    required this.id,
    required this.plotNo,
    required this.size,
    required this.status,
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
  });

  factory Property.fromMap(Map<String, dynamic> map) => Property(
        id: map['id'] as int,
        plotNo: map['plotNo'] as String,
        size: map['size'] as String,
        status: map['status'] as String,
        ownerName: map['ownerName'] as String?,
        ownerPhone: map['ownerPhone'] as String?,
        ownerEmail: map['ownerEmail'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'plotNo': plotNo,
        'size': size,
        'status': status,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,
        'ownerEmail': ownerEmail,
      };
}

class PropertyMapPage extends StatefulWidget {
  const PropertyMapPage({super.key});

  @override
  State<PropertyMapPage> createState() => _PropertyMapPageState();
}

class _PropertyMapPageState extends State<PropertyMapPage> {
  static const String storageKey = 'property_plots_v1';
  late Future<List<Property>> _futureProperties;

  @override
  void initState() {
    super.initState();
    _futureProperties = _loadOrSeed();
  }

  Future<List<Property>> _loadOrSeed() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(storageKey);
    if (jsonString != null) {
      final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
      return list.map((e) => Property.fromMap(e as Map<String, dynamic>)).toList();
    }

    // Seed with 49 plots per requirement
    final List<Property> seed = List.generate(49, (index) {
      final plotNo = (index + 1).toString();
      return Property(
        id: index + 1,
        plotNo: plotNo,
        size: '100 Sq.Yds',
        status: 'available',
      );
    });
    await _save(seed);
    return seed;
  }

  Future<void> _save(List<Property> properties) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(properties.map((e) => e.toMap()).toList());
    await prefs.setString(storageKey, jsonString);
  }

  Future<void> _bookProperty(Property property) async {
    final properties = await _futureProperties;
    property.status = 'booked';
    await _save(properties);
    setState(() {
      _futureProperties = Future.value(properties);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Map'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          _buildLegend(),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Property>>(
              future: _futureProperties,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final properties = snapshot.data!;
                return _SitePlan(properties: properties, onTapProperty: (p) => _onTapProperty(context, p));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: const [
          _LegendDot(color: Colors.red, label: 'Booked'),
          SizedBox(width: 16),
          _LegendDot(color: Colors.green, label: 'Available'),
        ],
      ),
    );
  }

  Future<void> _onTapProperty(BuildContext context, Property property) async {
    if (property.status == 'booked') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Already booked'),
          content: Text('Plot ${property.plotNo} is already booked.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Book Plot'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  controller: nameCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  controller: phoneCtrl,
                  validator: (v) => (v == null || v.trim().length < 8) ? 'Enter valid phone' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  controller: emailCtrl,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                ),
                const SizedBox(height: 8),
                Text('Plot Number: ${property.plotNo}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                property.ownerName = nameCtrl.text.trim();
                property.ownerPhone = phoneCtrl.text.trim();
                property.ownerEmail = emailCtrl.text.trim();
                Navigator.pop(context, true);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _bookProperty(property);
    }
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _SitePlan extends StatelessWidget {
  final List<Property> properties;
  final void Function(Property) onTapProperty;
  const _SitePlan({super.key, required this.properties, required this.onTapProperty});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3,
              boundaryMargin: const EdgeInsets.all(64),
              child: Center(
                child: Container(
                  width: 1100,
                  height: 1000,
                  color: Colors.white,
                  child: Stack(
                    children: [
              // Outer site area with border
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black87, width: 2),
                  ),
                ),
              ),
              // Top overall width label
              Positioned(
                top: 20,
                left: 220,
                right: 220,
                child: Center(
                  child: Text("207'-4\"", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                ),
              ),
              // Right overall height label
              Positioned(
                right: 16,
                top: 260,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text("488'-3\"", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                ),
              ),
              // Left outer 25' road (vertical)
              Positioned(
                left: 20,
                top: 40,
                bottom: 80,
                width: 80,
                child: _OuterRoad(label: "25' WIDE ROAD", vertical: true),
              ),
              // Bottom outer 25' road (horizontal)
              Positioned(
                left: 120,
                right: 40,
                bottom: 40,
                height: 80,
                child: _OuterRoad(label: "25' WIDE ROAD", vertical: false, showEntryArrows: true),
              ),
              // Top-left short 25' road (horizontal)
              Positioned(
                left: 120,
                right: 420,
                top: 80,
                height: 60,
                child: _OuterRoad(label: "25' WIDE ROAD", vertical: false),
              ),

              // Inner plot canvas in center to match approx dimensions and offsets
              Positioned(
                left: 120,
                right: 120,
                top: 140,
                bottom: 60,
                child: _MapCanvas(properties: properties, onTapProperty: onTapProperty),
              ),

              // SOLD LAND label on the left side
              Positioned(
                left: 130,
                top: 360,
                width: 100,
                height: 220,
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    'SOLD\nLAND',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 2,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OuterRoad extends StatelessWidget {
  final String label;
  final bool vertical;
  final bool showEntryArrows;
  const _OuterRoad({required this.label, required this.vertical, this.showEntryArrows = false});

  @override
  Widget build(BuildContext context) {
    final road = Container(
      decoration: BoxDecoration(color: const Color(0xFF2E2E2E), borderRadius: BorderRadius.circular(8)),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _DashedCenterLinePainter(isVertical: vertical))),
        Center(
          child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600)),
        )
      ]),
    );
    if (!showEntryArrows) return road;
    return Stack(
      children: [
        Positioned.fill(child: road),
        // two entry markers near left and right ends
        Align(
          alignment: Alignment(-0.7, 1),
          child: _EntryMarker(),
        ),
        Align(
          alignment: Alignment(0.7, 1),
          child: _EntryMarker(),
        ),
      ],
    );
  }
}

class _EntryMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.arrow_upward, color: Colors.white),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
          child: const Text('ENTRY', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _MapCanvas extends StatelessWidget {
  final List<Property> properties;
  final void Function(Property) onTapProperty;
  const _MapCanvas({required this.properties, required this.onTapProperty});

  @override
  Widget build(BuildContext context) {
    // Use InteractiveViewer for pinch-zoom and pan, with scrollable sized child
    return InteractiveViewer(
      minScale: 0.6,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(64),
      child: Center(
        child: Container(
          width: 900,
          height: 1200,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade400, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildGrid(context),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    // Grid with embedded roads similar to the provided layout image.
    // We use 11 columns where columns 3 and 7 are vertical roads.
    // We use 12 rows where rows 5 and 11 are horizontal roads (middle + bottom).
    const int columns = 11;
    const int rows = 12;
    const Set<int> verticalRoadCols = {3, 7};
    const Set<int> horizontalRoadRows = {5, 11};

    // Prepare plot widgets iterator
    int plotIndex = 0;

    Widget buildCell(int row, int col) {
      final bool isVerticalRoad = verticalRoadCols.contains(col);
      final bool isHorizontalRoad = horizontalRoadRows.contains(row);

      if (isVerticalRoad && isHorizontalRoad) {
        // intersection - render as road block
        return const _RoadTile(isVertical: true, isIntersection: true);
      } else if (isVerticalRoad) {
        return const _RoadTile(isVertical: true);
      } else if (isHorizontalRoad) {
        return const _RoadTile(isVertical: false);
      }

      if (plotIndex < properties.length) {
        final p = properties[plotIndex++];
        final style = _styleFor(row, col);
        return _PlotTile(property: p, onTap: () => onTapProperty(p), style: style);
      }
      // Empty area if we run out of plots
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: rows * columns,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, idx) {
        final row = idx ~/ columns;
        final col = idx % columns;
        return buildCell(row, col);
      },
    );
  }

  _PlotStyle _styleFor(int row, int col) {
    // Peripheral blue along outermost columns
    if (col == 0 || col == 1 || col == 9 || col == 10) {
      return _PlotStyle(
        border: Colors.blue,
        fill: Colors.blue.withOpacity(0.10),
        sizeLabel: '100 Sq.Yds',
        dims: "19'-9\" x 45'",
      );
    }
    // Purple corner plots at bottom near entries
    if (row == 10 && (col == 0 || col == 10)) {
      return _PlotStyle(
        border: Colors.purple,
        fill: Colors.purple.withOpacity(0.12),
        sizeLabel: '178 Sq.Yds',
        dims: "40' x 40'",
      );
    }
    // Central yellow around middle road rows
    if ((row == 4 || row == 6) && (col >= 4 && col <= 6)) {
      return _PlotStyle(
        border: Colors.amber.shade700,
        fill: Colors.amber.shade300.withOpacity(0.30),
        sizeLabel: '200 Sq.Yds',
        dims: "40' x 45'",
      );
    }
    // Mid-section grey/white between vertical roads
    if (col >= 4 && col <= 6) {
      return _PlotStyle(
        border: Colors.grey.shade600,
        fill: Colors.grey.shade200,
        sizeLabel: '150-160 Sq.Yds',
        dims: "30'–38' x 35'–45'",
      );
    }
    // Default small plots
    return _PlotStyle(
      border: Colors.blue,
      fill: Colors.blue.withOpacity(0.10),
      sizeLabel: '100 Sq.Yds',
      dims: "19'-9\" x 45'",
    );
  }
}

class _PlotTile extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final _PlotStyle style;
  const _PlotTile({required this.property, required this.onTap, required this.style});

  @override
  Widget build(BuildContext context) {
    final isBooked = property.status == 'booked';
    final Color color = isBooked ? Colors.red : style.border;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isBooked ? Colors.red.withOpacity(0.12) : style.fill,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Plot ${property.plotNo}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(style.sizeLabel, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              const SizedBox(height: 2),
              Text(style.dims, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlotStyle {
  final Color border;
  final Color fill;
  final String sizeLabel;
  final String dims;
  _PlotStyle({required this.border, required this.fill, required this.sizeLabel, required this.dims});
}

class _RoadTile extends StatelessWidget {
  final bool isVertical;
  final bool isIntersection;
  const _RoadTile({required this.isVertical, this.isIntersection = false});

  @override
  Widget build(BuildContext context) {
    final Color asphalt = const Color(0xFF2E2E2E);
    return Container(
      decoration: BoxDecoration(
        color: asphalt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // dashed center line via CustomPaint to avoid layout overflow
          Positioned.fill(
            child: CustomPaint(
              painter: _DashedCenterLinePainter(isVertical: isVertical),
            ),
          ),
          if (!isIntersection)
            Align(
              alignment: isVertical ? Alignment.topCenter : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  isVertical ? '27.5\' WIDE ROAD' : '20\' WIDE ROAD',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedCenterLinePainter extends CustomPainter {
  final bool isVertical;
  _DashedCenterLinePainter({required this.isVertical});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double dash = 8;
    const double gap = 6;

    if (isVertical) {
      double y = 4;
      final double x = size.width / 2;
      while (y < size.height - 4) {
        final double y2 = (y + dash).clamp(0, size.height);
        canvas.drawLine(Offset(x, y), Offset(x, y2), paint);
        y += dash + gap;
      }
    } else {
      double x = 4;
      final double y = size.height / 2;
      while (x < size.width - 4) {
        final double x2 = (x + dash).clamp(0, size.width);
        canvas.drawLine(Offset(x, y), Offset(x2, y), paint);
        x += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCenterLinePainter oldDelegate) {
    return oldDelegate.isVertical != isVertical;
  }
}

class PlotGridPage extends StatefulWidget {
  const PlotGridPage({super.key});



  @override
  State<PlotGridPage> createState() => _DefenceEnclavePageState();
}

class _DefenceEnclavePageState extends State<PlotGridPage> {
  // Example data from your PDF
  final List<Map<String, dynamic>> plots = [
    {"id": 1, "size": "178 Sq.Yds"},
    {"id": 2, "size": "100 Sq.Yds"},
    {"id": 3, "size": "100 Sq.Yds"},
    {"id": 4, "size": "100 Sq.Yds"},
    {"id": 5, "size": "100 Sq.Yds"},
    {"id": 6, "size": "100 Sq.Yds"},
    {"id": 7, "size": "100 Sq.Yds"},
    {"id": 8, "size": "100 Sq.Yds"},
    {"id": 9, "size": "100 Sq.Yds"},
    {"id": 10, "size": "100 Sq.Yds"},
    {"id": 27, "size": "200 Sq.Yds"},
    {"id": 28, "size": "200 Sq.Yds"},
    {"id": 29, "size": "152 Sq.Yds"},
    {"id": 30, "size": "152 Sq.Yds"},
    {"id": 35, "size": "200 Sq.Yds"},
    {"id": 36, "size": "152 Sq.Yds"},
    {"id": 41, "size": "200 Sq.Yds"},
    {"id": 42, "size": "200 Sq.Yds"},
    {"id": 43, "size": "150 Sq.Yds"},
    {"id": 44, "size": "150 Sq.Yds"},
    {"id": 45, "size": "150 Sq.Yds"},
    {"id": 46, "size": "150 Sq.Yds"},
    {"id": 47, "size": "150 Sq.Yds"},
    {"id": 48, "size": "85 Sq.Yds"},
    {"id": 49, "size": "100 Sq.Yds"},
    {"id": 50, "size": "100 Sq.Yds"},
    {"id": 68, "size": "178 Sq.Yds"},
  ];

  // Track selection states
  late List<bool> selected;

  @override
  void initState() {
    super.initState();
    selected = List.generate(plots.length, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Defence Enclave Layout"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // number of columns (adjust to match map)
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1, // adjust for rectangular plots
          ),
          itemCount: plots.length,
          itemBuilder: (context, index) {
            final plot = plots[index];
            final isSelected = selected[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  selected[index] = !isSelected;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green : Colors.grey[200],
                  border: Border.all(color: Colors.black54),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Plot ${plot["id"]}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black)),
                    Text("${plot["size"]}",
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.black)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}