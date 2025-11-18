import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class AddDayBookScreen extends StatefulWidget {
  const AddDayBookScreen({Key? key}) : super(key: key);

  @override
  State<AddDayBookScreen> createState() => _AddDayBookScreenState();
}

class _AddDayBookScreenState extends State<AddDayBookScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDateTime = DateTime.now();

  final TextEditingController _dateTimeController =
  TextEditingController(text: DateFormat('dd MMM yyyy – hh:mm a').format(DateTime.now()));
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  File? _pickedImage;

  final List<String> _purposeList = [
    'Labour Payment',
    'Material Payment',
    'Petrol Payment',
    'Car Parking Fare',
    'Office Expense',
    'Kisan Payment',
  ];

  String? _selectedPurpose;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          child: child!,
        );
      },
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
              DateFormat('dd MMM yyyy – hh:mm a').format(_selectedDateTime);
        });
      }
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Entry Saved Successfully"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, true);
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        onTap: onTap,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) =>
        value == null || value.isEmpty ? 'Required field' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Add Day Book Entry',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFC1B00A),
                Color(0xFFBFAF12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),


      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _inputField(
                    controller: _nameController,
                    label: "User Name",
                    icon: Icons.person,
                  ),

                  _inputField(
                    controller: _mobileController,
                    label: "Mobile Number",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),

                  _inputField(
                    controller: _dateTimeController,
                    label: "Date & Time",
                    icon: Icons.calendar_month,
                    readOnly: true,
                    onTap: _pickDateTime,
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedPurpose,
                      borderRadius: BorderRadius.circular(14),
                      decoration: InputDecoration(
                        labelText: 'Purpose',
                        prefixIcon: const Icon(Icons.list_alt),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                      ),
                      items: _purposeList.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedPurpose = value);
                      },
                      validator: (value) =>
                      value == null ? 'Please select purpose' : null,
                    ),
                  ),

                  _inputField(
                    controller: _amountController,
                    label: "Amount (₹)",
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                  ),

                  _inputField(
                    controller: _remarkController,
                    label: "Remark",
                    icon: Icons.note_alt,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 10),
                  Text(
                    "Upload Screenshot",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),

                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: _pickedImage == null
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.upload, size: 40, color: Colors.yellow),
                            SizedBox(height: 6),
                            Text("Tap to Upload")
                          ],
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _pickedImage!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.yellow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        'SUBMIT ENTRY',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
    );
  }
}