import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testsd_app/HRdashboad/HrDashboard.dart';
import 'package:testsd_app/sign_page.dart';
import 'Association_page.dart';
import 'DirectLogin/DirectLoginPage.dart';
import 'HomeScreen.dart';
import '/signin_role/sign_role_direct.dart';
import '/signin_role/sign_role_hr.dart';
import '/signin_role/sign_role_associate.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedButton;

  void _handleButtonPress(String buttonType) {
    setState(() {
      _selectedButton = buttonType;
    });

    // Navigate after a brief delay to show the color change
    Future.delayed(const Duration(milliseconds: 200), () {
      switch (buttonType) {
        case 'direct':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignInPaged()),
          );
          break;
        case 'employee':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignInPage()),
          );
          break;
        case 'hr':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignInPageh()),
          );
          break;
        case 'associate':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AssociateLoginScreen()),
          );
          break;
      }

      // Reset selection after navigation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _selectedButton = null;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Header Section with Rectangular Image
            Container(
              width: double.infinity,
              height: height * 0.35,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ✅ Rectangular Image Container
                  Container(
                    width: width * 0.8,
                    height: height * 0.25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        "assets/logo3.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ Main Content Area
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.06,
                  vertical: height * 0.02,
                ),
                child: Column(
                  children: [
                    // ✅ Welcome Text
                    Column(
                      children: [
                        SizedBox(height: height * 0.02),
                        Text(
                          "Choose Your Login Method",
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: height * 0.01),
                        Text(
                          "Select your role to continue",
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: width * 0.035,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: height * 0.03),
                      ],
                    ),

                    // ✅ Scrollable Buttons Group
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildDynamicLoginButton(
                              context: context,
                              title: "Direct Login",
                              subtitle: "External partner access",
                              icon: Icons.login_rounded,
                              color: Colors.blue[700]!,
                              buttonType: 'direct',
                              isSelected: _selectedButton == 'direct',
                              onPressed: () => _handleButtonPress('direct'),
                            ),
                            SizedBox(height: height * 0.02),

                            _buildDynamicLoginButton(
                              context: context,
                              title: "Employee Login",
                              subtitle: "Internal team access",
                              icon: Icons.work_rounded,
                              color: Colors.green[600]!,
                              buttonType: 'employee',
                              isSelected: _selectedButton == 'employee',
                              onPressed: () => _handleButtonPress('employee'),
                            ),
                            SizedBox(height: height * 0.02),

                            _buildDynamicLoginButton(
                              context: context,
                              title: "HR Login",
                              subtitle: "Human resources portal",
                              icon: Icons.supervisor_account_rounded,
                              color: Colors.orange[600]!,
                              buttonType: 'hr',
                              isSelected: _selectedButton == 'hr',
                              onPressed: () => _handleButtonPress('hr'),
                            ),
                            SizedBox(height: height * 0.02),

                            _buildDynamicLoginButton(
                              context: context,
                              title: "Associate Login",
                              subtitle: "Partner organization access",
                              icon: Icons.person_rounded,
                              color: Colors.purple[600]!,
                              buttonType: 'associate',
                              isSelected: _selectedButton == 'associate',
                              onPressed: () => _handleButtonPress('associate'),
                            ),

                            // ✅ Extra spacing for better scroll
                            SizedBox(height: height * 0.03),
                          ],
                        ),
                      ),
                    ),

                    // ✅ Footer Text
                    Padding(
                      padding: EdgeInsets.only(bottom: height * 0.02, top: height * 0.01),
                      child: Text(
                        "New Urban Home Access Portal",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicLoginButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String buttonType,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? color.withOpacity(0.4)
                : color.withOpacity(0.2),
            blurRadius: isSelected ? 20 : 12,
            offset: Offset(0, isSelected ? 8 : 4),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: height * 0.02,
              horizontal: width * 0.05,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: isSelected
                    ? [
                  color,
                  Color.lerp(color, Colors.white, 0.2)!,
                ]
                    : [
                  color.withOpacity(0.9),
                  color,
                ],
              ),
              border: Border.all(
                color: isSelected ? Colors.white : color.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // ✅ Animated Icon Container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : Colors.white.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? color : Colors.white,
                    size: width * 0.06,
                  ),
                ),
                SizedBox(width: width * 0.04),

                // ✅ Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: width * 0.042,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.9),
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // ✅ Animated Arrow Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isSelected ? color : Colors.white,
                    size: width * 0.04,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}