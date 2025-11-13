import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/Model/modelofindividual.dart';
import '/service/service_of_indiviadual.dart';
import '/service/auth_manager.dart';

class MyBookingScreen extends StatefulWidget {
  final dynamic phone;
  const MyBookingScreen({super.key, this.phone}); // dynamic + optional

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

  /// Load bookings for the logged-in user from session
  Future<void> _loadBookings() async {
    String? phone;
    
    // First, try to get phone from widget parameter
    final widgetPhone = (widget.phone ?? "").toString().trim();
    if (widgetPhone.isNotEmpty) {
      phone = widgetPhone;
    } else {
      // If no phone provided, get from session (logged-in user)
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

          // ✅ Filter: show only bookings by logged-in dealer
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
              ElevatedButton.icon(
                icon: const Icon(Icons.call, color: Colors.white),
                label: const Text(
                  "Call Now",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  minimumSize: const Size(120, 44),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final TextEditingController _amountController = TextEditingController();
        final TextEditingController _remarkController = TextEditingController();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add Payment",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Enter Amount",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _remarkController,
                decoration: InputDecoration(
                  labelText: "Remark (optional)",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "₹${_amountController.text} added for ${booking.customerName}"),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade800,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Submit Payment",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}