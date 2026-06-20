import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Update Activity in Squad Log
  Future<void> updateActivity({
    required String userId,
    required String squadId,
    required String userName,
    required String actionType, // 'studying', 'conquered', 'failed'
    required String description, // 'Polity', 'Ancient History Quiz'
  }) async {
    if (squadId.isEmpty) return;

    try {
      final activityRef = _firestore
          .collection('squads')
          .doc(squadId)
          .collection('activity_log')
          .doc(); // Auto-ID

      await activityRef.set({
        'userId': userId,
        'userName': userName,
        'actionType': actionType,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Optional: Cleanup old logs (cloud function better for this, but simplistic approach here)
      // await _cleanupOldLogs(squadId); 

    } catch (e) {
      debugPrint('Error updating activity: $e');
    }
  }
}
