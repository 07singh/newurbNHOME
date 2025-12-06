// asscoiate_plot_scren/assoicateBookingHistory.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import '../../Model/payment_history_model.dart';
import '../../service/payment_history_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final int bookingid;
  const PaymentHistoryScreen({super.key, required this.bookingid});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late Future<List<Payment>> _futurePayments;
  final PaymentHistoryService _service = PaymentHistoryService();

  List<Payment> _allPayments = [];
  List<Payment> _filteredPayments = [];
  String _searchQuery = '';
  String _selectedFilter = 'all';
  final List<String> _filterOptions = ['all', 'Pending', 'Confirmed', 'Cancelled', 'Sellout'];
  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadPaymentHistory() {
    setState(() {
      _futurePayments = _service.fetchPaymentHistory(bookingId: widget.bookingid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "Booking #${widget.bookingid} History",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF871BBF),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Payment>>(
        future: _futurePayments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF871BBF)),
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadPaymentHistory,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF871BBF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          // Filter by booking ID
          final bookingPayments = snapshot.data!
              .where((p) => p.bookingId == widget.bookingid)
              .toList();

          if (bookingPayments.isEmpty) {
            return _buildEmptyState();
          }

          // Update all payments if data changed
          if (_allPayments.length != bookingPayments.length ||
              (_allPayments.isNotEmpty && 
               _allPayments.first.paymentId != bookingPayments.first.paymentId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _allPayments = bookingPayments;
                });
                _applyFilters();
              }
            });
          } else if (_allPayments.isEmpty) {
            _allPayments = bookingPayments;
          }

          // Apply filters synchronously for initial render
          final filtered = _getFilteredPayments(_allPayments.isEmpty ? bookingPayments : _allPayments);

          return Column(
            children: [
              _buildSearchFilterSection(),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildPaymentList(filtered),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Payment> _getFilteredPayments(List<Payment> payments) {
    List<Payment> filtered = List.from(payments);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) =>
          p.bookingInfo.projectName.toLowerCase().contains(query) ||
          p.bookingInfo.customerName.toLowerCase().contains(query) ||
          p.bookingInfo.plotNumber.toLowerCase().contains(query),
      ).toList();
    }

    // Filter by payment status (using Payment_Status field)
    if (_selectedFilter != 'all') {
      filtered = filtered.where((p) => 
          p.paymentStatus == _selectedFilter || 
          p.bookingInfo.bookingStatus == _selectedFilter,
      ).toList();
    }

    return filtered;
  }

  void _applyFilters() {
    final filtered = _getFilteredPayments(_allPayments);
    setState(() {
      _filteredPayments = filtered;
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  void _onFilterChanged(String? filter) {
    _selectedFilter = filter ?? 'all';
    _applyFilters();
  }

  Widget _buildSearchFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: "Search project, client, or plot...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filterOptions.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      f,
                      style: TextStyle(
                        color: _selectedFilter == f ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                    selected: _selectedFilter == f,
                    onSelected: (s) => _onFilterChanged(s ? f : 'all'),
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: const Color(0xFF871BBF),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList([List<Payment>? payments]) {
    final displayPayments = payments ?? _filteredPayments;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: displayPayments.length,
      itemBuilder: (context, i) => _buildPaymentCard(displayPayments[i]),
    );
  }

  Widget _buildPaymentCard(Payment p) {
    // Use Payment_Status for payment status, Booking_Status for booking status
    final paymentStatus = p.paymentStatus;
    final bookingStatus = p.bookingInfo.bookingStatus;
    final statusColor = _getStatusColor(paymentStatus);
    final statusIcon = _getStatusIcon(paymentStatus);
    final hasImage = p.screenshot.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                p.bookingInfo.projectName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          paymentStatus,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (bookingStatus != paymentStatus && bookingStatus != 'Pending')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        bookingStatus,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailRow("Plot No", p.bookingInfo.plotNumber),
          _buildDetailRow("Client", p.bookingInfo.customerName),
          _buildDetailRow(
            "Paid",
            "₹${p.paidAmount.toStringAsFixed(2)} via ${p.paidThrough}",
          ),
          _buildDetailRow("Date", _formatDate(p.paymentDate)),
          _buildDetailRow("Payment Status", paymentStatus),
          const SizedBox(height: 10),
          Row(
            children: [
              if (hasImage)
                ElevatedButton.icon(
                  onPressed: () => _viewImage(p.screenshot),
                  icon: const Icon(Icons.image, size: 16),
                  label: const Text("View Proof"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white),
                ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: hasImage ? () => _downloadImage(p.screenshot) : null,
                icon: const Icon(Icons.download, size: 16),
                label: const Text("Download"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasImage ? const Color(0xFF871BBF) : Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
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
          SizedBox(width: 90, child: Text("$label:", style: const TextStyle(fontSize: 12, color: Colors.black54))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600))),
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
                ? "No results for '$_searchQuery'"
                : "No payment history for Booking #${widget.bookingid}",
            style: const TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      case 'Sellout':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Confirmed':
        return Icons.check_circle;
      case 'Pending':
        return Icons.hourglass_bottom;
      case 'Cancelled':
        return Icons.cancel;
      case 'Sellout':
        return Icons.sell;
      default:
        return Icons.info;
    }
  }

  // View Image
  void _viewImage(String path) {
    // Handle empty screenshot path
    if (path.isEmpty || path.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No payment proof image available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Construct full URL - path can be "Uploads/Payment/..." or already full URL
    String url;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      url = path;
    } else {
      // Remove leading slash if present
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;
      url = 'https://realapp.cheenu.in/$cleanPath';
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF871BBF)),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 8),
                        Text('Failed to load image'),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Download Image
  Future<void> _downloadImage(String path) async {
    // Handle empty screenshot path
    if (path.isEmpty || path.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No payment proof image available to download'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Request storage permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission required to download files'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF871BBF)),
        ),
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = path.split('/').last;
      final savePath = "${dir.path}/$fileName";
      
      // Construct full URL - path can be "Uploads/Payment/..." or already full URL
      String url;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        url = path;
      } else {
        // Remove leading slash if present
        final cleanPath = path.startsWith('/') ? path.substring(1) : path;
        url = 'https://realapp.cheenu.in/$cleanPath';
      }

      await Dio().download(url, savePath);

      if (!mounted) return;
      
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded: $fileName'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => OpenFile.open(savePath),
          ),
        ),
      );
      
      OpenFile.open(savePath);
    } catch (e) {
      if (!mounted) return;
      
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}