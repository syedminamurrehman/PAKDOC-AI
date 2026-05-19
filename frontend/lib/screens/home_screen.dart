import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:pak_doc_ai/models/models.dart';
import 'package:pak_doc_ai/services/api_service.dart';
import 'package:pak_doc_ai/screens/scanner_screen.dart';
import 'package:pak_doc_ai/screens/registration_screen.dart';
import 'package:pak_doc_ai/screens/vitals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  Patient? _foundPatient;
  bool _isSearching = false;
  String? _error;

  void _searchPatient() async {
    if (_searchController.text.isEmpty) return;
    setState(() { _isSearching = true; _error = null; _foundPatient = null; });
    try {
      final patient = await _apiService.getPatient(_searchController.text);
      setState(() => _foundPatient = patient);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll("Exception:", ""));
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Row(
                  children: [
                    Icon(Icons.health_and_safety, color: Color(0xFF004AAD), size: 32),
                    SizedBox(width: 12),
                    Text(
                      "PakDocAI",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1D1D1F)),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                const Text(
                  "Access Patient Records",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Enter CNIC or Patient ID to verify clinical history.",
                  style: TextStyle(color: Color(0xFF86868B), fontSize: 16),
                ),
                const SizedBox(height: 32),
                
                // Search Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "e.g. 42101-1111111-1",
                      hintStyle: const TextStyle(color: Color(0xFFC7C7CC)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF004AAD)),
                      suffixIcon: _isSearching 
                        ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _searchPatient),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onSubmitted: (_) => _searchPatient(),
                  ),
                ),
                
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                        if (_error!.contains("No record found"))
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final newCnic = await Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => RegistrationScreen(initialCnic: _searchController.text))
                                  );
                                  if (newCnic != null) {
                                    _searchController.text = newCnic;
                                    _searchPatient();
                                  }
                                },
                                icon: const Icon(Icons.person_add_alt_1),
                                label: const Text("REGISTER AS NEW PATIENT"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF004AAD),
                                  side: const BorderSide(color: Color(0xFF004AAD)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Quick Actions (Visible when no search result is active)
                if (_foundPatient == null && !_isSearching) ...[
                  const Text("QUICK ACTIONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF86868B), letterSpacing: 1)),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF2F2F7)),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0xFFF0F7FF),
                            child: Icon(Icons.person_add_alt_1, color: Color(0xFF004AAD)),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Register New Patient", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text("Create a digital medical ID for a new user", style: TextStyle(color: Color(0xFF86868B), fontSize: 13)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFC7C7CC)),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
                
                if (_foundPatient != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("IDENTIFIED PATIENT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF86868B), letterSpacing: 1)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFF2F2F7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_foundPatient!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            Text("ID: ${_foundPatient!.cnic}", style: const TextStyle(color: Color(0xFF86868B))),
                            const Divider(height: 40),
                            _buildSimpleInfo("Allergies", _foundPatient!.allergies.isEmpty ? "None" : _foundPatient!.allergies.join(", ")),
                            const SizedBox(height: 16),
                            _buildSimpleInfo("Condition", _foundPatient!.condition ?? "Stable / No chronic history"),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => VitalsScreen(patient: _foundPatient!)));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF004AAD),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: const Text("ADD VITALS & SCAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF004AAD))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
