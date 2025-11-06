import 'dart:convert';
import 'package:flutter/material.dart';
import '/service/associate_list_service.dart';
import '/Model/associate_list_model.dart';

class AssociateCardScreen extends StatefulWidget {
  const AssociateCardScreen({Key? key}) : super(key: key);

  @override
  State<AssociateCardScreen> createState() => _AssociateCardScreenState();
}

class _AssociateCardScreenState extends State<AssociateCardScreen> {
  final AssociateService _associateService = AssociateService();
  late Future<AssociateList> _futureAssociates;

  final String imageBaseUrl = "https://realapp.cheenu.in/Upload/AssociateImage/";

  @override
  void initState() {
    super.initState();
    _futureAssociates = _associateService.fetchAssociateList(phone: '');
  }

  ImageProvider _getProfileImage(AssociateData associate) {
    try {
      if (associate.photoBase64 != null && associate.photoBase64!.isNotEmpty) {
        return MemoryImage(base64Decode(associate.photoBase64!));
      } else if (associate.profilePic != null && associate.profilePic!.isNotEmpty) {
        final fullUrl = "$imageBaseUrl${associate.profilePic}";
        return NetworkImage(fullUrl);
      } else {
        return const AssetImage('assets/default_profile.png');
      }
    } catch (_) {
      return const AssetImage('assets/default_profile.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Associate List'),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<AssociateList>(
        future: _futureAssociates,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '❌ Error loading associates:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.data == null || snapshot.data!.data!.isEmpty) {
            return const Center(
              child: Text(
                'No associates found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final associates = snapshot.data!.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: associates.length,
            itemBuilder: (context, index) {
              final associate = associates[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Profile Image
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                          image: DecorationImage(
                            image: _getProfileImage(associate),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // ✅ Associate Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              associate.fullName ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text('📱 ${associate.phone ?? 'N/A'}', style: const TextStyle(fontSize: 13)),
                            Text('✉️ ${associate.email ?? 'N/A'}', style: const TextStyle(fontSize: 13)),
                            Text('🏙️ ${associate.city ?? 'N/A'}', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  associate.status == true ? '🟢 Active' : '🔴 Inactive',
                                  style: TextStyle(
                                    color: associate.status == true ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '#${associate.associateId ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
