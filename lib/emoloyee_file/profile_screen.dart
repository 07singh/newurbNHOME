import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '/Model/profile_model.dart';
import '/service/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? phone;
  final String? position;

  const ProfileScreen({super.key, this.phone, this.position});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  final StaffProfileService _service = StaffProfileService();

  late Future<StaffProfileResponse> _futureProfile;

  String? _profileImageUrl;
  File? _pickedImage;

  String? _savedPhone;
  String? _savedPosition;

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
      setState(() => _pickedImage = File(file.path));
    }
  }

  // ===================== UPLOAD PROFILE PIC =====================
  Future<void> _uploadProfilePic() async {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Uploading...")),
    );

    final uploaded = await _service.updateProfilePicture(
      phone: _savedPhone!,
      position: _savedPosition!,
      file: _pickedImage,
    );

    if (uploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully")),
      );

      setState(() {
        _pickedImage = null;
        _futureProfile = _loadProfile();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload Failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Profile Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
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
                  color: Colors.yellow,
                ),

                Transform.translate(
                  offset: const Offset(0, -60),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _pickedImage != null
                                ? FileImage(_pickedImage!)
                                : NetworkImage(_profileImageUrl!) as ImageProvider,
                          ),

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

                      const SizedBox(height: 10),

                      if (_pickedImage != null)
                        ElevatedButton(
                          onPressed: _uploadProfilePic,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text("Update Picture"),
                        )
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
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
