import 'package:flutter/material.dart';

class EvaluationResultWidget extends StatelessWidget {
  final Map<String, dynamic> evaluation;

  const EvaluationResultWidget({super.key, required this.evaluation});

  @override
  Widget build(BuildContext context) {
    final scoreStr = evaluation['score'] as String? ?? '0/10';
    final score = int.tryParse(scoreStr.split('/')[0]) ?? 0;
    final isGoodScore = score >= 5;

    final strengths = List<String>.from(evaluation['strengths'] ?? []);
    final weaknesses = List<String>.from(evaluation['weaknesses'] ?? []);
    final missingKeywords = List<String>.from(evaluation['missing_keywords'] ?? []);
    final comment = evaluation['overall_comment'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Score Circle
        Center(
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isGoodScore ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                  border: Border.all(
                    color: isGoodScore ? Colors.green : Colors.red,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Text(
                    scoreStr,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isGoodScore ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'AI SENSEI VERDICT',
                style: TextStyle(color: Colors.white60, letterSpacing: 1.5, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Overall Comment
        _buildSectionTitle('EXAMINER REMARKS'),
        Text(
          comment,
          style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 24),

        // Strengths
        _buildSectionTitle('STRENGTHS'),
        ...strengths.map((s) => _buildBulletPoint(s, Colors.greenAccent)),
        const SizedBox(height: 16),

        // Weaknesses
        _buildSectionTitle('WEAKNESSES'),
        ...weaknesses.map((w) => _buildBulletPoint(w, Colors.redAccent)),
        const SizedBox(height: 16),

        // Missing Keywords
        if (missingKeywords.isNotEmpty) ...[
          _buildSectionTitle('MISSING KEYWORDS'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: missingKeywords.map((k) => Chip(
              label: Text(k, style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.blueGrey.shade800,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Icon(Icons.circle, size: 6, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
