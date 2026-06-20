import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class GuardrailService {
  static final GuardrailService _instance = GuardrailService._internal();
  factory GuardrailService() => _instance;
  GuardrailService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Default Limits
  static const int _defaultDailyLimit = 100; // Increased from 10 to 100 to prevent hitting fallback quickly
  static const String _configDoc = 'system/config';
  static const String _prefKeyDailyCount = 'daily_gen_count';
  static const String _prefKeyDate = 'daily_gen_date';

  // State
  int _maxDailyGenerations = _defaultDailyLimit;
  bool _killSwitchActive = false;
  DateTime? _lastConfigFetch;

  Future<void> init() async {
    await _fetchRemoteConfig();
  }

  Future<void> _fetchRemoteConfig() async {
    // Cache config for 1 hour to save reads
    if (_lastConfigFetch != null && 
        DateTime.now().difference(_lastConfigFetch!).inMinutes < 60) {
      return;
    }

    try {
      final doc = await _firestore.doc(_configDoc).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _maxDailyGenerations = data['max_daily_generations_per_user'] ?? _defaultDailyLimit;
        _killSwitchActive = data['safety_kill_switch'] ?? false;
        _lastConfigFetch = DateTime.now();
        debugPrint("🛡️ GUARDRAILS: Updated. Limit: $_maxDailyGenerations, KillSwitch: $_killSwitchActive");
      }
    } catch (e) {
      debugPrint("🛡️ GUARDRAILS: Config fetch failed, using defaults. $e");
    }
  }

  Future<bool> canGenerateContent() async {
    if (_killSwitchActive) {
      debugPrint("🛡️ GUARDRAILS: Kill Switch Active. Generation Blocked.");
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final String today = DateTime.now().toIso8601String().split('T')[0];
    final String? lastDate = prefs.getString(_prefKeyDate);
    
    int currentCount = 0;

    if (lastDate == today) {
      currentCount = prefs.getInt(_prefKeyDailyCount) ?? 0;
    } else {
      // Reset for new day
      await prefs.setString(_prefKeyDate, today);
      await prefs.setInt(_prefKeyDailyCount, 0);
    }

    if (currentCount >= _maxDailyGenerations) {
      debugPrint("🛡️ GUARDRAILS: Daily Quota Exceeded ($currentCount/$_maxDailyGenerations).");
      return false;
    }

    return true;
  }

  Future<void> recordGeneration() async {
    final prefs = await SharedPreferences.getInstance();
    final int current = prefs.getInt(_prefKeyDailyCount) ?? 0;
    await prefs.setInt(_prefKeyDailyCount, current + 1);
    debugPrint("🛡️ GUARDRAILS: Generation Recorded. (${current + 1}/$_maxDailyGenerations)");
  }
}
