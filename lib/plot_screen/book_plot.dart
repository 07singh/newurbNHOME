import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/plot_screen/hh.dart';
import '/plot_screen/new_screen.dart';
import '/emoloyee_file/profile_screen.dart';
import '/DirectLogin/DirectLoginPage.dart';
import '/DirectLogin/client_visit.dart';
import '/provider/user_provider.dart';
import'/Add_associate/add_associate_screen.dart';

class BookPlotScreen extends StatefulWidget {
  const BookPlotScreen({Key? key}) : super(key: key);

  @override
  State<BookPlotScreen> createState() => _BookPlotScreenState();
}

class _BookPlotScreenState extends State<BookPlotScreen> {
  int _currentIndex = 1; // BookPlotScreen

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Book Plot',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFD700),
        iconTheme: const IconThemeData(color: Colors.black),
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
                  backgroundColor: Colors.blue,
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
      bottomNavigationBar: _buildBottomNavigationBar(userProvider),
    );
  }

  Widget _buildBottomNavigationBar(UserProvider userProvider) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFFFD700),
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey.shade800,
      showUnselectedLabels: true,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });

        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DirectloginPage(),
            ),
          );
        } else if (index == 1) {
          // Already on BookPlotScreen
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ClientVisitScreen()),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AddAssociateScreen ()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_rounded), label: "Bookings"),
        BottomNavigationBarItem(icon: Icon(Icons.visibility_rounded), label: "Client Visit"),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "AddAssociateScreen "),
      ],
    );
  }
}
