import 'dart:io';
import 'package:flutter/material.dart';
import '/Model/associate_profile_model.dart';
import '/service/associate_profile_service.dart';

class AssociateProfileScreen extends StatefulWidget {
  final String phone;
  const AssociateProfileScreen({super.key, required this.phone});

  @override
  State<AssociateProfileScreen> createState() => _AssociateProfileScreenState();
}

class _AssociateProfileScreenState extends State<AssociateProfileScreen> {
  final AssociateProfileService _service = AssociateProfileService();
  late Future<AssociateProfile?> _futureProfile;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _futureProfile = _loadProfile();
  }

  Future<AssociateProfile?> _loadProfile() async {
    final response = await _service.fetchProfile(widget.phone);
    if (response != null) {
      _profileImageUrl = "https://realapp.cheenu.in${response.profileImageUrl ?? ''}";
    }
    return response;
  }

  Future<void> _refresh() async {
    setState(() => _futureProfile = _loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<AssociateProfile?>(
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
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    "Something went wrong",
                    style: const TextStyle(color: Colors.deepPurple),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refresh,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text("No profile data found"));
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
                                "Associate Profile",
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
                      bottom: -105
                      ,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                  ? NetworkImage(_profileImageUrl!)
                                  : const AssetImage('assets/user.png') as ImageProvider,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ID: ${profile.associateId}",
                            style: const TextStyle(color: Colors.black54, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 90),

                // ===== Details Card =====
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow("Phone", profile.phone),
                          _divider(),
                          _buildInfoRow("Email", profile.email),
                          _divider(),
                          _buildInfoRow("Address", profile.currentAddress),
                          _divider(),
                          _buildInfoRow("City", profile.city),
                          _divider(),
                          _buildInfoRow("State", profile.state),
                          _divider(),
                          _buildInfoRow("Pincode", profile.pincode),
                          _divider(),
                          _buildInfoRow("Aadhaar No", profile.aadhaarNo),
                          _divider(),
                          _buildInfoRow("PAN No", profile.panNo),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ===== Documents Section (Optional) =====





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
    return const Divider(color: Colors.grey, thickness: 0.3, height: 4);
  }

  Widget _buildImageCard(String label, String? imagePath) {
    final fullUrl = imagePath != null && imagePath.isNotEmpty
        ? "https://realapp.cheenu.in$imagePath"
        : "";

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(title: Text(label)),
          if (fullUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Image.network(fullUrl,
                  height: 180, width: double.infinity, fit: BoxFit.cover),
            )
          else
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text("No image uploaded"),
            ),
        ],
      ),
    );
  }
}