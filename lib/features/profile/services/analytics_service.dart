import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../ai_sensei/services/gemini_content_service.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, double>> getSubjectStrengths() async {
    // Phase 43.5: Operation "Safety Net"
    // Standardize to fixed list to prevent Radar Chart crash (needs 3+ entries)
    // Phase 44: Added CSAT and Current Affairs
    final List<String> coreSubjects = [
      'History',
      'Polity',
      'Geography',
      'Economy',
      'Environment',
      'Science',
      'CSAT',
      'Current Affairs',
    ];

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return _getFallbackData();

      final doc = await _firestore.collection('users').doc(user.uid).get();
      // If no doc or no stats, return fallback (which now returns full list)
      if (!doc.exists) return _getFallbackData();

      final data = doc.data()!;
      if (!data.containsKey('stats')) return _getFallbackData();

      final stats = data['stats'] as Map<String, dynamic>;
      final Map<String, double> result = {};

      for (String subject in coreSubjects) {
        if (stats.containsKey(subject) && stats[subject] is Map) {
          final subjectStats = stats[subject] as Map<String, dynamic>;
          final attempted = subjectStats['attempted'] as int? ?? 0;
          final correct = subjectStats['correct'] as int? ?? 0;

          if (attempted > 0) {
            double accuracy = (correct / attempted) * 100;
            if (accuracy < 10) accuracy = 10;
            if (accuracy > 100) accuracy = 100;
            result[subject] = accuracy;
          } else {
            result[subject] = 10.0; // Default weak
          }
        } else {
          result[subject] = 10.0; // Default weak
        }
      }

      return result;
    } catch (e) {
      return _getFallbackData();
    }
  }

  Future<Map<String, String>> getServiceRecord() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {"accuracy": "0%", "completion": "N/A"};

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return {"accuracy": "0%", "completion": "N/A"};

      final data = doc.data()!;
      if (!data.containsKey('stats'))
        return {"accuracy": "0%", "completion": "N/A"};

      final stats = data['stats'] as Map<String, dynamic>;
      int totalAttempted = 0;
      int totalCorrect = 0;

      stats.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          totalAttempted += (value['attempted'] as int? ?? 0);
          totalCorrect += (value['correct'] as int? ?? 0);
        }
      });

      String accuracy = "0%";
      if (totalAttempted > 0) {
        accuracy = "${((totalCorrect / totalAttempted) * 100).round()}%";
      }

      // Compute completion percentage: prefer explicit user counter if present
      int userCompleted = (data['totalQuizzesTaken'] as int?) ?? totalAttempted;

      // Count total available quizzes in DB (small collection expected). If empty, return placeholder.
      try {
        final quizzesSnapshot = await _firestore.collection('quizzes').get();
        final totalAvailable = quizzesSnapshot.docs.length;
        String completion = "--";
        if (totalAvailable > 0) {
          final percent = ((userCompleted / totalAvailable) * 100).round();
          completion = "$percent%";
        }
        return {"accuracy": accuracy, "completion": completion};
      } catch (e) {
        return {"accuracy": accuracy, "completion": "--"};
      }
    } catch (e) {
      return {"accuracy": "0%", "completion": "ERR"};
    }
  }

  // Phase 5: War Room - AI Analyst Bridge
  Future<String> getAIAnalysis() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return "Access Denied. Please sign in.";

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return "No data found for analysis.";

      final data = doc.data()!;
      final stats = data['stats'] as Map<String, dynamic>? ?? {};

      // Analyze
      // We need to import GeminiContentService.
      // Since it's in a different feature, we might need to import it at top.
      // Or use a precise import if check fails.
      return await GeminiContentService().generateInsights(stats);
    } catch (e) {
      return "Analysis Unavailable: $e";
    }
  }

  Map<String, double> _getFallbackData() {
    return {
      "History": 10,
      "Polity": 10,
      "Geography": 10,
      "Economy": 10,
      "Environment": 10,
      "Science": 10,
      "CSAT": 10,
      "Current Affairs": 10,
    };
  }
}
