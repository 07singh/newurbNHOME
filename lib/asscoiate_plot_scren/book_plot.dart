import 'package:flutter/material.dart';
import '/plot_screen/hh.dart';
import '/plot_screen/new_screen.dart';
import '/Association_page.dart';
import '/asscoiate_plot_scren/book_plot.dart';

class BookPlotScreenNoNav extends StatefulWidget {
  const BookPlotScreenNoNav({Key? key}) : super(key: key);

  @override
  State<BookPlotScreenNoNav> createState() => _BookPlotScreenNoNavState();
}

class _BookPlotScreenNoNavState extends State<BookPlotScreenNoNav> {
  // Mock data for demonstration - replace with your actual data
  String _userName = "Akhand singh";
  String _userPhone = "+1234567890";
  String? _userEmail = "john.doe@example.com";
  String? _associateId = "A12345";
  bool _isLoadingProfile = false;
  Map<String, dynamic>? _profile = {'status': true};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Book Plot',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF8441B1),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Defence Enclave Phase 2 Button
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlotLayoutScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF871BBF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Defence Enclave Phase 2',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Green Regency Phase 2 Button
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlotScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Green Regency Phase 2',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}