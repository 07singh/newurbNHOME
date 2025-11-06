import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/Model/profile_model.dart';
import '/service/profile_service.dart';

class PScreen extends StatefulWidget {
  final String? phone;
  final String? position;

  const PScreen({super.key, this.phone, this.position});

  @override
  State<PScreen> createState() => _PScreenState();
}

class _PScreenState extends State<PScreen> {
  final _storage = const FlutterSecureStorage();
  final _service = ProfileService();
  late Future<ProfileResponse> _futureProfile;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _futureProfile = _loadProfile();
  }

  Future<ProfileResponse> _loadProfile() async {
    final phone = widget.phone ?? await _storage.read(key: 'user_mobile') ?? '';
    final position =
        widget.position ?? await _storage.read(key: 'user_role') ?? 'Director';

    if (phone.isEmpty) {
      throw Exception('Phone number not available');
    }

    return _service.fetchProfile(phone: phone, position: position);
  }

  Future<void> _refresh() async {
    setState(() {
      _futureProfile = _loadProfile();
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
      body: FutureBuilder<ProfileResponse>(
        future: _futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final profileResponse = snapshot.data!;
          if (profileResponse.data1.isEmpty) {
            return const Center(child: Text('No profile found'));
          }

          final user = profileResponse.data1.first;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: [
                // Header Section – YELLOW TO BLUE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                      top: 50, left: 16, right: 16, bottom: 30),
                  color: Colors.blue.shade700, // Changed from 0xFFFFD700
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile Image Section
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : const AssetImage('assets/download (1).jpeg')
                        as ImageProvider,
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

                // Profile Info Card
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
                        _buildInfoRow('ID', user.id?.toString()),
                        _buildInfoRow('Full Name', user.fullname),
                        _buildInfoRow('Phone', user.phone),
                        _buildInfoRow('Email', user.email),
                        _buildInfoRow('Position', user.position),
                        _buildInfoRow(
                          'Status',
                          user.status == true ? 'Active' : 'Inactive',
                        ),
                        _buildInfoRow('Staff Id', user.staffId?.toString()),
                        _buildInfoRow('Create Date', user.createDate),
                        _buildInfoRow('Joining Date', user.joiningDate),
                        _buildInfoRow('Login Date', user.loginDate),
                        _buildInfoRow('Login Out', user.loginOut),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Update Button – YELLOW TO BLUE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700, // Changed from 0xFFFFD700
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "Update",
                        style: TextStyle(
                          color: Colors.white, // Changed text to white for visibility
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
            width: 120,
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