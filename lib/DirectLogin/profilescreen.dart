import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ttProfileScreen extends StatefulWidget {
  const ttProfileScreen({super.key});

  @override
  State<ttProfileScreen> createState() => _ttProfileScreenState();
}

class _ttProfileScreenState extends State<ttProfileScreen> {
  File? _imageFile;

  final _usernameController = TextEditingController(text: "yANCHUI");
  final _emailController = TextEditingController(text: "yanchui@gmail.com");
  final _phoneController = TextEditingController(text: "+14987889999");
  final _passwordController = TextEditingController(text: "evFTbyVVCd");

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 30),
            color: const Color(0xFFFFD700),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.share_outlined, color: Colors.white),
                ),
              ],
            ),
          ),

          // Profile image
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : const AssetImage('assets/download (1).jpeg') as ImageProvider,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: const Text(
                    "Change Picture",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Text fields
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("Username"),
                _buildTextField(_usernameController),
                const SizedBox(height: 15),
                _buildLabel("Email I'd"),
                _buildTextField(_emailController),
                const SizedBox(height: 15),
                _buildLabel("Phone Number"),
                _buildTextField(_phoneController),
                const SizedBox(height: 15),
                _buildLabel("Password"),
                _buildTextField(_passwordController),
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Update",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.black26),
        ),
      ),
    );
  }
}
