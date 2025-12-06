import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/service/login_service.dart';
import '/Model/login_model.dart';
import 'HomeScreen.dart';
import '/service/auth_manager.dart';
import '/Model/user_session.dart';
import '/service/notification_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();
  final loginService = LoginService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Default selected position
  String position = 'TL';

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String phone = phoneController.text.trim();
    String password = passwordController.text.trim();

    LoginApi? loginData = await loginService.loginUser(phone, password, position);

    setState(() => _isLoading = false);

    if (loginData != null && loginData.statuscode == "Success") {
      // Only TL and Sales Executive are allowed
      if (loginData.position == 'TL' || loginData.position == 'Sales Executive') {
        // Save user data securely
        await storage.write(key: 'user_id', value: (loginData.id ?? '').toString());
        await storage.write(key: 'user_name', value: loginData.name ?? '');
        await storage.write(key: 'user_mobile', value: loginData.mobile ?? '');
        await storage.write(key: 'user_role', value: loginData.position ?? '');

        // Create user session
        final session = UserSession.fromLogin(
          userId: (loginData.id ?? '').toString(),
          userName: loginData.name ?? 'Unknown',
          userMobile: loginData.mobile ?? '',
          userRole: loginData.position ?? 'Employee',
          loginType: 'employee',
          profilePic: loginData.profilePic,
          phone: loginData.mobile,
          position: loginData.position,
        );

        await AuthManager.saveSession(session);

        // Save FCM token to backend after login
        try {
          await NotificationService().saveTokenToBackend();
          print('✅ Device token saved after Employee login');
        } catch (e) {
          print('⚠️ Error saving device token after login: $e');
        }

        // Navigate to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Denied: Only TL and Sales Executive can login here'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loginData?.message ?? "Login Failed. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.purple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 10),
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Image.asset("assets/logo3.png", fit: BoxFit.contain),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Employee Login",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Position Dropdown (Accountant Removed)
                    DropdownButtonFormField<String>(
                      value: position,
                      items: const [
                        DropdownMenuItem(value: 'TL', child: Text('TL')),
                        DropdownMenuItem(value: 'Sales Executive', child: Text('Sales Executive')),
                      ],
                      onChanged: (value) => setState(() => position = value!),
                      decoration: InputDecoration(
                        labelText: "Select Position",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.work, color: Colors.blueAccent),
                      ),
                      validator: (value) =>
                      value == null ? 'Please select a position' : null,
                    ),

                    const SizedBox(height: 20),

                    // Phone Number Field
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        labelText: "Enter Phone Number",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.phone, color: Colors.blueAccent),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your phone number';
                        } else if (value.length != 10) {
                          return 'Phone number must be 10 digits';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Password Field with Toggle Visibility
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Enter Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock, color: Colors.blueAccent),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter your password' : null,
                    ),

                    const SizedBox(height: 30),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "Login",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}