import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cadre_upsc/core/services/notification_service.dart';

class RetentionService {
  static final RetentionService _instance = RetentionService._internal();
  factory RetentionService() => _instance;
  RetentionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notifications = NotificationService();

  // Call on App Resume
  Future<void> onUserSessionStart(String userId) async {
    if (userId.isEmpty) return;
    
    debugPrint("🪖 DRILL SERGEANT: Officer on deck ($userId).");

    // 1. Cancel Nags
    await _notifications.cancelRetentionNotifications();

    // 2. Update Last Active
    try {
      final userRef = _firestore.collection('users').doc(userId);
      
      // We also check for streak updates here, but ideally that's done on specific actions (quiz complete).
      // Here we just mark presence.
      await userRef.update({
        'lastActive': FieldValue.serverTimestamp(),
        'isOnline': true,
      });

      // 3. Reschedule Daily Briefing (Ensure it's always set)
      await _notifications.scheduleDailyBriefing();

    } catch (e) {
      debugPrint("🪖 DRILL SERGEANT FAIL: $e");
    }
  }

  // Call on App Pause/Detach
  Future<void> onUserSessionEnd(String userId) async {
    if (userId.isEmpty) return;
    
    debugPrint("🪖 DRILL SERGEANT: Officer Update - Session Ended.");

    try {
      await _firestore.collection('users').doc(userId).update({
        'lastActive': FieldValue.serverTimestamp(),
        'isOnline': false,
      });

      // 4. Arm Retention Traps
      await _notifications.scheduleStreakProtection(); // Evening Nudge
      await _notifications.scheduleInactivityNudge(); // 3-Day AWOL Warning

    } catch (e) {
      debugPrint("🪖 DRILL SERGEANT FAIL: $e");
    }
  }
}
