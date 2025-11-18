import 'package:flutter/material.dart';
import '/service/ChangePasswordService.dart';
import '/Model/ChangePasswordResponse.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String phone;
  final String position;

  const ChangePasswordScreen({
    super.key,
    required this.phone,
    required this.position,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  TextEditingController oldPassCtrl = TextEditingController();
  TextEditingController newPassCtrl = TextEditingController();
  TextEditingController confirmPassCtrl = TextEditingController();

  bool loading = false;

  submitChangePassword() async {
    setState(() => loading = true);

    try {
      ChangePasswordResponse res =
      await ChangePasswordService().changePassword(
        phone: widget.phone,
        position: widget.position,
        oldPassword: oldPassCtrl.text.trim(),
        newPassword: newPassCtrl.text.trim(),
        confirmPassword: confirmPassCtrl.text.trim(),
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.message)));

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: oldPassCtrl,
              decoration: const InputDecoration(labelText: "Old Password"),
            ),
            TextField(
              controller: newPassCtrl,
              decoration: const InputDecoration(labelText: "New Password"),
            ),
            TextField(
              controller: confirmPassCtrl,
              decoration: const InputDecoration(labelText: "Confirm Password"),
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: submitChangePassword,
              child: const Text("Change Password"),
            ),
          ],
        ),
      ),
    );
  }
}
