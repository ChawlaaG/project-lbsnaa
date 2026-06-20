import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch questions for a specific subject
  Future<List<Map<String, dynamic>>> getQuestions(String subject, {int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('subject', isEqualTo: subject)
          .limit(limit)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      // Fallback or rethrow
      return [];
    }
  }

  // Fetch random questions (Mixed Bag)
  Future<List<Map<String, dynamic>>> getRandomQuestions({int limit = 5}) async {
    try {
      // Note: Firestore doesn't support random native queries easily.
      // For prototype, we'll fetch a batch and shuffle client-side, 
      // or just fetch from a 'mixed' collection if we structure it that way.
      // Simplest for now: just fetch generic questions.
      final snapshot = await _firestore
          .collection('questions')
          .limit(20) // Fetch more to shuffle
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      final allQuestions = snapshot.docs.map((doc) => doc.data()).toList();
      allQuestions.shuffle();
      return allQuestions.take(limit).toList();
    } catch (e) {
      return [];
    }
  }
}
