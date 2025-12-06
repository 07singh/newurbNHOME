import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../Model/payment_history_model.dart';
import '../service/payment_history_service.dart';

class BookingSummaryDetails {
  final int bookingId;
  final String projectName;
  final String plotNumber;
  final String plotType;
  final String bookingStatus;
  final String bookingArea;
  final String remainingArea;
  final String totalArea;
  final String purchasePrice;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final String paidThrough;
  final String dealerName;
  final String dealerPhone;
  final String customerName;
  final String customerPhone;
  final String screenshot;

  const BookingSummaryDetails({
    required this.bookingId,
    required this.projectName,
    required this.plotNumber,
    required this.plotType,
    required this.bookingStatus,
    required this.bookingArea,
    required this.remainingArea,
    required this.totalArea,
    required this.purchasePrice,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.paidThrough,
    required this.dealerName,
    required this.dealerPhone,
    required this.customerName,
    required this.customerPhone,
    required this.screenshot,
  });
}

class BookingSummaryIndividual extends StatefulWidget {
  final BookingSummaryDetails summary;

  const BookingSummaryIndividual({Key? key, required this.summary}) : super(key: key);

  @override
  State<BookingSummaryIndividual> createState() => _BookingSummaryIndividualState();
}

class _BookingSummaryIndividualState extends State<BookingSummaryIndividual> {
  final PaymentHistoryService _paymentHistoryService = PaymentHistoryService();
  final Set<int> _processingPayments = {};
  List<Payment> _payments = [];
  bool _isLoadingPayments = true;
  String? _paymentsError;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() {
      _isLoadingPayments = true;
      _paymentsError = null;
    });

    try {
      final fetched = await _paymentHistoryService.fetchPaymentHistory(bookingId: widget.summary.bookingId);
      final filtered = fetched.where((payment) => payment.bookingId == widget.summary.bookingId).toList();
      if (!mounted) return;
      setState(() => _payments = filtered);
    } catch (e) {
      if (!mounted) return;
      setState(() => _paymentsError = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingPayments = false);
    }
  }

  Future<void> _acceptPayment(int paymentId) async {
    await _handlePaymentDecision(paymentId, "accept");
  }

  Future<void> _rejectPayment(int paymentId) async {
    await _handlePaymentDecision(paymentId, "reject");
  }

  Future<void> _handlePaymentDecision(int paymentId, String action) async {
    if (_processingPayments.contains(paymentId)) return;
    setState(() => _processingPayments.add(paymentId));

    final url = Uri.parse("https://realapp.cheenu.in/api/$action/payment?paymentId=$paymentId");
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        _showSnackBar("Payment ${action == "accept" ? "accepted" : "rejected"}", Colors.green);
        await _fetchPayments();
      } else {
        _showSnackBar("Failed to ${action == "accept" ? "accept" : "reject"} payment", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Failed: $e", Colors.red);
    } finally {
      if (!mounted) return;
      setState(() => _processingPayments.remove(paymentId));
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(widget.summary.bookingStatus);
    final hasScreenshot = _hasScreenshot(widget.summary.screenshot);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.summary.customerName.isNotEmpty ? widget.summary.customerName : "Booking Summary"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle("Booking Overview"),
                Chip(
                  label: Text(widget.summary.bookingStatus.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildKeyValue("Project", widget.summary.projectName),
            _buildKeyValue("Plot Number", widget.summary.plotNumber),
            _buildKeyValue("Plot Type", widget.summary.plotType),
            const SizedBox(height: 16),
            _sectionTitle("Area Details"),
            const SizedBox(height: 6),
            _buildKeyValue("Booking Area", widget.summary.bookingArea),
            _buildKeyValue("Remaining Area", widget.summary.remainingArea),
            _buildKeyValue("Total Area", widget.summary.totalArea),
            const SizedBox(height: 16),
            _sectionTitle("Financials"),
            const SizedBox(height: 6),
            _buildKeyValue(
              "Purchase Price",
              widget.summary.purchasePrice.trim().isNotEmpty ? "₹${widget.summary.purchasePrice}" : "-",
            ),
            _buildKeyValue("Total Amount", _formatAmount(widget.summary.totalAmount)),
            _buildKeyValue("Paid Amount", _formatAmount(widget.summary.paidAmount)),
            _buildKeyValue("Pending Amount", _formatAmount(widget.summary.pendingAmount)),
            _buildKeyValue("Paid Through", widget.summary.paidThrough),
            const SizedBox(height: 16),
            _sectionTitle("Contacts"),
            const SizedBox(height: 6),
            _buildKeyValue("Customer", widget.summary.customerName),
            _buildKeyValue("Customer Phone", widget.summary.customerPhone),
            _buildKeyValue("Dealer", widget.summary.dealerName),
            _buildKeyValue("Dealer Phone", widget.summary.dealerPhone),
            const SizedBox(height: 16),
            _sectionTitle("Payment Screenshot"),
            const SizedBox(height: 6),
            hasScreenshot
                ? _buildScreenshotPreview(context, widget.summary.screenshot)
                : Text("No screenshot provided", style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            _sectionTitle("Payment History"),
            const SizedBox(height: 8),
            _buildPaymentHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistorySection() {
    if (_isLoadingPayments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_paymentsError != null) {
      return Text("Failed to load payments: $_paymentsError", style: const TextStyle(color: Colors.red));
    }

    if (_payments.isEmpty) {
      return const Text("No payments submitted for this booking yet", style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: _payments.map(_buildPaymentRow).toList(),
    );
  }

  Widget _buildPaymentRow(Payment payment) {
    final status = payment.paymentStatus;
    final isPending = !_isApprovedStatus(status);
    final paymentDate = DateFormat('dd MMM yyyy').format(payment.paymentDate.toLocal());
    final screenshotWidget = _createScreenshotWidget(payment.screenshot, fit: BoxFit.cover);

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: const Icon(Icons.payments, color: Colors.deepPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "₹${payment.paidAmount.toStringAsFixed(2)} • ${payment.paidThrough}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$status • $paymentDate",
                        style: TextStyle(color: isPending ? Colors.orange : Colors.green),
                      ),
                    ],
                  ),
                ),
                if (_hasScreenshot(payment.screenshot))
                  IconButton(
                    onPressed: () => _showFullScreenshot(context, payment.screenshot),
                    icon: const Icon(Icons.image, color: Colors.deepPurple),
                    tooltip: "View screenshot",
                  ),
              ],
            ),
        if (screenshotWidget != null) ...[
          const SizedBox(height: 10),
          _buildInlineScreenshot(context, screenshotWidget, payment.screenshot),
        ],
            if (isPending) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _processingPayments.contains(payment.paymentId)
                        ? null
                        : () => _acceptPayment(payment.paymentId),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: _processingPayments.contains(payment.paymentId)
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Accept"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _processingPayments.contains(payment.paymentId)
                        ? null
                        : () => _rejectPayment(payment.paymentId),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Reject"),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeyValue(String title, String value) {
    final display = value.trim().isNotEmpty ? value.trim() : "-";
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text("$title:", style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16));

  String _formatAmount(double value) => "₹${value.toStringAsFixed(2)}";

  bool _hasScreenshot(String data) {
    final trimmed = data.trim();
    return trimmed.isNotEmpty && trimmed.toLowerCase() != "null";
  }

  Widget _buildScreenshotPreview(BuildContext context, String data) {
    final imageWidget = _createScreenshotWidget(data, fit: BoxFit.cover);
    if (imageWidget == null) {
      return Text("Screenshot not available", style: TextStyle(color: Colors.grey.shade600));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showFullScreenshot(context, data),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: imageWidget,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text("Tap to view fullscreen", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  void _showFullScreenshot(BuildContext context, String data) {
    final imageWidget = _createScreenshotWidget(data, fit: BoxFit.contain);
    if (imageWidget == null) {
      _showSnackBar("Screenshot unavailable", Colors.grey);
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
              title: const Text("Screenshot"),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ],
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: InteractiveViewer(child: imageWidget),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineScreenshot(BuildContext context, Widget imageWidget, String data) {
    return GestureDetector(
      onTap: () => _showFullScreenshot(context, data),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 120,
          width: double.infinity,
          child: imageWidget,
        ),
      ),
    );
  }

  Widget? _createScreenshotWidget(String raw, {BoxFit fit = BoxFit.cover}) {
    final normalized = _normalizeScreenshotUrl(raw);
    if (normalized != null) {
      return Image.network(
        normalized,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.red)),
      );
    }

    final bytes = _decodeBase64Image(raw);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.red)),
      );
    }

    return null;
  }

  String? _normalizeScreenshotUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    if (lower == "null") return null;
    if (trimmed.contains("base64")) return null;
    if (trimmed.startsWith("http")) return trimmed;
    if (trimmed.startsWith("/")) {
      return "https://realapp.cheenu.in$trimmed";
    }
    return "https://realapp.cheenu.in/$trimmed";
  }

  Uint8List? _decodeBase64Image(String value) {
    final cleaned = value.contains(',') ? value.split(',').last : value;
    final trimmed = cleaned.trim();
    if (trimmed.length < 100) return null;
    try {
      return base64Decode(trimmed);
    } catch (_) {
      return null;
    }
  }

  MaterialColor _statusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains("sellout")) {
      return Colors.green;
    }
    if (lower.contains("booked")) {
      return Colors.blue;
    }
    if (lower.contains("pending")) {
      return Colors.orange;
    }
    return Colors.grey;
  }

  bool _isApprovedStatus(String status) {
    final lower = status.toLowerCase();
    return lower.contains("approved") || lower.contains("accepted") || lower.contains("rejected");
  }
}

