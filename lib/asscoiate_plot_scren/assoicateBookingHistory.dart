import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _MyBookingHistoryPageState();
}

class _MyBookingHistoryPageState extends State<PaymentHistoryScreen> {
  final List<BookingRecord> _allBookings = [
    BookingRecord(
      id: '1',
      projectName: 'Green Valley Residency',
      plotNumber: 'A-102',
      bookingDate: DateTime.now().subtract(const Duration(days: 1)),
      amount: 1200000,
      status: 'Confirmed',
      pdfUrl: "https://www.example.com/dummy.pdf",
    ),
    BookingRecord(
      id: '2',
      projectName: 'Sunshine Enclave',
      plotNumber: 'B-205',
      bookingDate: DateTime.now().subtract(const Duration(days: 5)),
      amount: 950000,
      status: 'Pending',
      pdfUrl: "https://www.example.com/dummy.pdf",
    ),
    BookingRecord(
      id: '3',
      projectName: 'Elite City Phase 2',
      plotNumber: 'C-310',
      bookingDate: DateTime.now().subtract(const Duration(days: 10)),
      amount: 1500000,
      status: 'Cancelled',
      pdfUrl: "https://www.example.com/dummy.pdf",
    ),
    BookingRecord(
      id: '4',
      projectName: 'Silver Homes',
      plotNumber: 'D-112',
      bookingDate: DateTime.now().subtract(const Duration(days: 3)),
      amount: 800000,
      status: 'Confirmed',
      pdfUrl: "https://www.example.com/dummy.pdf",
    ),
  ];

  List<BookingRecord> _filteredBookings = [];
  String _searchQuery = '';
  String _selectedFilter = 'all';

  final List<String> _filterOptions = ['all', 'Confirmed', 'Pending', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _filteredBookings = _allBookings;
  }

  // ---------------- PDF DOWNLOAD FUNCTION ----------------

  Future<void> downloadPDF(BookingRecord record) async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission required")),
      );
      return;
    }

    try {
      Directory dir = await getApplicationDocumentsDirectory();
      String savePath = "${dir.path}/${record.projectName}_${record.plotNumber}.pdf";

      await Dio().download(
        record.pdfUrl,
        savePath,
        onReceiveProgress: (count, total) {
          print("Downloading ${record.projectName} : ${(count / total * 100).toStringAsFixed(0)}%");
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF downloaded: ${record.projectName}")),
      );

      OpenFile.open(savePath);

    } catch (e) {
      print("Error downloading PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Download failed")),
      );
    }
  }

  // ---------------- FILTER LOGIC ----------------

  void _applyFilters() {
    List<BookingRecord> filtered = _allBookings;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((record) =>
          record.projectName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedFilter != 'all') {
      filtered = filtered.where((record) => record.status == _selectedFilter).toList();
    }

    setState(() {
      _filteredBookings = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onFilterChanged(String? filter) {
    setState(() {
      _selectedFilter = filter ?? 'all';
    });
    _applyFilters();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "My Booking History",
          style:
          TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF871BBF),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchFilterSection(),
          Expanded(
            child:
            _filteredBookings.isEmpty ? _buildEmptyState() : _buildBookingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: "Search by project name...",
              prefixIcon: const Icon(Icons.search),
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filterOptions.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: _selectedFilter == filter ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) =>
                        _onFilterChanged(selected ? filter : 'all'),
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: const Color(0xFF871BBF),
                    checkmarkColor: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredBookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(_filteredBookings[index]);
      },
    );
  }

  Widget _buildBookingCard(BookingRecord record) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info_outline;

    switch (record.status) {
      case 'Confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_bottom;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record.projectName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      record.status,
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          _buildDetailRow("Plot No", record.plotNumber),
          _buildDetailRow("Booking Date", _formatDate(record.bookingDate)),
          _buildDetailRow("Amount", "₹${record.amount.toStringAsFixed(0)}"),

          const SizedBox(height: 10),

          // 🔥 Replace View Details With PDF Download Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => downloadPDF(record),
              icon: const Icon(Icons.download),
              label: const Text("Download PDF"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF871BBF),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text("$label:", style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? "No bookings found for '$_searchQuery'"
                : "No booking history available",
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}

class BookingRecord {
  final String id;
  final String projectName;
  final String plotNumber;
  final DateTime bookingDate;
  final double amount;
  final String status;
  final String pdfUrl;

  BookingRecord({
    required this.id,
    required this.projectName,
    required this.plotNumber,
    required this.bookingDate,
    required this.amount,
    required this.status,
    required this.pdfUrl,
  });
}
