import 'package:flutter/material.dart';

class Associate_addNewVisit extends StatefulWidget {
  const Associate_addNewVisit({super.key});

  @override
  State<Associate_addNewVisit> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends State<Associate_addNewVisit> {
  final TextEditingController clientNameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController dateTimeController = TextEditingController();

  String? selectedProject;

  final List<String> projectList = [
    "Green Valley Residency",
    "Sunshine Enclave",
    "Elite City Phase 2",
    "Silver Homes"
  ];

  Future<void> pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final DateTime finalDateTime =
    DateTime(date.year, date.month, date.day, time.hour, time.minute);

    dateTimeController.text = finalDateTime.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Client Form"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Name
            const Text("Client Name", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: clientNameController,
              decoration: InputDecoration(
                hintText: "Enter client name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            // Project Dropdown
            const Text("Select Project Name", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              value: selectedProject,
              hint: const Text("Select project"),
              items: projectList.map((project) {
                return DropdownMenuItem(
                  value: project,
                  child: Text(project),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedProject = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Date & Time Picker
            const Text("Date & Time", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: dateTimeController,
              readOnly: true,
              onTap: pickDateTime,
              decoration: InputDecoration(
                hintText: "Select date & time",
                suffixIcon: const Icon(Icons.calendar_month),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            // Contact Number
            const Text("Contact Number", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: contactController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Enter contact number",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            // Note
            const Text("Note", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter note",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Submit action here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
