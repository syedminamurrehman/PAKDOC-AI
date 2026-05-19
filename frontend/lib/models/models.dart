class Patient {
  final String id;
  final String name;
  final int age;
  final double weight;
  final List<String> allergies;
  final String? condition;
  final String cnic;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.weight,
    required this.allergies,
    required this.cnic,
    this.condition,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['cnic'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      weight: (json['weight'] ?? 0).toDouble(),
      allergies: List<String>.from(json['allergies'] ?? []),
      cnic: json['cnic'] ?? '',
      condition: json['condition'],
    );
  }
}

class AgentStep {
  final String agentName;
  final String thoughtProcess;
  final dynamic findings;
  final String riskLevel;
  final String recommendation;

  AgentStep({
    required this.agentName,
    required this.thoughtProcess,
    required this.findings,
    required this.riskLevel,
    required this.recommendation,
  });

  factory AgentStep.fromJson(Map<String, dynamic> json) {
    return AgentStep(
      agentName: json['agent_name'] ?? '',
      thoughtProcess: json['thought_process'] ?? '',
      findings: json['findings'],
      riskLevel: json['risk_level'] ?? 'GREEN',
      recommendation: json['recommendation'] ?? '',
    );
  }
}

class AnalysisResult {
  final String drug;
  final String generic;
  final String safetyColor;
  final String reason;
  final List<String> alternatives;
  final List<AgentStep> agentSteps;
  final String actionSimulated;
  final Map<String, dynamic> outcomeVisualization;

  AnalysisResult({
    required this.drug,
    required this.generic,
    required this.safetyColor,
    required this.reason,
    required this.alternatives,
    required this.agentSteps,
    required this.actionSimulated,
    required this.outcomeVisualization,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      drug: json['drug'] ?? 'Unknown',
      generic: json['generic'] ?? 'Unknown',
      safetyColor: json['safety_color'] ?? 'GREEN',
      reason: json['reason'] ?? '',
      alternatives: List<String>.from(json['alternatives'] ?? []),
      agentSteps: (json['agent_steps'] as List? ?? [])
          .map((step) => AgentStep.fromJson(step))
          .toList(),
      actionSimulated: json['action_simulated'] ?? '',
      outcomeVisualization: Map<String, dynamic>.from(json['outcome_visualization'] ?? {}),
    );
  }
}
