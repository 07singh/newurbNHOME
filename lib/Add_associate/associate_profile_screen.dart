import 'package:flutter/material.dart';
import '/service/associate_profile_service.dart';
import '/Model/associate_profile_model.dart';

class AssociateProfileScreen extends StatefulWidget {
  final String phone;

  const AssociateProfileScreen({super.key, required this.phone});

  @override
  _AssociateProfileScreenState createState() => _AssociateProfileScreenState();
}

class _AssociateProfileScreenState extends State<AssociateProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Associate Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<ProfileAssociate>(
        future: fetchAssociateProfile(widget.phone),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${snapshot.error}')),
              );
            });
            return const Center(child: Text('Failed to load profile'));
          } else if (snapshot.hasData &&
              snapshot.data!.data1 != null &&
              snapshot.data!.data1!.isNotEmpty) {
            final profile = snapshot.data!.data1![0];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProfileField('Name', profile.fullName),
                    _buildProfileField('Email', profile.email),
                    _buildProfileField('Phone', profile.phone),
                    _buildProfileField('Current Address', profile.currentAddress),
                    _buildProfileField('Permanent Address', profile.permanentAddress?.toString()),
                    _buildProfileField('State', profile.state),
                    _buildProfileField('City', profile.city),
                    _buildProfileField('Pincode', profile.pincode),
                    _buildProfileField('Aadhaar No', profile.aadhaarNo),
                    _buildProfileField('PAN No', profile.panNo),
                    _buildProfileField('Associate ID', profile.associateId),
                    _buildProfileField('Status', profile.status == true ? 'Active' : 'Inactive'),
                    _buildProfileField('Message', snapshot.data!.message),
                  ],
                ),
              ),
            );
          }
          return const Center(child: Text('No profile data available'));
        },
      ),
    );
  }

  Widget _buildProfileField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.deepPurple,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}