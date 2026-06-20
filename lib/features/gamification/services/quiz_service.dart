import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_entity.dart';
import '../../ai_sensei/services/gemini_content_service.dart';
import '../../squads/services/squad_service.dart';
import '../../syllabus_map/services/syllabus_service.dart';
import 'package:flutter/foundation.dart';


class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch Quiz by Topic ID
  Future<QuizEntity?> getQuiz(String topicId) async {
    try {
      final doc = await _firestore.collection('quizzes').doc(topicId).get();
      if (doc.exists && doc.data() != null) {
        return QuizEntity.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Fetch or Generate Quiz (Infinite Archives)
  Future<QuizEntity?> getOrGenerateQuiz(String topicId, String subject, String stateName, {String difficulty = 'Officer'}) async {
    try {
      // 1. Check Cache (Firestore) - SKIP for Map Topics (Live Missions)
      // "IN-" prefix indicates a Map Region (e.g. IN-RJ_History)
      // We want these to ALWAYS be fresh.
      if (!topicId.startsWith('IN-')) {
        final doc = await _firestore.collection('quizzes').doc(topicId).get();
        if (doc.exists && doc.data() != null) {
          return QuizEntity.fromMap(doc.data()!, doc.id);
        }
      }

      // 2. Generate via AI (Gemini)
      final geminiService = GeminiContentService();
      final quiz = await geminiService.generateQuizForTopic(topicId, subject, stateName, difficulty: difficulty);
      return quiz;
    } catch (e, stackTrace) {
      debugPrint('Error getting/generating quiz: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  // Save Quiz Result & Update Core Stats
  Future<void> saveQuizResult(String uid, String topicId, double score, int totalQuestions, bool passed, {String? subject, String? squadId, List<String>? answeredQuestionHashes}) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Save specific quiz result
      final resultRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('quiz_results')
          .doc(topicId);

      batch.set(resultRef, {
        'score': score,
        'totalQuestions': totalQuestions,
        'passed': passed,
        'lastAttempt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 1b. Track answered question IDs to prevent repeats
      if (answeredQuestionHashes != null && answeredQuestionHashes.isNotEmpty) {
        final answeredRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('answered_questions')
            .doc(topicId);
        batch.set(answeredRef, {
          'hashes': FieldValue.arrayUnion(answeredQuestionHashes),
          'lastAttempt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 2. Update User Aggregated Stats (Operation Truth Serum)
      final userRef = _firestore.collection('users').doc(uid);
      
      final Map<String, dynamic> updates = {
        'xpPoints': FieldValue.increment(score > 0 ? score.round() : 0),
        'totalQuizzesTaken': FieldValue.increment(1),
      };

      if (subject != null) {
        // Atomic increments for specific subject
        updates['stats.$subject.attempted'] = FieldValue.increment(totalQuestions);
        updates['stats.$subject.correct'] = FieldValue.increment(score > 0 ? (score / 2).round() : 0); // Approx correct count
      }
      
      batch.update(userRef, updates);

      // 3. Update Squad XP (if applicable)
      if (squadId != null && score > 0) {
        // We can't batch across services easily without passing refs, 
        // but let's do it separately or just call service. 
        // Batch limits: 500 ops. We are fine. 
        // However, SquadService logic might be complex. Let's call it *after* batch commit to keep it decoupled.
      }

      await batch.commit();

      // 4. Trigger Squad Update (Fire and Forget)
      if (squadId != null && score > 0) {
         SquadService().updateSquadXP(squadId, score.round());
      }

      // 5. Trigger Territory Unlock (Map Region Quizzes only, when passed)
      // topicId format for map regions is 'IN-XX_Subject' (e.g. 'IN-KL_Environment')
      if (passed && topicId.startsWith('IN-')) {
        // Extract the region id (e.g. 'IN-KL') from 'IN-KL_Environment'
        final regionId = topicId.contains('_') ? topicId.split('_').first : topicId;
        await SyllabusService().checkAndUnlockNextRegion(uid, regionId);
        debugPrint('Territory unlock check triggered for region: $regionId');
      }

    } catch (e) {
      debugPrint('Error saving quiz result: $e');
    }
  }

  // Check if user passed the quiz
  Future<bool> hasPassedQuiz(String uid, String topicId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('quiz_results')
          .doc(topicId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return doc.data()!['passed'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getAnsweredQuestionIds(String uid, {String? topicId}) async {
    try {
      if (topicId != null) {
        // Fetch hashes for a specific topic
        final doc = await _firestore
            .collection('users')
            .doc(uid)
            .collection('answered_questions')
            .doc(topicId)
            .get();
        if (doc.exists && doc.data() != null) {
          return List<String>.from(doc.data()!['hashes'] ?? []);
        }
      } else {
        // Fetch ALL answered hashes across all topics
        final snapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('answered_questions')
            .get();
        final allHashes = <String>{};
        for (final doc in snapshot.docs) {
          allHashes.addAll(List<String>.from(doc.data()['hashes'] ?? []));
        }
        return allHashes.toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching answered questions: $e');
      return [];
    }
  }
}
