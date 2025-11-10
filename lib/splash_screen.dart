import 'package:flutter/material.dart';

import 'Employ.dart';
import '/service/auth_manager.dart';
import '/Model/user_session.dart';
import '/HomeScreen.dart';
import '/DirectLogin/DirectLoginPage.dart';
import '/HRdashboad/HrDashboard.dart';
import '/Association_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    // Show splash for minimum 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    
    // Check if user is already logged in
    final isLoggedIn = await AuthManager.isLoggedIn();
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      // Get user session
      final session = await AuthManager.getCurrentSession();
      
      if (session != null && mounted) {
        // Navigate to appropriate dashboard based on login type
        Widget destination;
        
        switch (session.loginType?.toLowerCase()) {
          case 'director':
          case 'admin':
            destination = DirectloginPage(
              userName: session.userName ?? 'Unknown User',
              userRole: session.userRole ?? 'Director',
              profileImageUrl: session.fullProfileImageUrl,
            );
            break;
            
          case 'employee':
          case 'tl':
          case 'sales executive':
            destination = HomeScreen(
              userName: session.userName,
              userRole: session.userRole,
              profileImageUrl: session.fullProfileImageUrl,
              userPhone: session.userMobile,
            );
            break;
            
          case 'hr':
            destination = HRDashboardPage(
              userName: session.userName ?? 'Unknown',
              userRole: session.userRole ?? 'HR',
              profileImageUrl: session.fullProfileImageUrl,
            );
            break;
            
          case 'associate':
            destination = AssociateDashboardPage(
              userName: session.userName ?? 'Associate',
              userRole: session.userRole ?? 'Associate',
              phone: session.userMobile ?? session.phone ?? '',
              profileImageUrl: session.fullProfileImageUrl,
            );
            break;
            
          default:
            // If login type is unknown, go to login page
            destination = const HomePage();
        }
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      } else {
        // Session invalid, go to login page
        _navigateToLogin();
      }
    } else {
      // Not logged in, go to login page
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PNG Logo Image
            SizedBox(
              width: 500,
              height: 500,
              child: Image.asset("assets/logo3.png"), // Your PNG image path
            ),
            const SizedBox(height: 20),
            // App Name
            const Text(
              'MyApp',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            const Text(
              'Welcome to Our Application',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 30),
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
