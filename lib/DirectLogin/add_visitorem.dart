import 'package:flutter/material.dart';
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

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final visitor = Visitor(
        name: _nameController.text.trim(),
        mobileNo: _mobileController.text.trim(),
        purpose: _purposeController.text.trim(),
        date: DateTime.now(), // ✅ Always current date-time
      );

      bool success = await _service.addVisitor(visitor);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visitor added successfully')),
        );
        _formKey.currentState!.reset();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add visitor')),
        );
      }
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
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter Name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mobileController,
                  decoration: InputDecoration(
                    labelText: 'Mobile No',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                  value!.isEmpty ? 'Enter Mobile No' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _purposeController,
                  decoration: InputDecoration(
                    labelText: 'Purpose',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.note),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter Purpose' : null,
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