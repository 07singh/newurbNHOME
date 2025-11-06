import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Employee',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFD700),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Summary', style: TextStyle(fontSize: 18)),
                TextButton(
                  onPressed: () {},
                  child: const Text('See detail'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Chip(label: Text('Active: 213')),
                Chip(label: Text('Inactive: 14')),
                Chip(label: Text('Total: 227')),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Employee List', style: TextStyle(fontSize: 18)),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Checkbox(value: false, onChanged: (value) {}),
                    title: const Text('Jack Snyder'),
                    subtitle: const Text('In Time: 09:00 AM'),
                    trailing: const Text('Present', style: TextStyle(color: Colors.green)),
                  ),
                  ListTile(
                    leading: Checkbox(value: false, onChanged: (value) {}),
                    title: const Text('Abdul DiCaprio'),
                    subtitle: const Text('In Time: 09:15 AM'),
                    trailing: const Text('Present', style: TextStyle(color: Colors.green)),
                  ),
                  ListTile(
                    leading: Checkbox(value: false, onChanged: (value) {}),
                    title: const Text('Roy Manhunt'),
                    subtitle: const Text('In Time: 08:45 AM'),
                    trailing: const Text('Absent', style: TextStyle(color: Colors.red)),
                  ),
                  ListTile(
                    leading: Checkbox(value: false, onChanged: (value) {}),
                    title: const Text('Tonelli Anton'),
                    subtitle: const Text('In Time: 09:30 AM'),
                    trailing: const Text('Absent', style: TextStyle(color: Colors.red)),
                  ),
                  ListTile(
                    leading: Checkbox(value: false, onChanged: (value) {}),
                    title: const Text('Michael Burrows'),
                    subtitle: const Text('In Time: 09:10 AM'),
                    trailing: const Text('Present', style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}