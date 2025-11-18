import 'package:flutter/material.dart';

class TodayFollowupFormPage extends StatefulWidget {
  const TodayFollowupFormPage({super.key});

  @override
  State<TodayFollowupFormPage> createState() => _TodayFollowupFormPageState();
}

class _TodayFollowupFormPageState extends State<TodayFollowupFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _requirementController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  String? _selectedLeadProcess;

  final List<String> leadOptions = [
    "Facebook",
    "Instagram",
    "Data",
    "Magicbricks",
    "9acres",
    "Other"
  ];

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Here you can handle form submission or API call
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Form Submitted"),
          content: Text(
              "Client Name: ${_nameController.text}\n"
                  "Mobile: ${_mobileController.text}\n"
                  "Project: ${_projectController.text}\n"
                  "Lead Process: $_selectedLeadProcess\n"
                  "Requirement: ${_requirementController.text}\n"
                  "Remark: ${_remarkController.text}"
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _projectController.dispose();
    _requirementController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today Follow-up"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Client Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Client Name",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                val == null || val.isEmpty ? "Enter client name" : null,
              ),
              const SizedBox(height: 12),

              // Mobile Number
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Mobile No",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                val == null || val.isEmpty ? "Enter mobile number" : null,
              ),
              const SizedBox(height: 12),

              // Project Name
              TextFormField(
                controller: _projectController,
                decoration: const InputDecoration(
                  labelText: "Project Name",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                val == null || val.isEmpty ? "Enter project name" : null,
              ),
              const SizedBox(height: 12),

              // Lead Process Dropdown
              DropdownButtonFormField<String>(
                value: _selectedLeadProcess,
                items: leadOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: "Lead Process",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                val == null ? "Select lead process" : null,
                onChanged: (val) {
                  setState(() {
                    _selectedLeadProcess = val;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Requirement
              TextFormField(
                controller: _requirementController,
                decoration: const InputDecoration(
                  labelText: "Requirement",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Remark
              TextFormField(
                controller: _remarkController,
                decoration: const InputDecoration(
                  labelText: "Remark",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Submit",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}