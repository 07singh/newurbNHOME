import 'package:flutter/material.dart';
import '/service/add_staff_list_service.dart';
import '/Model/add_staff_list.dart';

class StaffListScreenhr extends StatefulWidget {
  const StaffListScreenhr({super.key});

  @override
  State<StaffListScreenhr> createState() => _StaffListScreenhrState();
}

class _StaffListScreenhrState extends State<StaffListScreenhr> {
  final StaffService _service = StaffService();
  late Future<StaffListResponse> _futureStaff;

  @override
  void initState() {
    super.initState();
    _futureStaff = _service.fetchStaffList();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureStaff = _service.fetchStaffList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Staff List",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Color(0xFF3A62B7),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<StaffListResponse>(
        future: _futureStaff,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final staffList = snapshot.data!.data;

          if (staffList.isEmpty) {
            return const Center(child: Text("No staff found"));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: staffList.length,
              itemBuilder: (context, index) {
                final staff = staffList[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: staff.profilePic != null
                        ? NetworkImage(
                        "https://realapp.cheenu.in/uploads/${staff.profilePic}")
                        : const AssetImage('assets/download (1).jpeg')
                    as ImageProvider,
                  ),
                  title: Text(staff.fullname),
                  subtitle: Text("${staff.position} | ${staff.phone}"),
                  trailing: staff.status
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.cancel, color: Colors.red),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
