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
  File? _pickedImage;
  bool _isUploading = false;

  String? _savedPhone;
  String? _savedPosition;
  String? _currentName;
  String? _currentPosition;

  @override
  void initState() {
    super.initState();
    _futureProfile = _loadProfile();
  }

  // ===================== LOAD PROFILE =====================
  Future<StaffProfileResponse> _loadProfile() async {
    _savedPhone = widget.phone ?? await _storage.read(key: 'user_mobile') ?? '';
    _savedPosition = widget.position ?? await _storage.read(key: 'user_role') ?? '';

    if (_savedPhone!.isEmpty) {
      throw Exception("Phone not found in storage");
    }

    final response = await _service.fetchProfile(
      phone: _savedPhone!,
      position: _savedPosition!,
    );

    _profileImageUrl = response.staff?.fullProfilePicUrl;
    _currentName = response.staff?.fullName;
    _currentPosition = response.staff?.position;

    return response;
  }

  Future<void> _refresh() async {
    setState(() => _futureProfile = _loadProfile());
  }

  // ===================== PICKER BOTTOM SHEET =====================
  void _openPickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Gallery"),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ===================== PICK IMAGE =====================
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);

    if (file != null) {
      // Auto-upload immediately after selecting image
      await _uploadProfilePic(File(file.path));
    }
  }

  // ===================== UPLOAD PROFILE PIC =====================
  Future<void> _uploadProfilePic(File imageFile) async {
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      return;
    }

    setState(() {
      _pickedImage = imageFile;
      _isUploading = true;
    });

    final uploaded = await _service.updateProfilePicture(
      phone: _savedPhone!,
      position: _savedPosition!,
      file: imageFile,
    );

    if (uploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully")),
      );

      setState(() {
        _pickedImage = null;
        _isUploading = false;
        _futureProfile = _loadProfile();
      });

      // Wait for profile to reload and then return updated image URL
      final updatedProfile = await _loadProfile();
      final updatedImageUrl = updatedProfile.staff?.fullProfilePicUrl;
      
      if (updatedImageUrl != null && mounted) {
        Navigator.pop(context, {
          'name': _currentName ?? '',
          'position': _currentPosition ?? '',
          'profileImageUrl': updatedImageUrl,
          'phone': _savedPhone ?? '',
        });
      }
    } else {
      setState(() {
        _pickedImage = null;
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload Failed")),
      );
    }
  }

  // Helper method to return profile data when navigating back
  void _returnProfileData() {
    if (_profileImageUrl != null) {
      Navigator.pop(context, {
        'name': _currentName ?? '',
        'position': _currentPosition ?? '',
        'profileImageUrl': _profileImageUrl,
        'phone': _savedPhone ?? '',
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _returnProfileData();
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Profile Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _returnProfileData,
        ),
      ),

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
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final staff = snapshot.data!.staff!;

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: h * 0.15,
                  color: Colors.deepPurple,
                ),

                Transform.translate(
                  offset: const Offset(0, -80),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _pickedImage != null
                                ? FileImage(_pickedImage!)
                                : NetworkImage(_profileImageUrl!) as ImageProvider,
                            child: _isUploading
                                ? Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  )
                                : null,
                          ),

                          if (!_isUploading)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _openPickerDialog,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black,
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      size: 20, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow("Full Name", staff.fullName),
                          _divider(),
                          _buildInfoRow("Phone", staff.phone),
                          _divider(),
                          _buildInfoRow("Email", staff.email),
                          _divider(),
                          _buildInfoRow("Position", staff.position),
                          _divider(),
                          _buildInfoRow("Status", staff.status ? "Active" : "Inactive"),
                          _divider(),
                          _buildInfoRow("Staff ID", staff.staffId),
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value ?? '-',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(thickness: 0.3);
}
