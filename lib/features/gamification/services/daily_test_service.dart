import 'package:shared_preferences/shared_preferences.dart';

class DailyTestService {
  static const String _lastPlayedDateKey = 'daily_test_last_played_date';
  static const String _lastScoreKey = 'daily_test_last_score';

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<bool> isPlayedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPlayed = prefs.getString(_lastPlayedDateKey);
    return lastPlayed == _todayKey;
  }

  Future<double?> getTodayScore() async {
    if (!(await isPlayedToday())) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_lastScoreKey);
  }

  Future<void> saveDailyScore(double score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPlayedDateKey, _todayKey);
    await prefs.setDouble(_lastScoreKey, score);
  }
}
