import 'dart:convert';
import 'package:flutter/material.dart';
import '/service/associate_list_service.dart';
import '/Model/associate_list_model.dart';

class AssociateCardScreen extends StatefulWidget {
  const AssociateCardScreen({Key? key}) : super(key: key);

  @override
  _AssociateCardScreenState createState() => _AssociateCardScreenState();
}

class _AssociateCardScreenState extends State<AssociateCardScreen> {
  final AssociateService _associateService = AssociateService();
  late Future<AssociateList> _futureAssociates;

  @override
  void initState() {
    super.initState();
    // Fetch all associates automatically
    _futureAssociates = _associateService.fetchAssociateList(phone: '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Associate List'),
        backgroundColor: Color(0xFFFFD700),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<AssociateList>(
        future: _futureAssociates,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.data1 == null || snapshot.data!.data1!.isEmpty) {
            return const Center(child: Text('No associates found'));
          }

          final associates = snapshot.data!.data1!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: associates.length,
            itemBuilder: (context, index) {
              final associate = associates[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                          image: DecorationImage(
                            image: associate.photoBase64 != null
                                ? MemoryImage(base64Decode(associate.photoBase64!))
                                : const AssetImage('assets/default_profile.png') as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
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
                            const SizedBox(height: 4),
                            Text('Phone: ${associate.phone ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                            Text('Email: ${associate.email ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                            Text('City: ${associate.city ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                            Text(
                              'Status: ${associate.status == true ? 'Active' : 'Inactive'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${associate.associateId ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
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
