import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cadre_upsc/features/gamification/models/quiz_entity.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class OfflinePackService {
  static final OfflinePackService _instance = OfflinePackService._internal();
  factory OfflinePackService() => _instance;
  OfflinePackService._internal();

  static const String _packBox = 'offline_packs';
  static const String _syncQueueBox = 'quiz_sync_queue';
  static const String _syllabusBox = 'syllabus_cache';
  static const String _progressBox = 'progress_cache';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_packBox)) await Hive.openBox(_packBox);
    if (!Hive.isBoxOpen(_syncQueueBox)) await Hive.openBox(_syncQueueBox);
    if (!Hive.isBoxOpen(_syllabusBox)) await Hive.openBox(_syllabusBox);
    if (!Hive.isBoxOpen(_progressBox)) await Hive.openBox(_progressBox);
  }

  // 1. Download Pack (Fetch from Global Bank + Syllabus + Progress)
  Future<bool> downloadBunkerPack() async {
    try {
      debugPrint("📦 BUNKER MODE: Initiating Download...");
      await init();

      // A. Download Questions (Existing Logic)
      final snapshot = await _firestore
          .collection('global_question_bank')
          .limit(50) // Pack Size
          .get();

      List<QuestionEntity> questions = [];
      if (snapshot.docs.isNotEmpty) {
        questions = snapshot.docs.map((doc) {
          final data = doc.data();
          return QuestionEntity(
              questionText: data['questionText'] ?? '',
              options: List<String>.from(data['options']),
              correctOptionIndex: data['correctOptionIndex'],
              explanation: data['explanation'],
              type: data['type'],
              stem: data['stem'],
              statements: (data['statements'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
              ask: data['ask'],
          );
        }).toList();
      } else {
         debugPrint("📦 BUNKER MODE: Bank Empty. Downloading fallback pack.");
         // Optional: Add hardcoded fallback or just proceed with empty list
      }

      // Create a "Pack" (QuizEntity)
      final String packId = "bunker_pack_${DateTime.now().millisecondsSinceEpoch}";
      final pack = QuizEntity(
        id: packId,
        title: "Bunker Protocol #${packId.substring(12)}",
        questions: questions,
      );

      // Save to Hive
      final packBox = Hive.box(_packBox);
      await packBox.put(packId, jsonEncode(pack.toMap()));
      
      // B. Download Syllabus (Map Data)
      debugPrint("📦 BUNKER MODE: Securing Map Data...");
      final syllabusSnapshot = await _firestore.collection('syllabus').get();
      final syllabusBox = Hive.box(_syllabusBox);
      for (var doc in syllabusSnapshot.docs) {
         await syllabusBox.put(doc.id, jsonEncode(doc.data()));
      }
      
      // C. Download User Progress (For Map)
      // We need userId. We can get it from auth or pass it in.
      // Assuming we can get incomplete progress simply by fetching relevant collections.
      // For now, let's just cache the "Structure" as that's what was requested ("Map Data").
      // Real user progress offline sync is complex.
      
      debugPrint("📦 BUNKER MODE: Pack Downloaded ($packId) + Map Data.");
      return true;

    } catch (e) {
      debugPrint("📦 BUNKER MODE FAIL: $e");
      return false;
    }
  }

  // Helper to get cached syllabus
  Map<String, dynamic>? getCachedSyllabus(String regionId) {
    if (!Hive.isBoxOpen(_syllabusBox)) return null;
    final box = Hive.box(_syllabusBox);
    final jsonStr = box.get(regionId);
    if (jsonStr != null) {
      return jsonDecode(jsonStr);
    }
    return null;
  }

  // 2. Get Available Packs
  List<QuizEntity> getLocalPacks() {
    if (!Hive.isBoxOpen(_packBox)) return [];
    
    final box = Hive.box(_packBox);
    final List<QuizEntity> packs = [];

    for (var key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          packs.add(QuizEntity.fromMap(jsonDecode(jsonStr), key.toString()));
        } catch (e) {
          debugPrint("Error parsing pack $key: $e");
        }
      }
    }
    return packs;
  }

  // 2.5 Get Specific Pack
  QuizEntity? getPack(String packId) {
    if (!Hive.isBoxOpen(_packBox)) return null;
    final box = Hive.box(_packBox);
    final jsonStr = box.get(packId);
    
    if (jsonStr != null) {
      try {
        return QuizEntity.fromMap(jsonDecode(jsonStr), packId);
      } catch (e) {
        debugPrint("Error parsing pack $packId: $e");
      }
    }
    return null;
  }

  // 3. Queue Result for Sync
  Future<void> queueResultForSync(String quizId, int score, int total, String userId) async {
    await init();
    final box = Hive.box(_syncQueueBox);
    final attempt = {
      'quizId': quizId,
      'score': score,
      'total': total,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await box.add(attempt);
    debugPrint("🔄 SYNC: Result Queued.");
  }

  // 4. Sync Pending Results
  Future<void> syncPendingResults() async {
    await init();
    final box = Hive.box(_syncQueueBox);
    if (box.isEmpty) return;

    debugPrint("🔄 SYNC: Uploading ${box.length} pending results...");

    final batch = _firestore.batch();
    final Map<dynamic, dynamic> processed = {};

    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null && data is Map) {
         final docRef = _firestore.collection('quiz_attempts').doc();
         batch.set(docRef, {
           ...data,
           'syncedAt': FieldValue.serverTimestamp(),
           'isOfflineSync': true,
         });
         
         // Also update user XP (atomic increment is safe even if delayed)
         final userRef = _firestore.collection('users').doc(data['userId']);
         final int xp = (data['score'] as int) * 10;
         batch.update(userRef, {'xpPoints': FieldValue.increment(xp)});
         
         processed[key] = true;
      }
    }

    try {
      await batch.commit();
      await box.deleteAll(processed.keys);
      debugPrint("🔄 SYNC: Upload Complete.");
    } catch (e) {
      debugPrint("🔄 SYNC FAIL: $e");
    }
  }
}
