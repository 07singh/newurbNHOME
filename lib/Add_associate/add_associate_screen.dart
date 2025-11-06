import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '/plot_screen/book_plot.dart';
import '/DirectLogin/DirectLoginPage.dart';
import '/emoloyee_file/profile_screen.dart';
import '/DirectLogin/client_visit.dart';
import '/Add_associate/add_associate_screen.dart';

class AppConstants {
  static const String apiUrl = "https://realapp.cheenu.in/api/associate/add";
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color secondaryColor = Color(0xFF42A5F5);
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const Map<String, String> fieldLabels = {
    "FullName": "Full Name",
    "Phone": "Phone",
    "Email": "Email",
    "CurrentAddress": "Current Address",
    "PermanentAddress": "Permanent Address",
    "State": "State",
    "City": "City",
    "Pincode": "Pincode",
    "AadhaarNo": "Aadhaar Number",
    "PanNo": "PAN Number",
    "Password": "Password",
  };
  static const Map<String, String> fileLabels = {
    "ProfilePic": "Upload Profile Picture",
    "AadharFrontPic": "Upload Aadhaar Front",
    "AadhaarBackPic": "Upload Aadhaar Back",
    "PanPic": "Upload PAN Card",
  };
}

class AddAssociateScreen extends StatefulWidget {
  const AddAssociateScreen({super.key});

  @override
  State<AddAssociateScreen> createState() => _AddAssociateScreenState();
}

class _AddAssociateScreenState extends State<AddAssociateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _sameAsCurrent = false;
  int _currentIndex = 0;

  final Map<String, TextEditingController> _controllers = {
    for (var key in AppConstants.fieldLabels.keys) key: TextEditingController(),
  };

  final Map<String, FocusNode> _focusNodes = {
    for (var key in AppConstants.fieldLabels.keys) key: FocusNode(),
  };

  final Map<String, File?> _files = {
    for (var key in AppConstants.fileLabels.keys) key: null,
  };

  final Map<String, String?> _base64 = {
    for (var key in AppConstants.fileLabels.keys) key: null,
  };

  @override
  void initState() {
    super.initState();
    _focusNodes.forEach((key, node) {
      node.addListener(() => setState(() {}));
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    _focusNodes.values.forEach((f) => f.dispose());
    super.dispose();
  }
  Future<void> _pickImage(String key) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No file selected")),
        );
        return;
      }

      final filePath = result.files.single.path!;
      final file = File(filePath);

      // Check file size
      final fileSize = await file.length();
      if (fileSize > AppConstants.maxFileSizeBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ File size exceeds 5MB limit")),
        );
        return;
      }

      // Compress image
      final targetPath =
          "${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 60,
      );

      if (compressedXFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to compress image")),
        );
        return;
      }

      // ✅ Convert XFile → File
      final compressedFile = File(compressedXFile.path);

      // Convert to Base64
      final bytes = await compressedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Update UI
      setState(() {
        _files[key] = compressedFile;
        _base64[key] = base64Image;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${AppConstants.fileLabels[key]} uploaded ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error picking file: $e")),
      );
    }
  }



  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fix the errors in the form")),
      );
      return;
    }

    for (var key in AppConstants.fileLabels.keys) {
      if (_base64[key] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please upload ${AppConstants.fileLabels[key]}")),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      final Map<String, dynamic> bodyMap = {
        "FullName": _controllers["FullName"]!.text.trim(),
        "Phone": _controllers["Phone"]!.text.trim(),
        "Email": _controllers["Email"]!.text.trim(),
        "CurrentAddress": _controllers["CurrentAddress"]!.text.trim(),
        "PermanentAddress": _controllers["PermanentAddress"]!.text.trim(),
        "State": _controllers["State"]!.text.trim(),
        "City": _controllers["City"]!.text.trim(),
        "Pincode": _controllers["Pincode"]!.text.trim(),
        "AadhaarNo": _controllers["AadhaarNo"]!.text.trim(),
        "PanNo": _controllers["PanNo"]!.text.trim(),
        "AadharFrontPic": _base64["AadharFrontPic"],
        "AadhaarBackPic": _base64["AadhaarBackPic"],
        "PanPic": _base64["PanPic"],
        "Password": _controllers["Password"]!.text.trim(),
        "Profile_Pic": _base64["ProfilePic"], // ✅ matches backend key
        "Status": true,
        "AssociateId": "AS${DateTime.now().millisecondsSinceEpoch % 100000}", // simple random ID
        "CreateDate": now.toIso8601String(),
        "JoiningDate": now.toIso8601String(),
        "LoginDate": now.toIso8601String(),
        "LogoutDate": null
      };

      final response = await http.post(
        Uri.parse(AppConstants.apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bodyMap),
      );

      setState(() => _isLoading = false);

      final res = jsonDecode(response.body);
      if (response.statusCode == 200 || res["Status"] == true) {
        _showDialog("✅ Success", "Associate added successfully!");
      } else {
        _showDialog("❌ Error", res["Message"] ?? "Failed to add associate.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showDialog("⚠️ Error", "Something went wrong: $e");
    }
  }


  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (title.contains("Success")) {
                setState(() {
                  _controllers.forEach((key, c) => c.clear());
                  _files.updateAll((key, value) => null);
                  _base64.updateAll((key, value) => null);
                  _sameAsCurrent = false;
                });
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add New Associate",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFD700),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _profilePicField(),
                    const SizedBox(height: 20),
                    ..._inputFields(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Submit",
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _profilePicField() {
    final file = _files["ProfilePic"];
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickImage("ProfilePic"),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: file != null ? FileImage(file) : null,
            child: file == null
                ? const Icon(Icons.camera_alt, size: 40, color: Colors.black54)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        const Text("Upload Profile Picture",
            style: TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFFFD700),
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey.shade800,
      showUnselectedLabels: true,
      onTap: (index) {
        setState(() => _currentIndex = index);
        if (index == 0) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const DirectloginPage()));
        } else if (index == 1) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const BookPlotScreen()));
        } else if (index == 2) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const ClientVisitScreen()));
        } else if (index == 3) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const AddAssociateScreen()));
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_rounded), label: "Bookings"),
        BottomNavigationBarItem(icon: Icon(Icons.visibility_rounded), label: "Client Visit"),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Add Associate"),
      ],
    );
  }

  List<Widget> _inputFields() {
    return [
      _textField("FullName", "Enter full name"),
      _textField("Phone", "Enter phone number"),
      _textField("Email", "Enter email"),
      _textField("CurrentAddress", "Enter current address"),
      Row(
        children: [
          Checkbox(
            value: _sameAsCurrent,
            onChanged: (v) {
              setState(() {
                _sameAsCurrent = v!;
                if (v) {
                  _controllers["PermanentAddress"]!.text =
                      _controllers["CurrentAddress"]!.text;
                } else {
                  _controllers["PermanentAddress"]!.clear();
                }
              });
            },
          ),
          const Text("Same as Current Address"),
        ],
      ),
      _textField("PermanentAddress", "Enter permanent address"),
      _textField("State", "Enter state"),
      _textField("City", "Enter city"),
      _textField("Pincode", "Enter 6-digit pincode"),
      _textField("AadhaarNo", "Enter Aadhaar number"),
      _fileField("AadharFrontPic"),
      _fileField("AadhaarBackPic"),
      _textField("PanNo", "Enter PAN number"),
      _fileField("PanPic"),
      _textField("Password", "Enter password", obscure: true),
    ];
  }

  Widget _textField(String key, String hint, {bool obscure = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _controllers[key],
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: AppConstants.fieldLabels[key],
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (v) =>
        v == null || v.isEmpty ? "Please enter ${AppConstants.fieldLabels[key]}" : null,
      ),
    );
  }

  Widget _fileField(String key) {
    final fileName = _files[key]?.path.split("/").last ?? "No file chosen";
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(fileName, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _pickImage(key),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.secondaryColor,
            ),
            child: const Text("Choose File"),
          ),
        ],
      ),
    );
  }
}
