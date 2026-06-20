import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cadre_upsc/features/gamification/models/quiz_entity.dart';
import 'package:cadre_upsc/features/ai_sensei/services/gemini_content_service.dart';

class DailyOperationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Returns today's 5-question current affairs operation.
  /// Generates via Gemini if not yet in Firestore.
  Future<List<QuestionEntity>?> getTodaysOperation() async {
    try {
      final doc = await _firestore.collection('daily_operations').doc(_todayKey).get();

      if (doc.exists && doc.data() != null) {
        final raw = List<Map<String, dynamic>>.from(doc.data()!['questions'] ?? []);
        return raw.map((q) => QuestionEntity.fromMap(q)).toList();
      }

      // Generate fresh via Gemini
      final gemini = GeminiContentService();
      final quiz = await gemini.generateQuizForTopic(
        'DAILY_CA_$_todayKey',
        'Current Affairs',
        'Daily Current Affairs Operation',
        difficulty: 'Officer',
      );

      if (quiz.questions.isEmpty) return null;

      // Save to Firestore for all users
      final questions = quiz.questions.take(5).toList();
      await _firestore.collection('daily_operations').doc(_todayKey).set({
        'questions': questions.map((q) => q.toMap()).toList(),
        'topic': 'Current Affairs',
        'generatedAt': FieldValue.serverTimestamp(),
      });

      return questions;
    } catch (e) {
      debugPrint('DailyOperationService error: $e');
      return null;
    }
  }

  /// Submit user's score to today's national leaderboard.
  Future<void> submitScore(String uid, String userName, double score) async {
    try {
      await _firestore
          .collection('daily_scores')
          .doc(_todayKey)
          .collection('entries')
          .doc(uid)
          .set({
        'score': score,
        'userName': userName,
        'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('submitScore error: $e');
    }
  }

  /// Check if the current user has already completed today's operation.
  Future<bool> hasCompletedToday(String uid) async {
    try {
      final doc = await _firestore
          .collection('daily_scores')
          .doc(_todayKey)
          .collection('entries')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Stream top 20 scores for today's national leaderboard.
  Stream<List<DailyScore>> getLeaderboardStream() {
    return _firestore
        .collection('daily_scores')
        .doc(_todayKey)
        .collection('entries')
        .orderBy('score', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return DailyScore(
                uid: d.id,
                userName: data['userName'] ?? 'Anonymous',
                score: (data['score'] as num?)?.toDouble() ?? 0.0,
                completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
              );
            }).toList());
  }
}

class DailyScore {
  final String uid;
  final String userName;
  final double score;
  final DateTime? completedAt;

  DailyScore({
    required this.uid,
    required this.userName,
    required this.score,
    this.completedAt,
  });
}
