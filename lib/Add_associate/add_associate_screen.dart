import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:convert';
import 'dart:io';

class AppConstants {
  static const Color primaryColor = Color(0xFFFBE50A);
  static const Color secondaryColor = Color(0xFFFBE50A);

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
    "ProjectName": "Project Name",
    "Commission": "Commission (Rs)",
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
  String? _selectedProject;

  final List<String> _projects = [
    "Defence Phase 2",
    "Green Residency Phase 2",
  ];

  final List<String> _indianStates = [
    'Andhra Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Delhi', 'Goa', 'Gujarat',
    'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala',
    'Madhya Pradesh', 'Maharashtra', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim',
    'Tamil Nadu', 'Telangana', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
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

      final targetPath =
          "${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 60,
      );

      if (compressed == null) return;

      final bytes = await File(compressed.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() {
        _files[key] = File(compressed.path);
        _base64[key] = base64Image;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking file: $e")),
      );
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    for (var key in _base64.keys) {
      if (_base64[key] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please upload ${AppConstants.fileLabels[key]}")),
        );
        return;
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Success"),
        content: const Text("Form Submitted (no API used)."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Associate", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFD700),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _profilePicField(),
                  const SizedBox(height: 20),

                  ..._inputFields(),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Submit", style: TextStyle(color: Colors.black)),
                  ),
                ],
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
      _textField("CurrentAddress", "Enter address"),

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

      _textField("PermanentAddress", "Enter address"),

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
        validator: (v) => v == null ? "Please select state" : null,
      ),

      const SizedBox(height: 14),

      _textField("City", "Enter city"),
      _textField("Pincode", "Enter pincode"),
      _textField("AadhaarNo", "Enter Aadhaar"),
      _fileField("AadharFrontPic", label: "Upload Aadhaar Front"),
      _fileField("AadhaarBackPic", label: "Upload Aadhaar Back"),
      _textField("PanNo", "Enter PAN"),
      _fileField("PanPic", label: "Upload PAN Card"),

      // ✔ Replaced textfield → dropdown for project
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "Project Name",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        value: _selectedProject,
        items: _projects
            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
            .toList(),
        onChanged: (val) {
          setState(() {
            _selectedProject = val!;
            _controllers["ProjectName"]!.text = val;
          });
        },
        validator: (v) => v == null ? "Please select project" : null,
      ),

      const SizedBox(height: 14),

      _textField("Commission", "Enter commission (Rs)"),
      _textField("Password", "Enter password", obscure: true),
    ];
  }

  Widget _fileField(String key, {required String label}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ElevatedButton.icon(
        onPressed: () => _pickImage(key),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.secondaryColor,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.upload_file, color: Colors.black),
        label: Text(label, style: const TextStyle(color: Colors.black)),
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
        validator: (v) => v == null || v.isEmpty
            ? "Please enter ${AppConstants.fieldLabels[key]}"
            : null,
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
        const Text("Upload Profile Picture"),
      ],
    );
  }
}