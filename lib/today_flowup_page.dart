import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class TodayFollowupFormPage extends StatefulWidget {
  const TodayFollowupFormPage({super.key});

  @override
  State<TodayFollowupFormPage> createState() => _TodayFollowupFormPageState();
}

class _TodayFollowupFormPageState extends State<TodayFollowupFormPage> {
  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _lastFollowUpController = TextEditingController();
  final TextEditingController _nextFollowUpController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  DateTime? _lastFollowUpDate;
  DateTime? _nextFollowUpDate;
  String? _selectedProject;
  bool _isSubmitting = false;
  String? _userPhone;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final phone = await _storage.read(key: 'user_mobile');
    if (!mounted) return;
    setState(() {
      _userPhone = phone;
    });
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    required ValueChanged<DateTime> onSelected,
    DateTime? initialDate,
  }) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? today,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 5),
    );
    if (picked != null) {
      controller.text = _formatDate(picked);
      onSelected(picked);
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    const url = "https://realapp.cheenu.in/api/followup/add";

    final body = {
      "Client_Name": _nameController.text.trim(),
      "Contact_No": _mobileController.text.trim(),
      "Project_Name": _selectedProject ?? "",
      "Next_FollowUp_Date":
          _nextFollowUpDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      "Remark": _remarkController.text.trim(),
      "Created_By": _userPhone ?? "",
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        _formKey.currentState!.reset();
        _nameController.clear();
        _mobileController.clear();
        _lastFollowUpController.clear();
        _nextFollowUpController.clear();
        _lastFollowUpDate = null;
        _nextFollowUpDate = null;
        _remarkController.clear();
        _selectedProject = null;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Follow-up saved successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save follow-up (${response.statusCode})"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Something went wrong: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _lastFollowUpController.dispose();
    _nextFollowUpController.dispose();
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
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Client Name",
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  final value = val?.trim() ?? '';
                  if (value.isEmpty) return "Enter client name";
                  if (value.length < 3) return "Name must be at least 3 characters";
                  if (!RegExp(r'^[A-Za-z ]+$').hasMatch(value)) {
                    return "Name can contain letters and spaces only";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Mobile Number
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: "Mobile No",
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  final value = val?.trim() ?? '';
                  if (value.isEmpty) return "Enter mobile number";
                  if (value.length != 10) return "Mobile number must be 10 digits";
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Project Name
              DropdownButtonFormField<String>(
                value: _selectedProject,
                decoration: const InputDecoration(
                  labelText: "Project Name",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: "Defence Phase 2",
                    child: Text("Defence Phase 2"),
                  ),
                  DropdownMenuItem(
                    value: "Green Residency Phase 2",
                    child: Text("Green Residency Phase 2"),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedProject = val),
                validator: (val) => val == null || val.isEmpty ? "Select project" : null,
              ),
              const SizedBox(height: 12),

              // Last Follow-up Date
              TextFormField(
                controller: _lastFollowUpController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Last Follow-up Date",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDate(
                      controller: _lastFollowUpController,
                      onSelected: (date) => _lastFollowUpDate = date,
                      initialDate: _lastFollowUpDate,
                    ),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Pick last follow-up date" : null,
              ),
              const SizedBox(height: 12),

              // Next Follow-up Date
              TextFormField(
                controller: _nextFollowUpController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Next Follow-up Date",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () => _pickDate(
                      controller: _nextFollowUpController,
                      onSelected: (date) => _nextFollowUpDate = date,
                      initialDate: _nextFollowUpDate ?? DateTime.now().add(const Duration(days: 1)),
                    ),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Pick next follow-up date" : null,
              ),
              const SizedBox(height: 12),

              // Remark
              TextFormField(
                controller: _remarkController,
                decoration: const InputDecoration(
                  labelText: "Last Remark",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Enter remark" : null,
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
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
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