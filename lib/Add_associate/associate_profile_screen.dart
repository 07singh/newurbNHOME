import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '/Model/associate_profile_model.dart';
import '/service/associate_profile_service.dart';
import '/service/associateProfileChangeService.dart';

class AssociateProfileScreen extends StatefulWidget {
  final String phone;
  const AssociateProfileScreen({super.key, required this.phone});

  @override
  State<AssociateProfileScreen> createState() => _AssociateProfileScreenState();
}

class _AssociateProfileScreenState extends State<AssociateProfileScreen> {
  final AssociateProfileService _profileService = AssociateProfileService();
  final AssociateProfileChangeService _changeService = AssociateProfileChangeService();
  final ImagePicker _imagePicker = ImagePicker();

  late Future<AssociateProfile?> _futureProfile;
  String? _profileImageUrl;
  File? _selectedImage;
  bool _isUploading = false;

  static const TextStyle _phoneTextStyle = TextStyle(
    fontWeight: FontWeight.w600,
    color: Colors.blue,
    fontSize: 15,
  );
  static const double _avatarRadius = 65;

  @override
  void initState() {
    super.initState();
    _futureProfile = _loadProfile();
  }

  Future<AssociateProfile?> _loadProfile() async {
    try {
      final response = await _profileService.fetchProfile(widget.phone);
      if (response != null) {
        _profileImageUrl = "https://realapp.cheenu.in${response.profileImageUrl ?? ''}";
      }
      return response;
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _futureProfile = _loadProfile();
      _selectedImage = null;
    });
  }

  Future<void> _showImageSourceDialog() async {
    if (_isUploading) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Change Profile Picture"),
          content: const Text("Choose image source"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            _buildDialogButton("Camera", Icons.camera_alt, () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            }),
            _buildDialogButton("Gallery", Icons.photo_library, () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            }),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogButton(String text, IconData icon, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(text),
      style: TextButton.styleFrom(
        foregroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 850,
        maxHeight: 850,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _uploadImage(File(pickedFile.path));
      }
    } catch (e) {
      _showSnackBar("Failed to pick image: ${e.toString()}");
    }
  }

  Future<void> _uploadImage(File image) async {
    setState(() => _isUploading = true);

    try {
      final response = await _changeService.changeProfileImage(widget.phone, image);

      if (response.status == "Success") {
        setState(() {
          _selectedImage = image;
          _profileImageUrl = null;
        });
        _showSnackBar(response.message);
        await _refresh();
      } else {
        _showSnackBar("Failed: ${response.message}");
      }
    } catch (e) {
      _showSnackBar("Upload failed: ${e.toString()}");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text(
          "Associate Profile",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<AssociateProfile?>(
        future: _futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          final profile = snapshot.data;
          if (profile == null) {
            return _buildErrorWidget("No profile data found");
          }

          return _buildProfileContent(profile, h);
        },
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 64),
            const SizedBox(height: 16),
            Text(
              "Something went wrong",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(AssociateProfile profile, double height) {
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(profile, height),
              const SizedBox(height: 70),
              _buildDetailsCard(profile),
              const SizedBox(height: 20),
            ],
          ),
        ),
        if (_isUploading) _buildUploadingOverlay(),
      ],
    );
  }

  Widget _buildProfileHeader(AssociateProfile profile, double height) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: height * 0.15,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        Positioned(
          top: height * 0.15 - (_avatarRadius + 10),
          left: 0,
          right: 0,
          child: Column(
            children: [
              _buildProfileAvatar(),
              const SizedBox(height: 16),
              Text(
                "ID: ${profile.associateId}",
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ===========================
  /// UPDATED AVATAR (ONLY CAMERA ICON CLICKABLE)
  /// ===========================
  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        // Profile Avatar (NOT clickable)
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: _avatarRadius,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _getProfileImage(),
            child: _isUploading
                ? Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            )
                : null,
          ),
        ),

        // Camera Icon (ONLY clickable area)
        if (!_isUploading)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImageSourceDialog, // Only camera icon opens dialog
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }


  Widget _buildDetailsCard(AssociateProfile profile) {
    final infoItems = [
      _InfoItem("Phone", profile.phone),
      _InfoItem("Email", profile.email),
      _InfoItem("Address", profile.currentAddress),
      _InfoItem("City", profile.city),
      _InfoItem("State", profile.state),
      _InfoItem("Pincode", profile.pincode),
      _InfoItem("Aadhaar No", profile.aadhaarNo),
      _InfoItem("PAN No", profile.panNo),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                "Personal Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              ...infoItems.map((item) => Column(
                children: [
                  _buildInfoRow(item.label, item.value),
                  if (item != infoItems.last) _divider(),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)),
            SizedBox(height: 16),
            Text(
              "Updating Profile...",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    } else {
      return const AssetImage('assets/user.png');
    }
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: _isPhoneLabel(label) && value != null && value.isNotEmpty
                ? _buildPhoneText(value, TextAlign.right)
                : Text(
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

  bool _isPhoneLabel(String label) {
    return label.toLowerCase().contains('phone') ||
        label.toLowerCase().contains('contact');
  }

  Widget _buildPhoneText(String phone, TextAlign align) {
    final trimmedPhone = phone.trim();
    if (trimmedPhone.isEmpty) {
      return Text(
        phone,
        textAlign: align,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 15,
        ),
      );
    }

    return InkWell(
      onTap: () => _callPhoneNumber(trimmedPhone),
      child: Text(
        trimmedPhone,
        textAlign: align,
        style: _phoneTextStyle,
      ),
    );
  }

  Future<void> _callPhoneNumber(String phone) async {
    final sanitizedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (sanitizedPhone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
        ),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: sanitizedPhone);
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to initiate call to $phone'),
        ),
      );
    }
  }

  Widget _divider() {
    return Divider(
      color: Colors.grey.shade300,
      thickness: 1,
      height: 1,
    );
  }
}

class _InfoItem {
  final String label;
  final String? value;

  _InfoItem(this.label, this.value);
}
