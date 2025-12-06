import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testsd_app/HRdashboad/HrDashboard.dart';
import 'package:testsd_app/sign_page.dart';
import 'Association_page.dart';
import 'DirectLogin/DirectLoginPage.dart';
import 'HomeScreen.dart';
import'/signin_role/sign_role_direct.dart';
import'/signin_role/sign_role_hr.dart';
import'/signin_role/sign_role_associate.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Screen width & height for responsiveness
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(


      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.06,
              vertical: height * 0.02,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Logo section (top) - Reduced size to prevent overflow
                SizedBox(
                  width: width * 0.7,
                  height: height * 0.25,
                  child: Image.asset("assets/logo3.png", fit: BoxFit.contain),
                ),
                SizedBox(height: height * 0.05),

                // ✅ Buttons group (bottom) - Reduced spacing
                Column(
                  children: [
                    LoginButton(
                      title: "Direct Login",
                      color: Colors.blue,
                      icon: Icons.login,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignInPaged()),
                        );
                      },
                    ),
                    SizedBox(height: height * 0.015),

                    LoginButton(
                      title: "Employee Login",
                      color: Colors.green,
                      icon: Icons.work,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignInPage()),
                        );
                      },
                    ),
                    SizedBox(height: height * 0.015),

                    LoginButton(
                      title: "HR Login",
                      color: Colors.orange,
                      icon: Icons.supervisor_account,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignInPageh()),
                        );
                      },
                    ),
                    SizedBox(height: height * 0.015),

                    LoginButton(
                      title: "Associate Login",
                      color: Colors.purple,
                      icon: Icons.person,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AssociateLoginScreen (),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: height * 0.02),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onPressed;
  final IconData? icon;

  const LoginButton({
    super.key,
    required this.title,
    required this.color,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Get screen width for scaling font & padding
    final width = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(
            vertical: width * 0.04,
            horizontal: width * 0.06,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: width * 0.06),
              SizedBox(width: width * 0.03),
            ],
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: width * 0.045, // ✅ Responsive font
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}