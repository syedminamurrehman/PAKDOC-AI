import 'package:flutter/material.dart';
import 'package:pak_doc_ai/services/api_service.dart';

class RegistrationScreen extends StatefulWidget {
  final String? initialCnic;
  const RegistrationScreen({super.key, this.initialCnic});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  late TextEditingController _cnicController;
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _allergyController = TextEditingController();
  final _historyController = TextEditingController();
  String _selectedGender = 'Male';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cnicController = TextEditingController(text: widget.initialCnic);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      await _apiService.registerPatient({
        "cnic": _cnicController.text,
        "full_name": _nameController.text,
        "date_of_birth": _ageController.text, // Sending as date_of_birth
        "gender": _selectedGender,
        "allergies": _allergyController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        "medical_history": _historyController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Patient Registered Successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, _cnicController.text);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        title: const Text("New Medical Record", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("PATIENT IDENTITY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF86868B), letterSpacing: 1)),
              const SizedBox(height: 16),
              _buildTextField(_cnicController, "CNIC / ID Number", "e.g. 42101-XXXXXXX-X"),
              _buildTextField(_nameController, "Full Name", "As per CNIC"),
              Row(
                children: [
                  Expanded(child: _buildTextField(_ageController, "Date of Birth", "YYYY-MM-DD", keyboardType: TextInputType.datetime)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Gender", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (v) => setState(() => _selectedGender = v!),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF2F2F7))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text("CLINICAL DETAILS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF86868B), letterSpacing: 1)),
              const SizedBox(height: 16),
              _buildTextField(_allergyController, "Allergies (Comma separated)", "e.g. Penicillin, Pollen"),
              _buildTextField(_historyController, "Medical History", "e.g. Hypertension, Diabetes, CKD", maxLines: 3),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004AAD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("CREATE RECORD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: (v) => v!.isEmpty ? "This field is required" : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFC7C7CC)),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF2F2F7))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF004AAD))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
