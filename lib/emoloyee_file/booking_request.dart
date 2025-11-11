import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  final String screenshot;
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
      paidAmount:
      double.tryParse(json['Receiving_Amount']?.toString() ?? '0') ?? 0,
      pendingAmount:
      double.tryParse(json['Pending_Amount']?.toString() ?? '0') ?? 0,
      paidThrough: json['Paid_Through'] ?? '',
      screenshot: json['Screenshot'] ?? '',
      dealerName: json['Booked_ByDealer'] ?? '',
      dealerPhone: json['Dealer_Phn_Number']?.toString() ?? '',
      customerName: json['Customer_Name'] ?? '',
      customerPhone: json['Customer_Phn_Number']?.toString() ?? '',
      plotType: json['Plot_Type'] ?? '',
      bookingStatus: bs,
    );
  }
}

class PendingRequestsScreen extends StatefulWidget {
  final String userRole;
  const PendingRequestsScreen({Key? key, required this.userRole})
      : super(key: key);

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  BookingStatus selectedStatus = BookingStatus.pending;
  List<Plot> plots = [];
  bool isLoading = false;
  final Set<int> _approvingIds = {};

  final String pendingUrl = "https://realapp.cheenu.in/Api/PendingBooking/";
  final String bookedUrl = "https://realapp.cheenu.in/Api/BookedPlot/";
  final String selloutUrl = "https://realapp.cheenu.in/Api/SelloutPlot/";
  final String acceptUrl = "https://realapp.cheenu.in/api/acceptbooking/add";
  final String rejectUrl =
      "https://realapp.cheenu.in/api/rejectbookingrequest/reject";

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

        final fetchedPlots =
        dataList.map((e) => Plot.fromJson(e as Map<String, dynamic>)).toList();

        // Remove duplicates
        final uniquePlots = <Plot>[];
        final seenKeys = <String>{};
        for (var plot in fetchedPlots) {
          final key =
          "${plot.projectName}${plot.plotNumber}${plot.customerName}"
              .toLowerCase();
          if (!seenKeys.contains(key)) {
            seenKeys.add(key);
            uniquePlots.add(plot);
          }
        }

        setState(() => plots = uniquePlots);
      } else {
        _showSnackBar("Failed to load plots (${response.statusCode})", Colors.red);
      }
    } catch (e) {
      debugPrint("Error fetching plots: $e");
      _showSnackBar("Network error occurred", Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _approvePlot(Plot plot) async {
    if (widget.userRole != "Director" && widget.userRole != "HR") {
      _showSnackBar("⚠ Only Director or HR can approve plots.", Colors.orange);
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
        final resp = jsonDecode(response.body);
        final msg = resp["message"] ?? "Booking approved successfully";

        // ✅ Remove immediately from local pending list
        setState(() {
          plots.removeWhere((p) =>
          p.projectName == plot.projectName &&
              p.plotNumber == plot.plotNumber &&
              p.customerName == plot.customerName);
        });

        _showSnackBar("✅ $msg", Colors.green);
      } else {
        final resp = jsonDecode(response.body);
        final msg = resp["message"] ?? "Failed to approve booking";
        _showSnackBar("❌ $msg", Colors.red);
      }
    } catch (e) {
      _showSnackBar("⚠ Error: $e", Colors.red);
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
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Reject",
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final payload = {
        "Plot_Number": plot.plotNumber,
        "Customer_Name": plot.customerName,
        "BookingStatus": "rejected",
      };

      final response = await http.post(
        Uri.parse(rejectUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        _showSnackBar("❌ Booking rejected successfully", Colors.red);
        setState(() => plots.remove(plot));
      } else {
        _showSnackBar("Reject failed (${response.statusCode})", Colors.orange);
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Plot Status",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFD700),
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
                ? Center(
              child: Text(
                selectedStatus == BookingStatus.pending
                    ? "No pending requests"
                    : "No ${selectedStatus.name} plots",
                style: const TextStyle(
                    fontSize: 16, color: Colors.grey),
              ),
            )
                : RefreshIndicator(
              onRefresh: _fetchPlots,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: plots.length,
                itemBuilder: (context, index) {
                  final plot = plots[index];
                  final isApproving =
                  _approvingIds.contains(plot.id);

                  return Card(
                    margin:
                    const EdgeInsets.symmetric(vertical: 6),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade700,
                        radius: 26,
                        child: Text(
                          plot.plotNumber.isNotEmpty
                              ? plot.plotNumber
                              : "?",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      title: Text(plot.projectName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text("Plot: ${plot.plotNumber}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500)),
                          Text("Customer: ${plot.customerName}"),
                          Text("Dealer: ${plot.dealerName}"),
                          Text(
                            "Paid: ₹${plot.paidAmount.toStringAsFixed(0)} / ₹${plot.totalAmount.toStringAsFixed(0)}",
                            style: TextStyle(
                              color: plot.paidAmount >=
                                  plot.totalAmount * 0.5
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      trailing:
                      selectedStatus == BookingStatus.pending
                          ? Row(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: isApproving
                                ? null
                                : () =>
                                _approvePlot(plot),
                            style: ElevatedButton
                                .styleFrom(
                              backgroundColor:
                              Colors.green,
                              padding: const EdgeInsets
                                  .symmetric(
                                  horizontal: 12),
                              minimumSize:
                              const Size(70, 36),
                            ),
                            child: isApproving
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                Colors.white,
                              ),
                            )
                                : const Text(
                              "Accept",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors
                                      .white),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: () =>
                                _rejectPlot(plot),
                            style: ElevatedButton
                                .styleFrom(
                              backgroundColor:
                              Colors.red,
                              padding: const EdgeInsets
                                  .symmetric(
                                  horizontal: 12),
                              minimumSize:
                              const Size(70, 36),
                            ),
                            child: const Text(
                              "Reject",
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                  Colors.white),
                            ),
                          ),
                        ],
                      )
                          : Chip(
                        label: Text(
                          plot.bookingStatus
                              .isNotEmpty
                              ? plot.bookingStatus
                              .toUpperCase()
                              : (selectedStatus ==
                              BookingStatus
                                  .booked
                              ? "BOOKED"
                              : "SELLOUT"),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight:
                              FontWeight.bold),
                        ),
                        backgroundColor:
                        selectedStatus ==
                            BookingStatus.booked
                            ? Colors.blue
                            : Colors.green,
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
        _tabButton("Pending", BookingStatus.pending,
            const Color(0xFFFFD700)),
        _tabButton("Booked", BookingStatus.booked, Colors.blue),
        _tabButton("Sellout", BookingStatus.sellout, Colors.green),
      ],
    );
  }

  Widget _tabButton(String text, BookingStatus status, Color color) {
    final isSelected = selectedStatus == status;
    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
        if (selectedStatus != status) {
          setState(() => selectedStatus = status);
          _fetchPlots();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}