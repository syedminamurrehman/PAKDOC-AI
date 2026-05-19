import 'package:flutter/material.dart';

class SafetyCard extends StatelessWidget {
  final String color;
  final String drug;
  final String generic;
  final String reason;

  const SafetyCard({
    super.key,
    required this.color,
    required this.drug,
    required this.generic,
    required this.reason,
  });

  Color getStatusColor() {
    switch (color.toUpperCase()) {
      case 'RED': return const Color(0xFFFF3B30);
      case 'YELLOW': return const Color(0xFFFFCC00);
      case 'GREEN': return const Color(0xFF34C759);
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2F2F7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: getStatusColor().withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield, color: getStatusColor(), size: 18),
                const SizedBox(width: 10),
                Text(
                  "$color RISK IDENTIFIED",
                  style: TextStyle(color: getStatusColor(), fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drug,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                Text(
                  generic,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF86868B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                const Text(
                  "ANALYSIS RESULT",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF86868B), letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
                  style: const TextStyle(fontSize: 17, height: 1.5, fontWeight: FontWeight.w400, color: Color(0xFF1D1D1F)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AlternativeChip extends StatelessWidget {
  final String label;

  const AlternativeChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF004aad),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
