import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/service/associatee_login_new_service.dart';
import '/Model/associatate_new_login_model.dart';
import '../Association_page.dart'; // Dashboard page
import '/service/auth_manager.dart';
import '/Model/user_session.dart';
import '/service/notification_service.dart';

class AssociateLoginScreen extends StatefulWidget {
  const AssociateLoginScreen({super.key});

  @override
  State<AssociateLoginScreen> createState() => _AssociateLoginScreenState();
}

class _AssociateLoginScreenState extends State<AssociateLoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final AssociateLoginService service = AssociateLoginService();
  bool isLoading = false;
  bool _obscurePassword = true; // 👈 show/hide password

  void login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await service.login(
        phone: phoneController.text.trim(),
        password: passwordController.text.trim(),
      );

      setState(() => isLoading = false);

      if (response.isSuccess) {
        final phone = phoneController.text.trim();
        final session = UserSession.fromLogin(
          userId: phone, // Using phone as userId
          userName: 'Associate',
          userMobile: phone,
          userRole: 'Associate',
          loginType: 'associate',
          profilePic: null,
          phone: phone,
          position: 'Associate',
        );

        await AuthManager.saveSession(session);

        // Save FCM token to backend after login
        try {
          await NotificationService().saveTokenToBackend();
          print('✅ Device token saved after Associate login');
        } catch (e) {
          print('⚠️ Error saving device token after login: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AssociateDashboardPage(
              userName: 'Associate',
              userRole: 'Associate',
              phone: phone,
              profileImageUrl: null,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
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
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Image.asset("assets/logo3.png", fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Associate Login",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // PHONE FIELD (10 digits only)
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
                        if (value == null || value.isEmpty) return 'Enter your phone number';
                        if (value.length != 10) return 'Phone number must be 10 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // PASSWORD FIELD with eye icon
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
                      value == null || value.isEmpty ? 'Enter your password' : null,
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Login",
                            style: TextStyle(fontSize: 18, color: Colors.white)),
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