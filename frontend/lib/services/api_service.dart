import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // Use "10.0.2.2" for Android Emulator to access host localhost
  // Use "localhost" for iOS Simulator or Web
  // Use your computer's IP (e.g., 192.168.1.10) for physical devices
  static const String baseUrl = "http://10.180.166.156:8000"; 

  Future<Patient> getPatient(String cnic) async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients/$cnic'), // Updated path to match backend
    );

    if (response.statusCode == 200) {
      return Patient.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception("No record found for this ID");
    } else {
      throw Exception("Server connection failed");
    }
  }

  Future<void> registerPatient(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patients'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception("Registration failed");
    }
  }

  Future<String> recordVitals(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/visits'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['visit_id'];
    } else {
      throw Exception("Failed to record vitals");
    }
  }

  Future<AnalysisResult> analyzePrescription(String patientId, String inputText) async {
    final response = await http.post(
      Uri.parse('$baseUrl/analyze'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "patient_id": patientId,
        "input_text": inputText,
      }),
    );

    if (response.statusCode == 200) {
      return AnalysisResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Safety check failed to complete");
    }
  }

  Future<AnalysisResult> analyzeImage(String patientId, String imagePath) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze-image'));
    request.fields['patient_id'] = patientId;
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return AnalysisResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Image analysis failed");
    }
  }
}
