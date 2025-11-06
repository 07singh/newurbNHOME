import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/Model/day_book_model.dart';
import '/service/add_book_service.dart';

class AddDayBookScreen extends StatefulWidget {
  const AddDayBookScreen({Key? key}) : super(key: key);

  @override
  State<AddDayBookScreen> createState() => _AddDayBookScreenState();
}

class _AddDayBookScreenState extends State<AddDayBookScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDateTime = DateTime.now();

  final TextEditingController _dateTimeController =
  TextEditingController(text: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()));
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _employeeController = TextEditingController();
  final TextEditingController _spendByController = TextEditingController();

  final List<String> _categories = ['Payment', 'Expense', 'Advance'];
  String? _selectedCategory;
  bool _isLoading = false;

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _dateTimeController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime);
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    DayBook newEntry = DayBook(
      id: 0,
      employeeName: _employeeController.text,
      dateTime: _selectedDateTime,
      amount: double.parse(_amountController.text),
      purpose: _purposeController.text,
      spendBy: _spendByController.text,
    );

    final result = await DayBookService.addDayBook(newEntry);

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Something went wrong'),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (result['success'] == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _dateTimeController.dispose();
    _purposeController.dispose();
    _amountController.dispose();
    _employeeController.dispose();
    _spendByController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onTap: onTap,
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Day Book Entry',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFD700),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff7F00FF), Color(0xffE100FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
            child: Container(
              width: width,
              constraints: BoxConstraints(
                minHeight: height - 32,
              ),
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _employeeController,
                      label: 'Employee Name',
                      icon: Icons.person,
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Enter employee name' : null,
                    ),
                    _buildTextField(
                      controller: _spendByController,
                      label: 'Spend By (Phone)',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Enter phone number' : null,
                    ),
                    _buildTextField(
                      controller: _dateTimeController,
                      label: 'Date & Time',
                      icon: Icons.calendar_today,
                      readOnly: true,
                      onTap: _pickDateTime,
                    ),
                    _buildTextField(
                      controller: _purposeController,
                      label: 'Purpose',
                      icon: Icons.edit_note,
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Enter purpose' : null,
                    ),
                    _buildTextField(
                      controller: _amountController,
                      label: 'Amount (₹)',
                      icon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter amount';
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Enter valid amount';
                        }
                        return null;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedCategory = value),
                        validator: (value) =>
                        value == null ? 'Please select category' : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'SUBMIT ENTRY',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}