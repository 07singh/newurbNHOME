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
import '/Model/add_staff_list.dart'; // ✅ Replace with your AssociateListScreen import if needed
import '/service/add_staff_list_service.dart'; // example
import'/Add_associate/add_associate_list_screen.dart';

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

  final Map<String, TextEditingController> _controllers = {
    for (var key in AppConstants.fieldLabels.keys) key: TextEditingController(),
  };

  final Map<String, File?> _files = {
    for (var key in AppConstants.fileLabels.keys) key: null,
  };

  final Map<String, String?> _base64 = {
    for (var key in AppConstants.fileLabels.keys) key: null,
  };

  String? _selectedState;

  final List<String> _indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Puducherry',
    'Jammu and Kashmir',
    'Ladakh'
  ];

  Future<void> _pickImage(String key) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final file = File(filePath);

      final fileSize = await file.length();
      if (fileSize > AppConstants.maxFileSizeBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠ File size exceeds 5MB limit")),
        );
        return;
      }

      final targetPath =
          "${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 60,
      );

      if (compressedXFile == null) return;

      final compressedFile = File(compressedXFile.path);
      final bytes = await compressedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() {
        _files[key] = compressedFile;
        _base64[key] = base64Image;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${AppConstants.fileLabels[key]} uploaded ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠ Error picking file: $e")),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
        "State": _selectedState ?? "",
        "City": _controllers["City"]!.text.trim(),
        "Pincode": _controllers["Pincode"]!.text.trim(),
        "AadhaarNo": _controllers["AadhaarNo"]!.text.trim(),
        "PanNo": _controllers["PanNo"]!.text.trim(),
        "AadharFrontPic": _base64["AadharFrontPic"],
        "AadhaarBackPic": _base64["AadhaarBackPic"],
        "PanPic": _base64["PanPic"],
        "Password": _controllers["Password"]!.text.trim(),
        "Profile_Pic": _base64["ProfilePic"],
        "Status": true,
        "AssociateId": "AS${DateTime.now().millisecondsSinceEpoch % 100000}",
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
      _showDialog("⚠ Error", "Something went wrong: $e");
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
                // ✅ After success → Navigate to AssociateListScreen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AssociateListScreen()),
                );
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
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "State",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        value: _selectedState,
        items: _indianStates
            .map((state) => DropdownMenuItem(value: state, child: Text(state)))
            .toList(),
        onChanged: (val) => setState(() => _selectedState = val),
        validator: (v) => v == null ? "Please select a state" : null,
      ),
      const SizedBox(height: 14),
      _textField("City", "Enter city"),
      _textField("Pincode", "Enter 6-digit pincode"),
      _textField("AadhaarNo", "Enter Aadhaar number"),
      _fileField("AadharFrontPic", label: "Upload Aadhaar Front"),
      _fileField("AadhaarBackPic", label: "Upload Aadhaar Back"),
      _textField("PanNo", "Enter PAN number"),
      _fileField("PanPic", label: "Upload PAN Card"),
      _textField("Password", "Enter password", obscure: true),
    ];
  }

  Widget _fileField(String key, {required String label}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _pickImage(key),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.secondaryColor,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
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
}