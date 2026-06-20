import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum StreakStatus { maintained, extended, broken }

class StreakCheckResult {
  final StreakStatus status;
  final int currentStreak;
  final int previousStreak;

  const StreakCheckResult({
    required this.status,
    required this.currentStreak,
    required this.previousStreak,
  });
}

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Check and update the user's streak on app open.
  /// Returns a StreakCheckResult indicating what happened.
  Future<StreakCheckResult> checkAndUpdateStreak(
    String uid,
    String? lastActiveDateStr,
    int currentStreak,
    int currentLevel,
  ) async {
    final today = _todayKey;

    // Already checked today — no change
    if (lastActiveDateStr == today) {
      return StreakCheckResult(
        status: StreakStatus.maintained,
        currentStreak: currentStreak,
        previousStreak: currentStreak,
      );
    }

    final previousStreak = currentStreak;
    int newStreak;
    int newLevel = currentLevel;
    StreakStatus status;

    if (lastActiveDateStr == null) {
      // First time
      newStreak = 1;
      status = StreakStatus.extended;
    } else {
      final lastDate = DateTime.tryParse(lastActiveDateStr);
      if (lastDate == null) {
        newStreak = 1;
        status = StreakStatus.extended;
      } else {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final lastDateOnly = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final yesterdayOnly = DateTime(yesterday.year, yesterday.month, yesterday.day);

        if (lastDateOnly == yesterdayOnly) {
          // Consecutive — extend streak
          newStreak = currentStreak + 1;
          status = StreakStatus.extended;
        } else {
          // Missed day(s) — break streak, apply rank decay
          newStreak = 1;
          newLevel = (currentLevel - 1).clamp(1, 999);
          status = StreakStatus.broken;
        }
      }
    }

    // Write to Firestore
    try {
      final updates = <String, dynamic>{
        'currentStreak': newStreak,
        'lastActiveDate': today,
        'lastActive': FieldValue.serverTimestamp(),
      };
      if (status == StreakStatus.broken) {
        updates['currentLevel'] = newLevel;
      }
      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      debugPrint('StreakService update error: $e');
    }

    return StreakCheckResult(
      status: status,
      currentStreak: newStreak,
      previousStreak: previousStreak,
    );
  }
}
