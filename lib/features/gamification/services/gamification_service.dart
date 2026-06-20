import 'package:cadre_upsc/core/models/user_entity.dart';

class GamificationService {
  static const int xpPerMinute = 10;
  static const int streakResetHours = 24;

  // Calculate XP for a session
  int calculateXP(int minutesStudied) {
    return minutesStudied * xpPerMinute;
  }

  // Check if user should level up
  bool shouldLevelUp(int currentXp, int currentLevel) {
    // Level N requires 1000 * N XP
    int requiredXp = 1000 * currentLevel;
    return currentXp >= requiredXp;
  }

  // Calculate next level
  int calculateNextLevel(int currentLevel) {
    return currentLevel + 1;
  }

  // Logic to handle streak updates
  // This would typically involve checking the last study timestamp
  // For now, we'll just provide a helper to check if streak is valid
  bool isStreakActive(DateTime lastActivityTime) {
    final difference = DateTime.now().difference(lastActivityTime);
    return difference.inHours < streakResetHours;
  }

  // Simulate processing a study session
  UserEntity processStudySession(UserEntity user, int minutesStudied) {
    int earnedXp = calculateXP(minutesStudied);
    int newXp = user.xpPoints + earnedXp;
    int newLevel = user.currentLevel;

    // Check for level up loop (in case multiple levels gained)
    // Simple version: just check next level threshold
    while (shouldLevelUp(newXp, newLevel)) {
      newLevel = calculateNextLevel(newLevel);
    }

    return user.copyWith(
      xpPoints: newXp,
      currentLevel: newLevel,
      // Streak logic requires timestamp, assuming basic increment for now
      currentStreak: user.currentStreak + 1, 
    );
  }
}
