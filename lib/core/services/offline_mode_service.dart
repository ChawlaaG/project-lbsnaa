import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class OfflineModeService {
  static const String _briefingBox = 'daily_briefing';
  static const String _profileBox = 'user_profile_cache';

  // Singleton
  static final OfflineModeService _instance = OfflineModeService._internal();
  factory OfflineModeService() => _instance;
  OfflineModeService._internal();

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_briefingBox);
    await Hive.openBox(_profileBox);
    debugPrint("BUNKER MODE: Hive Initialized.");
  }

  // --- Quiz Cache ---
  Future<void> cacheQuiz(String quizId, String jsonContent) async {
    final box = Hive.box(_briefingBox);
    await box.put('quiz_$quizId', jsonContent);
    await box.put('timestamp_$quizId', DateTime.now().toIso8601String());
  }

  String? getCachedQuiz(String quizId) {
    final box = Hive.box(_briefingBox);
    return box.get('quiz_$quizId');
  }

  // --- Daily Briefing Cache (Specific Slot) ---
  Future<void> cacheDailyBriefing(String content) async {
    final box = Hive.box(_briefingBox);
    await box.put('today', content);
    await box.put('timestamp', DateTime.now().toIso8601String());
  }

  String? getCachedBriefing() {
    final box = Hive.box(_briefingBox);
    return box.get('today');
  }

  // --- User Profile Cache (Simple Map for now) ---
  Future<void> cacheUserProfile(Map<String, dynamic> userData) async {
    final box = Hive.box(_profileBox);
    await box.put('data', userData);
  }

  Map<String, dynamic>? getCachedUserProfile() {
    final box = Hive.box(_profileBox);
    final data = box.get('data');
    if (data != null && data is Map) {
       return Map<String, dynamic>.from(data);
    }
    return null;
  }
}
