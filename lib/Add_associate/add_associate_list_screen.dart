import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ For call functionality
import '/Model/associate_model.dart';
import '/service/associate_list_service.dart';
import '/DirectLogin/DirectLoginPage.dart';

class AssociateListScreen extends StatefulWidget {
  const AssociateListScreen({super.key});

  @override
  State<AssociateListScreen> createState() => _AssociateListScreenState();
}

class _AssociateListScreenState extends State<AssociateListScreen> {
  final AssociateService _service = AssociateService();
  late Future<List<Associate>> _futureAssociates;

  @override
  void initState() {
    super.initState();
    _futureAssociates = _service.fetchAssociates().then((list) {
      list = list.reversed.toList(); // Latest at top
      return list;
    });
  }

  // ✅ Function to launch phone dialer
  void _makeCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot launch phone dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: const Text(
          'Associates',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Associate>>(
        future: _futureAssociates,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No associates found'));
          } else {
            final associates = snapshot.data!;
            return ListView.builder(
              itemCount: associates.length,
              itemBuilder: (context, index) {
                final associate = associates[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        'https://realapp.cheenu.in/uploads/${associate.profilePic}',
                      ),
                    ),
                    title: Text(associate.fullName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('Phone: ${associate.phone}')),
                            IconButton(
                              icon: const Icon(Icons.call, color: Colors.green),
                              onPressed: () => _makeCall(associate.phone),
                            ),
                          ],
                        ),
                        Text('Email: ${associate.email}'),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}