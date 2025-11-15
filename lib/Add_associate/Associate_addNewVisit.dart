import 'package:flutter/material.dart';
import '/Model/associate_add_client_form_model.dart';
import '/service/associate_add_form_service.dart';

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

  final AssociateAddFormService _service = AssociateAddFormService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedProject;
  bool _isSubmitting = false;

  final List<String> projectList = [
    "Green Valley Residency",
    "Elite City Phase 2",
    "Skyline Apartments",
    "Royal Gardens",
    "Tech Park Plaza",
  ];

  @override
  void initState() {
    super.initState();
    // Set initial date time to current time
    dateTimeController.text = DateTime.now().toIso8601String();
  }

  Future<void> pickDateTime() async {
    final DateTime initialDate = dateTimeController.text.isNotEmpty
        ? DateTime.parse(dateTimeController.text)
        : DateTime.now();

    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: initialDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    final DateTime finalDateTime =
    DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      dateTimeController.text = finalDateTime.toIso8601String();
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Manual validation for dropdown
    if (selectedProject == null) {
      _showSnackBar('Please select a project');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = AddClientRequest(
        clientName: clientNameController.text.trim(),
        projectName: selectedProject!,
        createDate: dateTimeController.text,
        contactNo: contactController.text.trim(),
        note: noteController.text.trim(),
      );

      final response = await _service.addClient(request);

      if (response.status == "Success") {
        _showSuccessDialog(response.message);
        _clearForm();
      } else {
        _showSnackBar('Failed: ${response.message}');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    clientNameController.clear();
    contactController.clear();
    noteController.clear();
    setState(() {
      selectedProject = null;
      dateTimeController.text = DateTime.now().toIso8601String();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text("Success"),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to previous screen
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  String? _validateContact(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter contact number';
    }
    if (value.length != 10) {
      return 'Contact number must be 10 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Please enter valid contact number';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Client"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client Name
                  _buildSectionTitle("Client Name"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: clientNameController,
                    validator: (value) => _validateRequired(value, 'client name'),
                    decoration: _inputDecoration(
                      hintText: "Enter client name",
                      prefixIcon: Icons.person_outline,
                    ),
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 20),

                  // Project Dropdown
                  _buildSectionTitle("Select Project"),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedProject,
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a project';
                      }
                      return null;
                    },
                    decoration: _inputDecoration(
                      hintText: "Select project",
                      prefixIcon: Icons.business_outlined,
                    ),
                    items: projectList.map((project) {
                      return DropdownMenuItem(
                        value: project,
                        child: Text(
                          project,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedProject = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // Date & Time Picker
                  _buildSectionTitle("Date & Time"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: dateTimeController,
                    readOnly: true,
                    onTap: pickDateTime,
                    validator: (value) => _validateRequired(value, 'date and time'),
                    decoration: _inputDecoration(
                      hintText: "Select date & time",
                      prefixIcon: Icons.calendar_today_outlined,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Contact Number
                  _buildSectionTitle("Contact Number"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: contactController,
                    keyboardType: TextInputType.phone,
                    validator: _validateContact,
                    maxLength: 10,
                    decoration: _inputDecoration(
                      hintText: "Enter 10-digit contact number",
                      prefixIcon: Icons.phone_android_outlined,
                      counterText: "",
                    ),
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 20),

                  // Note
                  _buildSectionTitle("Note"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: noteController,
                    maxLines: 4,
                    validator: (value) => _validateRequired(value, 'note'),
                    decoration: _inputDecoration(
                      hintText: "Enter note about the client...",
                      prefixIcon: Icons.note_outlined,
                    ),
                    textInputAction: TextInputAction.done,
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isSubmitting) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    String? counterText,
  }) {
    return InputDecoration(
      hintText: hintText,
      counterText: counterText,
      prefixIcon: Icon(prefixIcon, color: Colors.deepPurple),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : const Text(
          "Submit Client Details",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
        ),
      ),
    );
  }

  @override
  void dispose() {
    clientNameController.dispose();
    contactController.dispose();
    noteController.dispose();
    dateTimeController.dispose();
    super.dispose();
  }
}