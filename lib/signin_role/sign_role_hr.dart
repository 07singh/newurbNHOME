import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/service/login_service.dart';
import '/Model/login_model.dart';
import '/HRdashboad/HrDashboard.dart'; // HR dashboard import

class SignInPageh extends StatefulWidget {
  const SignInPageh({super.key});

  @override
  State<SignInPageh> createState() => _SignInPagehState();
}

class _SignInPagehState extends State<SignInPageh> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();
  final loginService = LoginService();

  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String phone = phoneController.text.trim();
      String password = passwordController.text.trim();

      // Call the login API
      LoginApi? loginData = await loginService.loginUser(phone, password, "HR");

      setState(() => _isLoading = false);

      if (loginData != null && loginData.statuscode.toLowerCase() == "success") {
        // Only HR can login
        if ((loginData.position ?? '').toLowerCase() == 'hr') {
          // Store user details securely
          await storage.write(key: 'user_id', value: loginData.id.toString());
          await storage.write(key: 'user_name', value: loginData.name ?? '');
          await storage.write(key: 'user_mobile', value: loginData.mobile ?? '');
          await storage.write(key: 'user_role', value: loginData.position ?? '');
          await storage.write(key: 'profile_pic', value: loginData.profilePic ?? '');

          // Navigate to HR Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HRDashboardPage(
                userName: loginData.name ?? 'Unknown',
                userRole: loginData.position ?? 'HR',
                profileImageUrl: (loginData.profilePic != null && loginData.profilePic!.isNotEmpty)
                    ? "https://realapp.cheenu.in/Images/${loginData.profilePic}"
                    : null,
              ),
            ),
          );
        } else {
          // Access denied for non-HR
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access Denied: Only HR can login here'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        // Login failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loginData?.message ?? 'Login Failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.redAccent,
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
            colors: [Colors.green.shade400, Colors.teal.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
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
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Image.asset("assets/logo3.png", fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "HR Login",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: "Enter Phone Number",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.phone, color: Colors.teal),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Enter your phone number' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Enter Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock, color: Colors.teal),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter your password' : null,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.teal,
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

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
