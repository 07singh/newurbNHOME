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

  @override
  void initState() {
    super.initState();
    _futureProfile = _service.fetchProfile(widget.phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Associate Profile"),
        backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder<AssociateProfile?>(
        future: _futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No profile found"));
          }

          final profile = snapshot.data!;
          final baseUrl = "https://realapp.cheenu.in";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: profile.profileImageUrl != null
                      ? NetworkImage(baseUrl + profile.profileImageUrl!)
                      : const AssetImage('assets/user.png') as ImageProvider,
                ),
                const SizedBox(height: 16),
                Text(profile.fullName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("ID: ${profile.associateId}"),
                const Divider(height: 30),

                _buildInfoTile("Phone", profile.phone),
                _buildInfoTile("Email", profile.email),
                _buildInfoTile("Address", profile.currentAddress),
                _buildInfoTile("City", profile.city),
                _buildInfoTile("State", profile.state),
                _buildInfoTile("Pincode", profile.pincode),
                _buildInfoTile("Aadhaar No", profile.aadhaarNo),
                _buildInfoTile("PAN No", profile.panNo),
                const SizedBox(height: 20),

              /*  const Text("Documents",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                const SizedBox(height: 10),

                _buildImageCard("Aadhaar Front", baseUrl + (profile.aadharFrontPic ?? '')),
                _buildImageCard("Aadhaar Back", baseUrl + (profile.aadharBackPic ?? '')),
                _buildImageCard("PAN Card", baseUrl + (profile.panPic ?? '')),*/
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildImageCard(String label, String imageUrl) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(title: Text(label)),
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
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
