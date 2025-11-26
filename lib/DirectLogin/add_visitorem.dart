import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/Model/add_visitor.dart';
import '/service/add_visitor_service.dart';
import 'package:intl/intl.dart';

class AddVisitorScreenem extends StatefulWidget {
  const AddVisitorScreenem({super.key});

  @override
  State<AddVisitorScreenem> createState() => _AddVisitorScreenState();
}

class _AddVisitorScreenState extends State<AddVisitorScreenem> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _purposeController = TextEditingController();
  final VisitorService _service = VisitorService();

  /// Automatically get current date & time
  String get _currentDateTime =>
      DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final visitor = Visitor(
      name: _nameController.text.trim(),
      mobileNo: _mobileController.text.trim(),
      purpose: _purposeController.text.trim(),
      date: DateTime.now(),
    );

    final success = await _service.addVisitor(visitor);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visitor added successfully')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add visitor')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Visitor'),
        centerTitle: true,
        elevation: 2,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Visitor Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return 'Enter name';
                    if (trimmed.length < 3) return 'Name must be at least 3 characters';
                    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(trimmed)) {
                      return 'Name can contain letters and spaces only';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Mobile No',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  validator: (value) {
                    final digits = value?.trim() ?? '';
                    if (digits.isEmpty) return 'Enter mobile number';
                    if (digits.length != 10) return 'Mobile number must be 10 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _purposeController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Purpose',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.note),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Enter purpose';
                    if (text.length < 4) return 'Purpose must be at least 4 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // ✅ Just show current date-time (no selection)
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text(
                      'Current Time: $_currentDateTime',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Add Visitor',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}