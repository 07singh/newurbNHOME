import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '/service/auth_manager.dart';

class AddDayBookScreenhr extends StatefulWidget {
  const AddDayBookScreenhr({Key? key}) : super(key: key);

  @override
  State<AddDayBookScreenhr> createState() => _AddDayBookScreenhrState();
}

class _AddDayBookScreenhrState extends State<AddDayBookScreenhr> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDateTime = DateTime.now();

  final TextEditingController _dateTimeController =
  TextEditingController(text: DateFormat('yyyy-MM-ddTHH:mm:ss').format(DateTime.now()));
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _paymentGivenByController = TextEditingController();

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
  String _selectedPaymentMode = 'Cash';
  final List<String> _paymentModes = ['Cash', 'UPI'];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final session = await AuthManager.getCurrentSession();
    if (!mounted) return;
    setState(() {
      _paymentGivenByController.text = session?.userName ?? '';
    });
  }

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
              DateFormat('yyyy-MM-ddTHH:mm:ss').format(_selectedDateTime);
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    String? base64Image;
    if (_pickedImage != null) {
      final bytes = await _pickedImage!.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    final body = {
      "Id": 1,
      "Employee_Name": _employeeNameController.text.trim(),
      "Date_Time": _dateTimeController.text.trim(),
      "Amount": double.tryParse(_amountController.text.trim()) ?? 0.0,
      "Purpose": _selectedPurpose,
      "PaymentGivenBy": _paymentGivenByController.text.trim(),
      "PaymentMode": _selectedPaymentMode,
      "Spend_By": _mobileController.text.trim(),
      "Remarks": _remarkController.text.trim(),
      "Screenshot": base64Image ?? "",
    };

    try {
      final dio = Dio();
      final response = await dio.post(
        "https://realapp.cheenu.in/api/AddDayBook/add",
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Entry Saved Successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${response.statusCode} ${response.statusMessage}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Exception: ${e.toString()}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
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
        validator: validator ?? ((value) =>
        value == null || value.isEmpty ? 'Required field' : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
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
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3371F4), Color(0xFF3371F4)],
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
                    controller: _employeeNameController,
                    label: "Employee Name",
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter employee name';
                      }
                      return null;
                    },
                  ),
                  _inputField(
                    controller: _mobileController,
                    label: "Spend By (Phone Number)",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
                      // Allow any phone number format (10 digits minimum)
                      final phoneRegex = RegExp(r'^[0-9]{10,}$');
                      if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
                        return 'Please enter a valid mobile number';
                      }
                      return null;
                    },
                  ),
                  _inputField(
                    controller: _paymentGivenByController,
                    label: "Payment Given By (Logger)",
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter logger name';
                      }
                      return null;
                    },
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
                      value: _selectedPaymentMode,
                      borderRadius: BorderRadius.circular(14),
                      decoration: InputDecoration(
                        labelText: 'Payment Mode',
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _paymentModes
                          .map(
                            (mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(mode),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedPaymentMode = value);
                      },
                    ),
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
                          borderSide: BorderSide.none,
                        ),
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
                      color: Colors.grey.shade700,
                    ),
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
                            Icon(Icons.upload,
                                size: 40, color: Color(0xFF3371F4)),
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
                      onPressed: _loading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF3371F4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text(
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
