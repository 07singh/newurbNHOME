import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '/HRdashboad/PaymentHistoryScreen.dart';

enum BookingStatus { pending, booked, sellout }

class Plot {
  final int id;
  final String projectName;
  final String plotNumber;
  final String bookingArea;
  final String remainingArea;
  final String totalArea;
  final String purchasePrice;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final String paidThrough;
  final String screenshot; // ← Yeh important hai
  final String dealerName;
  final String dealerPhone;
  final String customerName;
  final String customerPhone;
  final String plotType;
  final String bookingStatus;

  Plot({
    required this.id,
    required this.projectName,
    required this.plotNumber,
    required this.bookingArea,
    required this.remainingArea,
    required this.totalArea,
    required this.purchasePrice,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.paidThrough,
    required this.screenshot,
    required this.dealerName,
    required this.dealerPhone,
    required this.customerName,
    required this.customerPhone,
    required this.plotType,
    required this.bookingStatus,
  });

  factory Plot.fromJson(Map<String, dynamic> json) {
    final bs = (json['BookingStatus'] ??
        json['Booking_Status'] ??
        json['booking_status'] ??
        '')
        .toString()
        .toLowerCase();

    return Plot(
      id: json['id'] ?? 0,
      projectName: json['Project_Name'] ?? '',
      plotNumber: json['Plot_Number'] ?? '',
      bookingArea: json['Booking_Area'] ?? '',
      remainingArea: json['Remaining_Area'] ?? '',
      totalArea: json['Total_Area'] ?? '',
      purchasePrice: json['Purchase_price']?.toString() ?? '',
      totalAmount: double.tryParse(json['Total_Amount']?.toString() ?? '0') ?? 0,
      paidAmount: double.tryParse(json['Receiving_Amount']?.toString() ?? '0') ?? 0,
      pendingAmount: double.tryParse(json['Pending_Amount']?.toString() ?? '0') ?? 0,
      paidThrough: json['Paid_Through'] ?? '',
      screenshot: json['Screenshot'] ?? '', // ← Yeh field
      dealerName: json['Booked_ByDealer'] ?? '',
      dealerPhone: json['Dealer_Phn_Number']?.toString() ?? '',
      customerName: json['Customer_Name'] ?? '',
      customerPhone: json['Customer_Phn_Number']?.toString() ?? '',
      plotType: json['Plot_Type'] ?? '',
      bookingStatus: bs,
    );
  }
}

class PendingRequestsHrScreen extends StatefulWidget {
  final String userRole;
  const PendingRequestsHrScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  State<PendingRequestsHrScreen> createState() => _PendingRequestsHrScreenState();
}

class _PendingRequestsHrScreenState extends State<PendingRequestsHrScreen> {
  BookingStatus selectedStatus = BookingStatus.pending;
  List<Plot> plots = [];
  bool isLoading = false;
  final Set<int> _approvingIds = {};

  final String pendingUrl = "https://realapp.cheenu.in/Api/PendingBooking/";
  final String bookedUrl = "https://realapp.cheenu.in/Api/BookedPlot/";
  final String selloutUrl = "https://realapp.cheenu.in/Api/SelloutPlot/";
  final String acceptUrl = "https://realapp.cheenu.in/api/acceptbooking/add";
  final String rejectUrl = "https://realapp.cheenu.in/api/rejectbookingrequest/reject";

  @override
  void initState() {
    super.initState();
    _fetchPlots();
  }

  Future<void> _fetchPlots() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    String url;
    switch (selectedStatus) {
      case BookingStatus.booked:
        url = bookedUrl;
        break;
      case BookingStatus.sellout:
        url = selloutUrl;
        break;
      default:
        url = pendingUrl;
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List dataList = jsonData["data1"] ?? jsonData["data"] ?? [];

        final fetchedPlots = dataList
            .map((e) => Plot.fromJson(e as Map<String, dynamic>))
            .toList();

        // Remove duplicates
        final uniquePlots = <Plot>[];
        final seenKeys = <String>{};
        for (var plot in fetchedPlots) {
          final key = "${plot.projectName}_${plot.plotNumber}_${plot.customerName}".toLowerCase();
          if (!seenKeys.contains(key)) {
            seenKeys.add(key);
            uniquePlots.add(plot);
          }
        }

        setState(() => plots = uniquePlots);
      } else {
        _showSnackBar("Failed to load plots", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Network error: $e", Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  bool _hasScreenshot(Plot plot) {
    final data = plot.screenshot.trim().toLowerCase();
    return data.isNotEmpty && data != 'null';
  }

  void _showScreenshot(String imageData) {
    final Widget? imageWidget =
    _buildImageWidget(imageData, fit: BoxFit.contain);

    if (imageWidget == null) {
      _showSnackBar("No screenshot available", Colors.orange);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text("Payment Screenshot"),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: imageWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildImageWidget(String imageData, {BoxFit fit = BoxFit.cover}) {
    final normalizedUrl = _normalizeScreenshotUrl(imageData);
    if (normalizedUrl != null) {
      return Image.network(
        normalizedUrl,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: Colors.red),
        ),
      );
    }

    final bytes = _decodeBase64Image(imageData);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: Colors.red),
        ),
      );
    }

    return null;
  }

  String? _normalizeScreenshotUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
      return null;
    }
    if (trimmed.startsWith('http')) return trimmed;
    if (trimmed.contains('base64')) return null;

    if (trimmed.startsWith('/')) {
      return "https://realapp.cheenu.in$trimmed";
    }
    return "https://realapp.cheenu.in/$trimmed";
  }

  Uint8List? _decodeBase64Image(String raw) {
    final cleaned = raw.contains(',')
        ? raw.split(',').last.trim()
        : raw.trim();

    if (cleaned.length < 100) return null;

    try {
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  Future<void> _approvePlot(Plot plot) async {
    if (widget.userRole != "Director" && widget.userRole != "HR") {
      _showSnackBar("Only Director or HR can approve", Colors.orange);
      return;
    }

    if (_approvingIds.contains(plot.id)) return;
    _approvingIds.add(plot.id);

    try {
      final payload = {
        "id": plot.id,
        "Project_Name": plot.projectName,
        "Plot_Number": plot.plotNumber,
        "Booking_Area": plot.bookingArea,
        "Remaining_Area": plot.remainingArea,
        "Total_Area": plot.totalArea,
        "Purchase_price": plot.purchasePrice,
        "Total_Amount": plot.totalAmount,
        "Receiving_Amount": plot.paidAmount,
        "PendingAmount": plot.pendingAmount.toString(),
        "Paid_Through": plot.paidThrough,
        "Screenshot": plot.screenshot,
        "Booked_ByDealer": plot.dealerName,
        "Dealer_Phn_Number": plot.dealerPhone,
        "Customer_Name": plot.customerName,
        "Customer_Phn_Number": plot.customerPhone,
        "Plot_Type": plot.plotType,
        "BookingStatus": "approved",
      };

      final response = await http.post(
        Uri.parse(acceptUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        setState(() {
          plots.remove(plot); // ← Instant remove
        });
        _showSnackBar("Booking Approved Successfully", Colors.green);
      } else {
        final msg = jsonDecode(response.body)["message"] ?? "Approval failed";
        _showSnackBar(msg, Colors.red);
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    } finally {
      _approvingIds.remove(plot.id);
    }
  }

  Future<void> _rejectPlot(Plot plot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Booking"),
        content: Text("Reject ${plot.plotNumber} for ${plot.customerName}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Reject", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse(rejectUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Plot_Number": plot.plotNumber,
          "Customer_Name": plot.customerName,
          "BookingStatus": "rejected",
        }),
      );

      if (response.statusCode == 200) {
        setState(() => plots.remove(plot));
        _showSnackBar("Booking Rejected", Colors.red);
      } else {
        _showSnackBar("Reject failed", Colors.orange);
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // Call Dealer
  Future<void> _callDealer(String? phone) async {
    if (phone == null || phone.isEmpty) {
      _showSnackBar("Dealer phone number not available", Colors.orange);
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar("Cannot make phone call", Colors.red);
    }
  }

  // Show Add Payment Modal
  void _showAddPaymentModal(Plot plot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddPaymentModal(plot: plot, onSuccess: _fetchPlots),
    );
  }

  // Show Payment History
  void _showPaymentHistory(Plot plot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentHistoryScreen(),
      ),
    );
  }

  // Build Action Icon Widget
  Widget _buildActionIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final effectiveColor = enabled ? color : Colors.grey;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.1) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (enabled ? color : Colors.grey).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: effectiveColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plot Status", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: const Color(0xFF3371F4),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildTabs(),
          const Divider(thickness: 1),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : plots.isEmpty
                ? Center(child: Text(selectedStatus == BookingStatus.pending ? "No pending requests" : "No ${selectedStatus.name} plots"))
                : RefreshIndicator(
              onRefresh: _fetchPlots,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: plots.length,
                itemBuilder: (context, index) {
                  final plot = plots[index];
                  final isApproving = _approvingIds.contains(plot.id);

                  return Card(
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.blue.shade700,
                              child: Text(plot.plotNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(plot.projectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Plot: ${plot.plotNumber} | Customer: ${plot.customerName}"),
                                Text("Dealer: ${plot.dealerName} • ${plot.dealerPhone}"),
                                Text("Paid: ₹${plot.paidAmount.toStringAsFixed(0)} / ₹${plot.totalAmount.toStringAsFixed(0)}",
                                    style: TextStyle(color: plot.paidAmount >= plot.totalAmount * 0.5 ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),

                          // Action Icons Row: Call, Add Payment, Payment History
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final availableWidth = constraints.maxWidth;
                                final needWrap = availableWidth < 360;
                                final children = [
                                  _buildActionIcon(
                                    icon: Icons.phone,
                                    label: "Call Dealer",
                                    color: Colors.green,
                                    onTap: () => _callDealer(plot.dealerPhone),
                                  ),
                                  _buildActionIcon(
                                    icon: Icons.payment,
                                    label: "Add Payment",
                                    color: Colors.blue,
                                    onTap: () => _showAddPaymentModal(plot),
                                  ),
                                  _buildActionIcon(
                                    icon: Icons.history,
                                    label: "Payment History",
                                    color: Colors.orange,
                                    onTap: () => _showPaymentHistory(plot),
                                  ),
                                ];

                                if (needWrap) {
                                  return Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    alignment: WrapAlignment.spaceEvenly,
                                    children: children,
                                  );
                                }

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: children,
                                );
                              },
                            ),
                          ),

                          // Accept/Reject Buttons
                          if (selectedStatus == BookingStatus.pending)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: isApproving ? null : () => _approvePlot(plot),
                                    icon: isApproving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
                                    label: Text(isApproving ? "Processing..." : "Accept"),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _rejectPlot(plot),
                                    icon: const Icon(Icons.close),
                                    label: const Text("Reject"),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  ),
                                ],
                              ),
                            )
                          else
                            Chip(
                              label: Text(plot.bookingStatus.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              backgroundColor: selectedStatus == BookingStatus.booked ? Colors.blue : Colors.green,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _tabButton("Pending", BookingStatus.pending, const Color(0xFFFFD700)),
        _tabButton("Booked", BookingStatus.booked, Colors.blue),
        _tabButton("Sellout", BookingStatus.sellout, Colors.green),
      ],
    );
  }

  Widget _tabButton(String text, BookingStatus status, Color color) {
    final isSelected = selectedStatus == status;
    return GestureDetector(
      onTap: isLoading ? null : () {
        if (selectedStatus != status) {
          setState(() => selectedStatus = status);
          _fetchPlots();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(text, style: TextStyle(color: isSelected ? Colors.white : color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ====================== ADD PAYMENT MODAL ======================
class _AddPaymentModal extends StatefulWidget {
  final Plot plot;
  final VoidCallback onSuccess;
  const _AddPaymentModal({required this.plot, required this.onSuccess});

  @override
  State<_AddPaymentModal> createState() => _AddPaymentModalState();
}

class _AddPaymentModalState extends State<_AddPaymentModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  String? _selectedPaymentMethod;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'UPI Payment', 'icon': Icons.qr_code, 'color': Colors.purple},
    {'name': 'NEFT', 'icon': Icons.account_balance, 'color': Colors.blue},
    {'name': 'RTGS', 'icon': Icons.money, 'color': Colors.green},
    {'name': 'Cheque', 'icon': Icons.description, 'color': Colors.orange},
    {'name': 'Cash', 'icon': Icons.attach_money, 'color': Colors.green},
  ];

  Future<void> _pickImage() async {
    try {
      final XFile? img = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (img != null) {
        setState(() => _selectedImage = File(img.path));
      }
    } catch (e) {
      _showError('Image selection failed: $e');
    }
  }

  Future<void> _submitPayment() async {
    if (_amountController.text.isEmpty) {
      _showError('Please enter amount');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter valid amount');
      return;
    }

    if (_selectedPaymentMethod == null) {
      _showError('Please select payment method');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? screenshotBase64;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        screenshotBase64 = base64Encode(bytes);
      }

      final url = "https://realapp.cheenu.in/Api/AddPayment/Add";
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Booking_Id": widget.plot.id,
          "Paid_Amount": amount,
          "Paid_Through": _selectedPaymentMethod,
          "Screenshot": screenshotBase64 ?? "",
          "Payment_Date": DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError('Failed to add payment');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Add Payment",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.grey.shade800),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            "For ${widget.plot.customerName} - ${widget.plot.plotNumber}",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Enter Amount (₹)",
              prefixIcon: const Icon(Icons.currency_rupee),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Text("Payment Method", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method['name'];
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(method['icon'], size: 18, color: isSelected ? Colors.white : method['color']),
                    const SizedBox(width: 4),
                    Text(method['name']),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedPaymentMethod = selected ? method['name'] : null);
                },
                selectedColor: method['color'],
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (_selectedPaymentMethod != null && _selectedPaymentMethod != 'Cash')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Payment Screenshot", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade400),
                        Text("Tap to add screenshot", style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text("Submit Payment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }
}