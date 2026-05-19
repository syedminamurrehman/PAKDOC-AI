import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class ResultScreen extends StatelessWidget {
  final AnalysisResult result;
  final Patient patient;

  const ResultScreen({super.key, required this.result, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        title: const Text("Safety Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Minimalist Patient Info Strip
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.account_circle, color: Color(0xFF86868B), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    patient.name.toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF86868B)),
                  ),
                  const Spacer(),
                  const Text("VERIFIED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF2F2F7)),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SafetyCard(
                    color: result.safetyColor,
                    drug: result.drug,
                    generic: result.generic,
                    reason: result.reason,
                  ),
                  const SizedBox(height: 32),
                  
                  // --- AI AGENT REASONING SECTION ---
                  const Text(
                    "AI MULTI-AGENT REASONING",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF86868B), letterSpacing: 1),
                  ),
                  const SizedBox(height: 16),
                  ...result.agentSteps.map((step) => _buildAgentStepCard(step)),
                  
                  const SizedBox(height: 32),
                  
                  // --- ACTION & OUTCOME ---
                  if (result.actionSimulated.isNotEmpty) ...[
                    const Text(
                      "SIMULATED ACTION & OUTCOME",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF86868B), letterSpacing: 1),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF2F2F7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.psychology_outlined, size: 20, color: Color(0xFF5E5E62)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  result.actionSimulated,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Safety Probability", style: TextStyle(fontSize: 13, color: Color(0xFF86868B))),
                              Text(
                                "${result.outcomeVisualization['safety_score']}%",
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold, 
                                  color: _getScoreColor(result.outcomeVisualization['safety_score'] ?? 0)
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (result.outcomeVisualization['safety_score'] ?? 0) / 100,
                            backgroundColor: const Color(0xFFF2F2F7),
                            color: _getScoreColor(result.outcomeVisualization['safety_score'] ?? 0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  if (result.alternatives.isNotEmpty) ...[
                    const Text(
                      "SUGGESTED ALTERNATIVES",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF86868B), letterSpacing: 1),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: result.alternatives.length,
                        itemBuilder: (context, index) {
                          return AlternativeChip(label: result.alternatives[index]);
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.1)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3B30), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "IMPORTANT: This is an AI-generated safety check. The final clinical decision rests entirely with the attending physician. Please review all details before proceeding.",
                            style: TextStyle(fontSize: 12, color: Color(0xFF1D1D1F), fontWeight: FontWeight.w500, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D1D1F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text("FINISH SESSION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentStepCard(AgentStep step) {
    Color statusColor = Colors.green;
    if (step.riskLevel == 'RED') statusColor = Colors.red;
    if (step.riskLevel == 'YELLOW') statusColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F2F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  step.agentName.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
              const Spacer(),
              Icon(Icons.check_circle, size: 16, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            step.thoughtProcess,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F), height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            "Recommendation: ${step.recommendation}",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
