import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of Daily Briefs ordered by timestamp descending
  Stream<List<Map<String, dynamic>>> getDailyBriefStream() {
    return _firestore
        .collection('daily_brief')
        .orderBy('timestamp', descending: true)
        .limit(20) // Keep it light
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data; // Timestamp will need conversion in UI
      }).toList();
    });
  }

  // Admin: Post a new brief
  Future<void> postBrief(String headline, String summary, String? sourceUrl) async {
    try {
      await _firestore.collection('daily_brief').add({
        'headline': headline,
        'summary': summary,
        'sourceUrl': sourceUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('News Posted: $headline');
    } catch (e) {
      debugPrint('Error posting news: $e');
      rethrow;
    }
  }
}
