import 'package:flutter/material.dart';
import 'package:pak_doc_ai/models/models.dart';
import 'package:pak_doc_ai/services/api_service.dart';
import 'package:pak_doc_ai/screens/scanner_screen.dart';

class VitalsScreen extends StatefulWidget {
  final Patient patient;
  const VitalsScreen({super.key, required this.patient});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  final _weightController = TextEditingController();
  final _bpController = TextEditingController();
  final _hrController = TextEditingController();
  final _tempController = TextEditingController();
  final _complaintController = TextEditingController();
  bool _isLoading = false;

  void _saveVitals() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      await _apiService.recordVitals({
        "patient_cnic": widget.patient.cnic,
        "weight_kg": double.parse(_weightController.text),
        "blood_pressure": _bpController.text,
        "heart_rate": int.parse(_hrController.text),
        "temperature_f": double.parse(_tempController.text),
        "chief_complaint": _complaintController.text,
      });
      
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => ScannerScreen(patient: widget.patient))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        title: const Text("Current Vitals", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
              Text("Patient: ${widget.patient.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildField(_weightController, "Weight (kg)", "e.g. 70", keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(_tempController, "Temp (°F)", "e.g. 98.6", keyboardType: TextInputType.number)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildField(_bpController, "Blood Pressure", "e.g. 120/80")),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(_hrController, "Heart Rate", "e.g. 72", keyboardType: TextInputType.number)),
                ],
              ),
              _buildField(_complaintController, "Chief Complaint", "Why is the patient here?", maxLines: 2),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveVitals,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004AAD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SAVE & PROCEED TO SCAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, String hint, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
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
            validator: (v) => v!.isEmpty ? "Required" : null,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF2F2F7))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF004AAD))),
            ),
          ),
        ],
      ),
    );
  }
}
