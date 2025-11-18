import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddHrNotificationPage extends StatefulWidget {
  const AddHrNotificationPage({super.key});

  @override
  State<AddHrNotificationPage> createState() => _AddHrNotificationPageState();
}

class _AddHrNotificationPageState extends State<AddHrNotificationPage> {
  int _currentSection = 0; // 0 for All, 1 for Individual
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers for All section
  final TextEditingController _allNameController = TextEditingController();
  final TextEditingController _allTitleController = TextEditingController();
  final TextEditingController _allMessageController = TextEditingController();

  // Form controllers for Individual section
  final TextEditingController _individualMobileController = TextEditingController();
  final TextEditingController _individualNameController = TextEditingController();
  final TextEditingController _individualTitleController = TextEditingController();
  final TextEditingController _individualMessageController = TextEditingController();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submitForm() {
    if (_currentSection == 0) {
      // All section validation
      if (_allNameController.text.isEmpty ||
          _allTitleController.text.isEmpty ||
          _allMessageController.text.isEmpty) {
        _showSnackBar('Please fill all required fields');
        return;
      }

      // Process All notification
      _showSnackBar('Notification sent to All users successfully!');
      _resetAllForm();

    } else {
      // Individual section validation
      if (_individualMobileController.text.isEmpty ||
          _individualNameController.text.isEmpty ||
          _individualTitleController.text.isEmpty ||
          _individualMessageController.text.isEmpty) {
        _showSnackBar('Please fill all required fields');
        return;
      }

      // Process Individual notification
      _showSnackBar('Notification sent to Individual successfully!');
      _resetIndividualForm();
    }
  }

  void _resetAllForm() {
    _allNameController.clear();
    _allTitleController.clear();
    _allMessageController.clear();
    _removeImage();
  }

  void _resetIndividualForm() {
    _individualMobileController.clear();
    _individualNameController.clear();
    _individualTitleController.clear();
    _individualMessageController.clear();
    _removeImage();
  }

  @override
  void dispose() {
    _allNameController.dispose();
    _allTitleController.dispose();
    _allMessageController.dispose();
    _individualMobileController.dispose();
    _individualNameController.dispose();
    _individualTitleController.dispose();
    _individualMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Send Notification',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(width * 0.04),
        child: Column(
          children: [
            // Section Toggle Buttons
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSectionButton(
                      title: 'All Users',
                      isSelected: _currentSection == 0,
                      onTap: () {
                        setState(() {
                          _currentSection = 0;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildSectionButton(
                      title: 'Individual',
                      isSelected: _currentSection == 1,
                      onTap: () {
                        setState(() {
                          _currentSection = 1;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: height * 0.03),

            // Form Section
            Expanded(
              child: SingleChildScrollView(
                child: _currentSection == 0 ? _buildAllSection() : _buildIndividualSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAllSection() {
    final width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Text(
          'Send notification to all users',
          style: GoogleFonts.poppins(
            fontSize: width * 0.04,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 20),

        // Name Field
        _buildTextField(
          controller: _allNameController,
          label: 'Name *',
          hintText: 'Enter name',
          icon: Icons.person,
        ),
        SizedBox(height: 16),

        // Title Field
        _buildTextField(
          controller: _allTitleController,
          label: 'Title *',
          hintText: 'Enter notification title',
          icon: Icons.title,
        ),
        SizedBox(height: 16),

        // Message Field
        _buildMessageField(
          controller: _allMessageController,
          label: 'Message *',
          hintText: 'Enter notification message',
        ),
        SizedBox(height: 16),

        // Image Upload Section
        _buildImageUploadSection(),
        SizedBox(height: 30),

        // Submit Button
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildIndividualSection() {
    final width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Text(
          'Send notification to individual user',
          style: GoogleFonts.poppins(
            fontSize: width * 0.04,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 20),

        // Mobile Number Field
        _buildTextField(
          controller: _individualMobileController,
          label: 'Mobile Number *',
          hintText: 'Enter mobile number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 16),

        // Name Field
        _buildTextField(
          controller: _individualNameController,
          label: 'Name *',
          hintText: 'Enter name',
          icon: Icons.person,
        ),
        SizedBox(height: 16),

        // Title Field
        _buildTextField(
          controller: _individualTitleController,
          label: 'Title *',
          hintText: 'Enter notification title',
          icon: Icons.title,
        ),
        SizedBox(height: 16),

        // Message Field
        _buildMessageField(
          controller: _individualMessageController,
          label: 'Message *',
          hintText: 'Enter notification message',
        ),
        SizedBox(height: 16),

        // Image Upload Section
        _buildImageUploadSection(),
        SizedBox(height: 30),

        // Submit Button
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(icon, color: Colors.blue[700]),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageField({
    required TextEditingController controller,
    required String label,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Image (Optional)',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        _selectedImage == null
            ? Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[400]!,
              width: 1.5,
              style: BorderStyle.solid, // Changed from dashed to solid
            ),
          ),
          child: TextButton(
            onPressed: _pickImage,
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: Colors.grey[500]
                ),
                SizedBox(height: 8),
                Text(
                  'Tap to upload image',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'PNG, JPG, JPEG supported',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        )
            : Stack(
          children: [
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                ),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.white),
                  padding: EdgeInsets.zero,
                  onPressed: _removeImage,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          'Send Notification',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
