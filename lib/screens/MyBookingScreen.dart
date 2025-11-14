import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../asscoiate_plot_scren/assoicateBookingHistory.dart';
import '/Model/modelofindividual.dart';
import '/service/service_of_indiviadual.dart';
import '/service/auth_manager.dart';

class MyBookingScreen extends StatefulWidget {
  final dynamic phone;
  const MyBookingScreen({super.key, this.phone});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  late Future<List<Booking>> _futureBookings;
  final BookingService _service = BookingService();
  String? _loggedInPhone;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    String? phone;

    final widgetPhone = (widget.phone ?? "").toString().trim();
    if (widgetPhone.isNotEmpty) {
      phone = widgetPhone;
    } else {
      final session = await AuthManager.getCurrentSession();
      phone = session?.userMobile ?? session?.phone;
    }

    setState(() {
      _loggedInPhone = phone;
    });

    if (phone != null && phone.isNotEmpty) {
      _futureBookings = _service.fetchBookingsForPhone(phone);
    } else {
      _futureBookings = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String loggedPhone = _loggedInPhone ?? (widget.phone ?? "").toString().trim();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "My Bookings",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF871BBF),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadBookings();
              });
            },
            tooltip: 'Refresh Bookings',
          ),
        ],
      ),
      body: FutureBuilder<List<Booking>>(
        future: _futureBookings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                    onPressed: () {
                      setState(() {
                        _loadBookings();
                      });
                    },
                  ),
                ],
              ),
            );
          }

          final allBookings = snapshot.data ?? [];
          final myBookings = allBookings.where((b) {
            if (loggedPhone.isEmpty) return false;
            final dealer = b.dealerPhnNumber.replaceAll(RegExp(r'\s+|\+91'), '');
            final logged = loggedPhone.replaceAll(RegExp(r'\s+|\+91'), '');
            return dealer == logged;
          }).toList();

          if (myBookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_online_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loggedPhone.isEmpty
                        ? "Unable to load bookings.\nPlease login again."
                        : "No bookings found for your account",
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  if (loggedPhone.isEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                      onPressed: () {
                        setState(() {
                          _loadBookings();
                        });
                      },
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: myBookings.length,
            itemBuilder: (context, index) {
              return _buildBookingCard(myBookings[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_work, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                "Plot No: ${booking.plotNumber}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87),
              ),
            ],
          ),
          const Divider(height: 20),
          _infoRow("Client Name", booking.customerName),
          _infoRow("Project Name", booking.projectName),
          _infoRow("Booked Area", "${booking.bookingArea ?? '-'} sq.ft"),
          _infoRow("Received Payment", "₹${booking.receivingAmount}"),
          _infoRow("Pending Amount", "₹${booking.pendingAmount}"),
          _infoRow("Status", booking.bookingStatus),
          _infoRow("Paid Through", booking.paidThrough),
          const SizedBox(height: 16),
          Row(
            children: [
              // Add Payment Button
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  label: const Text(
                    "Add Payment",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _addPayment(context, booking),
                ),
              ),
              const SizedBox(width: 10),

              // Add Payment Record Button
              // In your MyBookingScreen, update the Payment Record button:
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.history, color: Colors.white),
                  label: const Text(
                    "Payment",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentHistoryScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Call Now Button
              ElevatedButton.icon(
                icon: const Icon(Icons.call, color: Colors.white),
                label: const Text(
                  "Call Now",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  minimumSize: const Size(100, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _callNow(booking.customerPhnNumber),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callNow(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not call $phone")),
      );
    }
  }

  void _addPayment(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return PaymentModal(booking: booking);
      },
    );
  }
}

class PaymentModal extends StatefulWidget {
  final Booking booking;

  const PaymentModal({super.key, required this.booking});

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  String? _selectedPaymentMethod;
  bool _isSubmitting = false;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // Payment method options
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      id: 'upi',
      name: 'UPI Payment',
      icon: Icons.qr_code,
      color: Colors.purple,
      description: 'Upload UPI payment screenshot',
      requiresImage: true,
    ),
    PaymentMethod(
      id: 'neft',
      name: 'NEFT',
      icon: Icons.account_balance,
      color: Colors.blue,
      description: 'Bank transfer through NEFT',
      requiresImage: true,
    ),
    PaymentMethod(
      id: 'rtgs',
      name: 'RTGS',
      icon: Icons.money,
      color: Colors.green,
      description: 'Real Time Gross Settlement',
      requiresImage: true,
    ),
    PaymentMethod(
      id: 'cheque',
      name: 'Cheque',
      icon: Icons.description,
      color: Colors.orange,
      description: 'Upload cheque image',
      requiresImage: true,
    ),
    PaymentMethod(
      id: 'cash',
      name: 'Cash',
      icon: Icons.attach_money,
      color: Colors.green.shade700,
      description: 'Cash payment',
      requiresImage: false,
    ),
  ];

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showError("Image selection failed: $e");
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showError("Camera failed: $e");
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  bool get _requiresImage {
    if (_selectedPaymentMethod == null) return false;
    return _paymentMethods
        .firstWhere((method) => method.id == _selectedPaymentMethod)
        .requiresImage;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Text(
              "Add Payment",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "For ${widget.booking.customerName}",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Amount Input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Enter Amount (₹)",
              prefixIcon: const Icon(Icons.currency_rupee, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.purple, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payment Method Selection
          Text(
            "Select Payment Method",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          // Payment Method Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _paymentMethods.length,
            itemBuilder: (context, index) {
              final method = _paymentMethods[index];
              final isSelected = _selectedPaymentMethod == method.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = method.id;
                    // Clear image when switching to non-image method
                    if (!method.requiresImage) {
                      _selectedImage = null;
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? method.color.withOpacity(0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? method.color : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: method.color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(method.icon, color: method.color, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          method.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle, color: method.color, size: 18),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Selected Payment Method Details
          if (_selectedPaymentMethod != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _paymentMethods
                    .firstWhere((method) => method.id == _selectedPaymentMethod)
                    .color
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _paymentMethods
                      .firstWhere((method) => method.id == _selectedPaymentMethod)
                      .color
                      .withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _paymentMethods
                        .firstWhere((method) => method.id == _selectedPaymentMethod)
                        .color,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _paymentMethods
                          .firstWhere((method) => method.id == _selectedPaymentMethod)
                          .description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Image Upload Section (only show for methods that require image)
          if (_requiresImage) ...[
            Text(
              "Upload Proof",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),

            if (_selectedImage == null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Gallery"),
                      onPressed: _pickImage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.purple,
                        side: const BorderSide(color: Colors.purple),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Camera"),
                      onPressed: _takePhoto,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.purple,
                        side: const BorderSide(color: Colors.purple),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Image selected",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red.shade600),
                      onPressed: _removeImage,
                      tooltip: 'Remove image',
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
          ],

          // Remark Input
          TextField(
            controller: _remarkController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: "Remarks (optional)",
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.purple, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                disabledBackgroundColor: Colors.purple.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : const Text(
                "Submit Payment",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> _submitPayment() async {
    // Validation
    if (_amountController.text.isEmpty) {
      _showError("Please enter amount");
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError("Please enter valid amount");
      return;
    }

    if (_selectedPaymentMethod == null) {
      _showError("Please select payment method");
      return;
    }

    // Image validation for methods that require it
    if (_requiresImage && _selectedImage == null) {
      _showError("Please upload payment proof image");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // TODO: Implement actual API call here
    // You would upload the image and payment data to your server
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSubmitting = false;
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "₹${_amountController.text} added via ${_paymentMethods.firstWhere((method) => method.id == _selectedPaymentMethod).name} for ${widget.booking.customerName}",
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final bool requiresImage;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.requiresImage,
  });
}