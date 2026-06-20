import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cadre_upsc/core/services/guardrail_service.dart';
import 'package:cadre_upsc/features/ai_sensei/services/gemini_content_service.dart';

class ContentGenerationService {
  static final ContentGenerationService _instance = ContentGenerationService._internal();
  factory ContentGenerationService() => _instance;
  ContentGenerationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiContentService _geminiService = GeminiContentService();
  final GuardrailService _guardrails = GuardrailService();

  bool _isHarvesting = false;
  Timer? _harvestTimer;

  // Entry point: Call this from HomeDashboard.initState
  void startHarvester() {
    // Phase 2: Infinite Library - Continuous Loop
    // Run every 60 seconds
    _harvestTimer?.cancel();
    _harvestTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _runHarvestLoop();
    });
    
    // Run once after UI is fully rendered and stable
    Future.delayed(const Duration(seconds: 30), () {
      _runHarvestLoop();
    });
  }
  
  void stopHarvester() {
    _harvestTimer?.cancel();
    _isHarvesting = false;
  }

  Future<void> _runHarvestLoop() async {
    if (_isHarvesting) return;
    _isHarvesting = true;

    debugPrint("🚜 HARVESTER: Starting Cycle...");

    try {
      // 1. Initialize Guardrails
      await _guardrails.init();

      // 2. Check Permissions
      if (!await _guardrails.canGenerateContent()) {
        debugPrint("🚜 HARVESTER: Guardrails say STOP. Shutting down.");
        _isHarvesting = false;
        return;
      }

      // 3. Fetch Next Task from Queue
      var queueSnapshot = await _firestore
          .collection('syllabus_queue')
          .where('status', isEqualTo: 'pending')
          .orderBy('priority', descending: true)
          .limit(1)
          .get();

      // Phase 2: Auto-Replenish (Infinite Library)
      if (queueSnapshot.docs.isEmpty) {
        debugPrint("🚜 HARVESTER: Queue empty. Initiating Refill Protocol...");
        await _replenishQueue();
        
        // Fetch again
        queueSnapshot = await _firestore
          .collection('syllabus_queue')
          .where('status', isEqualTo: 'pending')
          .orderBy('priority', descending: true)
          .limit(1)
          .get();
          
        if (queueSnapshot.docs.isEmpty) {
             debugPrint("🚜 HARVESTER: Refill failed or delayed. Aborting cycle.");
             _isHarvesting = false;
             return;
        }
      }

      final taskDoc = queueSnapshot.docs.first;
      final taskData = taskDoc.data();
      final String topicId = taskData['topicId'] ?? taskDoc.id; 
      final String subject = taskData['subject'] ?? 'General Studies';
      final String stateName = taskData['stateName'] ?? 'India'; 

      debugPrint("🚜 HARVESTER: Processing Task: $topicId ($subject)");

      // 4. Mark as Processing (Atomic)
      await taskDoc.reference.update({'status': 'processing'});

      // 5. Generate Content
      await _geminiService.generateQuizForTopic(topicId, subject, stateName);

      // 6. Mark as Done & Record Usage
      await taskDoc.reference.update({
        'status': 'done',
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      await _guardrails.recordGeneration();
      debugPrint("🚜 HARVESTER: Task Complete. Sleeping.");

    } catch (e) {
      debugPrint("🚜 HARVESTER ERROR: $e");
    } finally {
      _isHarvesting = false;
    }
  }

  Future<void> _replenishQueue() async {
    // Generate a random high-value topic based on UPSC syllabus
    final random = Random();
    
    // Core Subjects
    final subjects = [
      {'sub': 'History', 'topics': ['Mughal Architecture', 'Gandhian Era', 'Vijayanagara Empire', '1857 Revolt', 'Tribal Uprisings']},
      {'sub': 'Polity', 'topics': ['Preamble', 'Fundamental Rights', 'President Powers', 'Parliamentary Committees', 'Emergency Provisions']},
      {'sub': 'Economy', 'topics': ['Inflation Targeting', 'Banking Reforms', 'Fiscal Deficit', 'WTO & Trade', 'Budget 2026']},
      {'sub': 'Environment', 'topics': ['Climate Change', 'National Parks', 'Biodiversity Hotspots', 'Pollution Control', 'Renewable Energy']},
      {'sub': 'Science', 'topics': ['Space Missions', 'Biotechnology', 'Nanotechnology', 'Defense Missiles', 'AI & Robotics']},
      {'sub': 'Geography', 'topics': ['Monsoon Mechanism', 'Rock Systems', 'Ocean Currents', 'Soil Types', 'Himalayan Rivers']},
    ];
    
    final selection = subjects[random.nextInt(subjects.length)];
    final String subject = selection['sub'] as String;
    final List<String> topics = selection['topics'] as List<String>;
    final String topic = topics[random.nextInt(topics.length)];
    
    // Add to Queue
    debugPrint("🚜 HARVESTER: Adding generated task -> $topic ($subject)");
    
    await _firestore.collection('syllabus_queue').add({
      'topicId': topic,
      'subject': subject,
      'stateName': 'India', // Generic context
      'status': 'pending',
      'priority': 5, // Lower priority than user-requested
      'createdAt': FieldValue.serverTimestamp(),
      'isAutoGenerated': true,
    });
  }
}
