import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  String? _selectedLeaveType;

  final List<String> _leaveTypes = [
    'Sick Leave',
    'Casual Leave',
    'Earned Leave',
    'Maternity Leave',
    'Paternity Leave'
  ];

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Leave application submitted successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leave Application"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Apply for Leave",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Employee Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Employee Name",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 15),

                  // Leave Type
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Leave Type",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    value: _selectedLeaveType,
                    items: _leaveTypes
                        .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLeaveType = value;
                      });
                    },
                    validator: (value) =>
                    value == null ? 'Please select leave type' : null,
                  ),
                  const SizedBox(height: 15),

                  // Start Date
                  TextFormField(
                    controller: _startDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Start Date",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.date_range),
                        onPressed: () => _pickDate(_startDateController),
                      ),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? 'Please select start date' : null,
                  ),
                  const SizedBox(height: 15),

                  // End Date
                  TextFormField(
                    controller: _endDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "End Date",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.date_range),
                        onPressed: () => _pickDate(_endDateController),
                      ),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? 'Please select end date' : null,
                  ),
                  const SizedBox(height: 15),

                  // Reason
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Reason",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter a reason' : null,
                  ),
                  const SizedBox(height: 25),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.send),
                      label: const Text(
                        "Submit Leave",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
