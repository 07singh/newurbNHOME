import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/Model/profile_model.dart';
import '/service/profile_service.dart';

class ProfileScreenem extends StatefulWidget {
  final String? phone;
  final String? position;

  const ProfileScreenem({super.key, this.phone, this.position});

  @override
  State<ProfileScreenem> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreenem> {
  final _storage = const FlutterSecureStorage();
  final StaffProfileService _service = StaffProfileService();
  late Future<StaffProfileResponse> _futureProfile;

  @override
  void initState() {
    super.initState();
    _futureProfile = _loadProfile();
  }

  Future<StaffProfileResponse> _loadProfile() async {
    final phone = widget.phone ?? await _storage.read(key: 'user_mobile') ?? '';
    final position = widget.position ?? await _storage.read(key: 'user_role') ?? '';

    if (phone.isEmpty) throw Exception('Phone number not available');
    return _service.fetchProfile(phone: phone, position: position);
  }

  Future<void> _refresh() async {
    setState(() => _futureProfile = _loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white, // Black text color
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade400, // Yellow background
        foregroundColor: Colors.white, // Black for back button and icons
        elevation: 0,
      ),
      body: FutureBuilder<StaffProfileResponse>(
        future: _futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final staff = snapshot.data?.staff;
          if (staff == null) {
            return const Center(child: Text('No profile data found'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // 🔹 Profile Picture (API Image)
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(staff.fullProfilePicUrl),
                    onBackgroundImageError: (_, __) {},
                  ),
                ),
                const SizedBox(height: 16),

                // 🔹 Name & Position
                Center(
                  child: Text(
                    staff.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    staff.position,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ),

                const SizedBox(height: 25),

                // 🔹 Profile Info Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
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
                      _buildInfoRow('Status', staff.status ? 'Active' : 'Inactive'),
                      _divider(),
                      _buildInfoRow('Staff ID', staff.staffId),
                      _divider(),

                    ],
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

  Widget _divider() =>
      const Divider(height: 18, color: Colors.grey, thickness: 0.3);

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              (value != null && value.isNotEmpty) ? value : '-',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
