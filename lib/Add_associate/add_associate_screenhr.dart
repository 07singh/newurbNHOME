import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/services.dart';
import 'package:testsd_app/service/add_associate_service.dart';
import 'dart:convert';
import 'dart:io';

class AppConstants {
  static const Color primaryColor = Color(0xFF3371F4);
  static const Color secondaryColor = Color(0xFF3371F4);

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
  bool _isSubmitting = false;

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
  final AddAssociateService _associateService = AddAssociateService();

  // Multi-project selection
  final List<String> _projects = [
    "Defence Phase 2",
    "Green Residency Phase 2",
  ];
  List<String> _selectedProjects = [];

  // Commission controller for each project
  final Map<String, TextEditingController> _commissionControllers = {};

  final List<String> _indianStates = [
    'Andhra Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Delhi', 'Goa', 'Gujarat',
    'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala',
    'Madhya Pradesh', 'Maharashtra', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim',
    'Tamil Nadu', 'Telangana', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal','Jammu& kashmir'
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

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              "${AppConstants.fileLabels[key] ?? 'Image'} uploaded successfully",
            ),
          ),
        );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking file: $e")),
      );
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedProjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one project")),
      );
      return;
    }

    // Check all file uploads
    for (var key in _base64.keys) {
      if (_base64[key] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please upload ${AppConstants.fileLabels[key]}")),
        );
        return;
      }
    }

    // Check commissions for selected projects
    for (var project in _selectedProjects) {
      if (_commissionControllers[project] == null || _commissionControllers[project]!.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter commission for $project")),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = _buildPayload();
      final response = await _associateService.submitAssociate(payload);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back to dashboard after a short delay
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Pop back to dashboard (DirectLoginPage)
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to submit: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Associate", style: TextStyle(color: Colors.white,fontWeight: FontWeight.w700,)),
        centerTitle: true,
        backgroundColor: const Color(0xFF3371F4),
        iconTheme: const IconThemeData(color: Colors.white),
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
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                        : const Text("Submit", style: TextStyle(color: Colors.white)),
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
      const SizedBox(height: 10),
      _projectsField(), // Projects + per-project commissions
      const SizedBox(height: 14),
      _textField("Password", "Enter password", obscure: true),
    ];
  }

  Widget _projectsField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Projects", style: TextStyle(fontWeight: FontWeight.bold)),
          ..._projects.map((project) {
            // Ensure controller exists
            _commissionControllers.putIfAbsent(project, () => TextEditingController());

            return Column(
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(project),
                  value: _selectedProjects.contains(project),
                  onChanged: (bool? val) {
                    setState(() {
                      if (val == true) {
                        _selectedProjects.add(project);
                      } else {
                        _selectedProjects.remove(project);
                        _commissionControllers[project]!.clear();
                      }
                    });
                  },
                ),
                if (_selectedProjects.contains(project))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextFormField(
                      controller: _commissionControllers[project],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Commission for $project (Rs)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) {
                        if (_selectedProjects.contains(project) && (v == null || v.isEmpty)) {
                          return "Enter commission for $project";
                        }
                        return null;
                      },
                    ),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
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
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Map<String, dynamic> _buildPayload() {
    final Map<String, dynamic> payload = {
      "FullName": _controllers["FullName"]!.text.trim(),
      "Phone": _controllers["Phone"]!.text.trim(),
      "Email": _controllers["Email"]!.text.trim(),
      "CurrentAddress": _controllers["CurrentAddress"]!.text.trim(),
      "PermanentAddress": _controllers["PermanentAddress"]!.text.trim(),
      "State": _selectedState,
      "City": _controllers["City"]!.text.trim(),
      "Pincode": _controllers["Pincode"]!.text.trim(),
      "AadhaarNo": _controllers["AadhaarNo"]!.text.trim(),
      "PanNo": _controllers["PanNo"]!.text.trim(),
      "Password": _controllers["Password"]!.text.trim(),
      "Status": true,
      "AssociateId": "",
      "CreateDate": DateTime.now().toIso8601String(),
      "JoiningDate": DateTime.now().toIso8601String(),
      "LoginDate": null,
      "LogoutDate": null,
      "AadharFrontPic": _base64["AadharFrontPic"],
      "AadhaarBackPic": _base64["AadhaarBackPic"],
      "PanPic": _base64["PanPic"],
      "Profile_Pic": _base64["ProfilePic"],
    };

    final commissionValues = _selectedProjects
        .map((project) => _parseCommissionValue(_commissionControllers[project]?.text))
        .whereType<num>()
        .toList();
    final totalCommission = commissionValues.fold<num>(0, (sum, value) => sum + value);
    payload["CommissionReceived"] = totalCommission;

    for (var i = 0; i < _selectedProjects.length; i++) {
      final index = i + 1;
      final project = _selectedProjects[i];
      payload["ProjectName$index"] = project;

      final commission = _parseCommissionValue(_commissionControllers[project]?.text);
      if (commission != null) {
        final key = "CommissionProject$index";
        payload[key] = commission;
        if (index == 2) {
          payload["commissionProject$index"] = commission;
        }
      }
    }

    return payload;
  }

  num? _parseCommissionValue(String? value) {
    final sanitized = value?.trim();
    if (sanitized == null || sanitized.isEmpty) return null;
    final integerValue = int.tryParse(sanitized);
    if (integerValue != null) return integerValue;
    final doubleValue = double.tryParse(sanitized);
    return doubleValue;
  }

  Widget _textField(String key, String hint, {bool obscure = false}) {
    final isPhoneField = key == "Phone";
    final isAadhaarField = key == "AadhaarNo";
    final isPanField = key == "PanNo";
    final isPincodeField = key == "Pincode";
    final isCurrentAddress = key == "CurrentAddress";
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _controllers[key],
        obscureText: obscure,
        keyboardType: (isPhoneField || isAadhaarField || isPincodeField)
            ? TextInputType.number
            : (obscure ? TextInputType.visiblePassword : TextInputType.text),
        inputFormatters: [
          if (isPhoneField || isAadhaarField || isPincodeField)
            FilteringTextInputFormatter.digitsOnly,
          if (isPhoneField) LengthLimitingTextInputFormatter(10),
          if (isAadhaarField) LengthLimitingTextInputFormatter(12),
          if (isPincodeField) LengthLimitingTextInputFormatter(6),
        ],
        onChanged: (value) {
          if (key == "FullName" && value.isNotEmpty) {
            final formatted = _capitalizeName(value);
            if (formatted != value) {
              _controllers[key]!.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          }
          if (isPanField && value.isNotEmpty) {
            final upper = value.toUpperCase();
            if (upper != value) {
              _controllers[key]!.value = TextEditingValue(
                text: upper,
                selection: TextSelection.collapsed(offset: upper.length),
              );
            }
          }
        },
        decoration: InputDecoration(
          labelText: AppConstants.fieldLabels[key],
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return "Please enter ${AppConstants.fieldLabels[key]}";
          }
          final value = v.trim();
          if (key == "FullName") {
            if (!_startsWithCapital(value)) {
              return "Full Name must start with a capital letter";
            }
          }
          if (isCurrentAddress) {
            if (!_hasMaxWordCount(value, 30)) {
              return "Current Address must be within 30 words";
            }
          }
          if (isPhoneField) {
            if (value.length != 10) {
              return "Phone number must be exactly 10 digits";
            }
          }
          if (isAadhaarField) {
            if (value.length != 12) {
              return "Aadhaar number must be exactly 12 digits";
            }
          }
          if (isPanField) {
            if (!_isValidPan(value)) {
              return "PAN number must be 10 characters (e.g., ABCDE1234F)";
            }
          }
          if (isPincodeField) {
            if (value.length != 6) {
              return "Pincode must be exactly 6 digits";
            }
          }
          if (key == "Email") {
            if (!_isValidEmail(value)) {
              return "Please enter a valid email address";
            }
          }
          return null;
        },
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
                ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        const Text("Upload Profile Picture"),
      ],
    );
  }

  String _capitalizeName(String value) {
    if (value.isEmpty) return value;
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    final words = cleaned.split(' ');
    final capitalized = words
        .map((word) => word.isEmpty
        ? word
        : word[0].toUpperCase() + (word.length > 1 ? word.substring(1) : ''))
        .join(' ');
    return capitalized;
  }

  bool _startsWithCapital(String value) {
    if (value.isEmpty) return false;
    return RegExp(r'^[A-Z]').hasMatch(value);
  }

  bool _hasMaxWordCount(String value, int maxWords) {
    final words = value.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.length <= maxWords;
  }

  bool _isValidPan(String value) {
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
    return panRegex.hasMatch(value);
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    return emailRegex.hasMatch(value);
  }
}