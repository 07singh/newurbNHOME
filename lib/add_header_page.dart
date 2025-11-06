import 'package:flutter/material.dart';

class AddHeaderPage extends StatefulWidget {
  @override
  _AddHeaderPageState createState() => _AddHeaderPageState();
}

class _AddHeaderPageState extends State<AddHeaderPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();
  final TextEditingController _listedNoController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _requestController = TextEditingController();

  @override
  void dispose() {
    _clientNameController.dispose();
    _mobileNoController.dispose();
    _listedNoController.dispose();
    _noteController.dispose();
    _requestController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // You can now use the form values or send them to a server
      final snackBar = SnackBar(
        content: Text("Header submitted successfully!"),
        backgroundColor: Colors.green,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      // Clear fields (optional)
      _clientNameController.clear();
      _mobileNoController.clear();
      _listedNoController.clear();
      _noteController.clear();
      _requestController.clear();
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Header"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(label: 'Client Name', controller: _clientNameController),
              SizedBox(height: 16),

              _buildTextField(
                label: 'Mobile No',
                controller: _mobileNoController,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),

              _buildTextField(label: 'Listed No', controller: _listedNoController),
              SizedBox(height: 16),

              _buildTextField(
                label: 'Note',
                controller: _noteController,
                maxLines: 3,
              ),
              SizedBox(height: 16),

              _buildTextField(
                label: 'Request',
                controller: _requestController,
                maxLines: 3,
              ),
              SizedBox(height: 26),

              SizedBox(
                width: double.infinity, // Makes button full width
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: Icon(Icons.send, color: Colors.white),
                  label: Text("Submit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white, // Makes text/icon white
                    elevation: 5, // Adds slight shadow
                    minimumSize: Size(0, 56), // height of button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
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
