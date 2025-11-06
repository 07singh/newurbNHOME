import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({Key? key}) : super(key: key);

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _joiningDateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedPosition;
  bool _agree = false;
  File? _imageFile;
  String? _base64Image;

  final List<String> _positions = [
    "Manager",
    "Sales Executive",
    "HR",
    "Accountant",

  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _joiningDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _selectJoiningDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _joiningDateController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _agree) {
      if (_base64Image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠ Please upload a profile picture")),
        );
        return;
      }


    // Example payload
    final employeeData = {
    "fullName": _fullNameController.text.trim(),
    "phone": _phoneController.text.trim(),
    "email": _emailController.text.trim(),
    "position": _selectedPosition,
    "joiningDate": _joiningDateController.text.trim(),
    "password": _passwordController.text.trim(),
    "profileImage": _base64Image,
    };

    print("🧾 Employee Data: $employeeData"); // Replace with API call

    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("✅ Staff added successfully!")),
    );
    } else if (!_agree) {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("⚠ Please check the agreement box.")),
    );
    }


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Staff",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFFFD700),
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
            key: _formKey,
            child: Column(
              children: [
// Profile Picture
              GestureDetector(
              onTap: _pickImage,
              child: Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.black54)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),


        _buildTextField("Full Name", _fullNameController, TextInputType.name),
        const SizedBox(height: 12),
        _buildTextField("Phone No", _phoneController, TextInputType.phone),
        const SizedBox(height: 12),
        _buildTextField("Email Address", _emailController, TextInputType.emailAddress),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _selectedPosition,
          decoration: const InputDecoration(
            labelText: "Position",
            border: OutlineInputBorder(),
          ),
          items: _positions
              .map((position) => DropdownMenuItem(
            value: position,
            child: Text(position),
          ))
              .toList(),
          onChanged: (value) => setState(() => _selectedPosition = value),
          validator: (value) => value == null ? 'Please select a position' : null,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _joiningDateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: "Joining Date (dd-mm-yyyy)",
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectJoiningDate(context),
            ),
          ),
          validator: (value) =>
          value == null || value.isEmpty ? 'Please enter joining date' : null,
        ),
        const SizedBox(height: 12),

        _buildTextField("Password", _passwordController, TextInputType.visiblePassword, isPassword: true),
        const SizedBox(height: 12),
        _buildTextField("Confirm Password", _confirmPasswordController, TextInputType.visiblePassword, isPassword: true),
        const SizedBox(height: 8),

        Row(
          children: [
            Checkbox(
              value: _agree,
              onChanged: (value) => setState(() => _agree = value!),
            ),
            const Text("Check me out", style: TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              "Add Employee",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        ],
      ),
    ),
    ),
    );


  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType type,
      {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Please enter $label";
        if (label == "Confirm Password" && value != _passwordController.text) {
          return "Passwords do not match";
        }
        return null;
      },
    );
  }
}
