import 'package:flutter/material.dart';
import '/Model/associate_model.dart'; // ✅ Only one model
import '/service/associate_list_service.dart';
import'/DirectLogin/DirectLoginPage.dart';

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
      list = list.reversed.toList(); // 🔄 Latest upar dikhega
      return list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Associates'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // ✅ This ensures we go back safely
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // ✅ If no previous screen, go to DirectloginPage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DirectloginPage()),
              );
            }
          },
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
                        Text('Phone: ${associate.phone}'),
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
