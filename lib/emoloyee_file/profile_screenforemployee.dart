import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '/Model/profile_model.dart';
import '/service/profile_service.dart';

class ProfileScreenem extends StatefulWidget {
  final String? phone;
  final String? position;

  const ProfileScreenem({super.key, this.phone, this.position});

  @override
  State<ProfileScreenem> createState() => _ProfileScreenemState();
}

class _ProfileScreenemState extends State<ProfileScreenem> {
  final _storage = const FlutterSecureStorage();
  final StaffProfileService _service = StaffProfileService();
  late Future<StaffProfileResponse> _futureProfile;

  String? _profileImageUrl;
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    _futureProfile = _loadProfile();
  }

  Future<StaffProfileResponse> _loadProfile() async {
    final phone = widget.phone ?? await _storage.read(key: 'user_mobile') ?? '';
    final position = widget.position ?? await _storage.read(key: 'user_role') ?? '';

    if (phone.isEmpty) throw Exception('Phone number not available');
    final response = await _service.fetchProfile(phone: phone, position: position);
    if (response.staff != null) {
      _profileImageUrl = response.staff!.fullProfilePicUrl;
    }
    return response;
  }

  Future<void> _refresh() async => setState(() => _futureProfile = _loadProfile());

  Future<void> _changePicture() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _localImagePath = image.path);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<StaffProfileResponse>(
        future: _futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.deepPurple)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          final staff = snapshot.data?.staff;
          if (staff == null) {
            return const Center(child: Text('No profile data found'));
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ===== Header =====
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: h * 0.22,
                      width: double.infinity,
                      color: Colors.deepPurple,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Text(
                                "Profile Details",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ===== Profile Picture =====
                    Positioned(
                      bottom: -75,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _changePicture,
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage: _localImagePath != null
                                    ? FileImage(File(_localImagePath!))
                                    : (_profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : const AssetImage('assets/profile_placeholder.png'))
                                as ImageProvider,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _changePicture,
                            child: const Text(
                              "Change Picture",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 80),

                // ===== Card Section =====
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow('Full Name', staff.fullName),
                          _divider(),
                          _buildInfoRow('Phone', staff.phone),
                          _divider(),
                          _buildInfoRow('Email', staff.email),
                          _divider(),
                          _buildInfoRow('Position', staff.position),
                          _divider(),
                          _buildInfoRow(
                            'Status',
                            staff.status ? 'Active' : 'Inactive',
                          ),
                          _divider(),
                          _buildInfoRow('Staff ID', staff.staffId.toString()),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===== Helper Widgets =====
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value ?? '-',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      color: Colors.grey,
      thickness: 0.3,
      height: 4,
    );
  }
}