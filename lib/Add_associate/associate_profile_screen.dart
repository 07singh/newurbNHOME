import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '/service/associate_profile_service.dart';
import '/Model/associate_profile_model.dart';

class AssociateProfileScreen extends StatefulWidget {
  final String phone;

  const AssociateProfileScreen({super.key, required this.phone});

  @override
  State<AssociateProfileScreen> createState() => _AssociateProfileScreenState();
}

class _AssociateProfileScreenState extends State<AssociateProfileScreen> {
  late Future<ProfileAssociate> _futureProfile;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _futureProfile = fetchAssociateProfile(widget.phone);
  }

  Future<void> _refresh() async {
    setState(() {
      _futureProfile = fetchAssociateProfile(widget.phone);
    });
  }

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
      body: FutureBuilder<ProfileAssociate>(
        future: _futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.data1 == null || snapshot.data!.data1!.isEmpty) {
            return const Center(child: Text('No profile data available'));
          }

          final profile = snapshot.data!.data1![0];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: [
                // Header Section – Blue
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 30),
                  color: Colors.blue.shade700,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Text(
                        "Associate Profile",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile Image Section – Dummy + Change Picture
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

                // Profile Info Card – Same Style
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Name', profile.fullName),
                        _buildInfoRow('Email', profile.email),
                        _buildInfoRow('Phone', profile.phone),
                        _buildInfoRow('Current Address', profile.currentAddress),
                        _buildInfoRow('Permanent Address', profile.permanentAddress),
                        _buildInfoRow('State', profile.state),
                        _buildInfoRow('City', profile.city),
                        _buildInfoRow('Pincode', profile.pincode),
                        _buildInfoRow('Aadhaar No', profile.aadhaarNo),
                        _buildInfoRow('PAN No', profile.panNo),
                        _buildInfoRow('Associate ID', profile.associateId),
                        _buildInfoRow('Status', profile.status == true ? 'Active' : 'Inactive'),
                        _buildInfoRow('Message', snapshot.data!.message),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Update Button – Blue
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        // Add update logic here if needed
                      },
                      child: const Text(
                        "Update",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}