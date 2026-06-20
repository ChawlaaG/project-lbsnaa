import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Needed for Colors
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadre_upsc/features/syllabus_map/models/syllabus_model.dart';
import 'package:cadre_upsc/features/syllabus_map/models/syllabus_region.dart';

final syllabusServiceProvider = Provider<SyllabusService>((ref) {
  return SyllabusService();
});

class SyllabusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hardcoded syllabus data for Dashboard Map
  // This serves the SyllabusMapWidget
  List<SyllabusRegion> getDashboardRegions() {
    return [
      const SyllabusRegion(
        id: 'IN-KL', // Kerala (Environment) - START
        subjectName: 'Kerala: Environment',
        isLocked: false,
        associatedColor: Colors.green, // Green
      ),
      const SyllabusRegion(
        id: 'IN-MH', // Maharashtra (Economy)
        subjectName: 'Maharashtra: Economy',
        isLocked: true,
        associatedColor: Colors.blue, // Blue
         subRegions: [
          SyllabusSubRegion(id: 'macro', title: 'Macro Economics'),
          SyllabusSubRegion(id: 'micro', title: 'Micro Economics'),
        ],
      ),
      const SyllabusRegion(
        id: 'IN-BR', // Bihar (History)
        subjectName: 'Bihar: History',
        isLocked: true,
        associatedColor: Colors.orange, // Orange
        subRegions: [
          SyllabusSubRegion(id: 'anc_hist', title: 'Ancient History'),
          SyllabusSubRegion(id: 'med_hist', title: 'Medieval History'),
          SyllabusSubRegion(id: 'mod_hist', title: 'Modern History'),
        ],
      ),
      const SyllabusRegion(
        id: 'IN-DL', // Delhi (Polity)
        subjectName: 'Delhi: Polity',
        isLocked: true,
        associatedColor: Colors.red, // Red
        subRegions: [
          SyllabusSubRegion(id: 'const', title: 'Constitution'),
          SyllabusSubRegion(id: 'gov', title: 'Governance'),
        ],
      ),
      const SyllabusRegion(
        id: 'IN-UT', // Uttarakhand (LBSNAA) - GOAL
        subjectName: 'Uttarakhand: Foundation', 
        isLocked: true, 
        associatedColor: Colors.amber, // Gold
        subRegions: [
          SyllabusSubRegion(id: 'lbsnaa_101', title: 'LBSNAA Basics', isCompleted: true),
          SyllabusSubRegion(id: 'ethics', title: 'Ethics & Integrity', isCompleted: false),
        ],
      ),
    ];
  }

  // Fetch a specific region's syllabus (e.g., 'north_history')
  // merging with user's progress
  Future<SyllabusSubject> getSyllabusForRegion(String regionId, String userId) async {
    try {
      // 1. Fetch Subject Data
      final docSnapshot = await _firestore.collection('syllabus').doc(regionId).get();
      
      if (!docSnapshot.exists) {
        // Fallback or just throw
        throw Exception('Syllabus not found for region: $regionId. (Did seeding run?)');
      }

      final data = docSnapshot.data()!;
      var subject = SyllabusSubject.fromFirestore(regionId, data);

      // 2. Fetch User Progress
      final userProgressDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(regionId)
          .get();

      if (userProgressDoc.exists) {
        final completedTopics = List<String>.from(userProgressDoc.data()?['completed_topics'] ?? []);
        
        // Merge progress
        final updatedTopics = subject.topics.map((topic) {
          return topic.copyWith(isCompleted: completedTopics.contains(topic.title));
        }).toList();
        
        subject = SyllabusSubject(id: subject.id, subject: subject.subject, topics: updatedTopics);
      }

      return subject;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception("Access Denied: Please check Firestore Security Rules. You likely need to allow reading 'syllabus' and 'users'.");
      }
      rethrow;
    } catch (e) {
      throw Exception("Error loading syllabus: $e");
    }
  }

  // Toggle completion status
  Future<void> toggleTopicCompletion(String userId, String regionId, String topicTitle, bool isCompleted) async {
    final progressRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(regionId);

    if (isCompleted) {
      // Add to completed list
      await progressRef.set({
        'completed_topics': FieldValue.arrayUnion([topicTitle])
      }, SetOptions(merge: true));

      // Store completion timestamp in a subcollection so Mission Log shows real dates
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('completions')
          .doc('${regionId}_$topicTitle')
          .set({
        'topicTitle': topicTitle,
        'regionId': regionId,
        'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update global XP
      _firestore.collection('users').doc(userId).update({
        'xpPoints': FieldValue.increment(50),
        'lastActive': FieldValue.serverTimestamp(),
      });

      // Check for region completion/unlock
      await checkAndUnlockNextRegion(userId, regionId);

    } else {
      // Remove from list
      await progressRef.update({
        'completed_topics': FieldValue.arrayRemove([topicTitle])
      });
      // Optionally delete the completion record
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('completions')
          .doc('${regionId}_$topicTitle')
          .delete();
    }
  }

  // Check if region is fully completed and unlock next
  Future<void> checkAndUnlockNextRegion(String userId, String currentRegionId) async {
    // 1. Get total topics for this region
    final syllabusDoc = await _firestore.collection('syllabus').doc(currentRegionId).get();
    if (!syllabusDoc.exists) return;
    
    final topics = List<Map<String, dynamic>>.from(syllabusDoc.data()?['topics'] ?? []);
    final totalTopicCount = topics.length;

    // 2. Get user completed topics
    final progressDoc = await _firestore.collection('users').doc(userId).collection('progress').doc(currentRegionId).get();
    final completedTopics = List<String>.from(progressDoc.data()?['completed_topics'] ?? []);

    if (completedTopics.length >= totalTopicCount) {
      // Region Complete! Unlock next.
      final nextRegionId = _getNextRegionId(currentRegionId);
      if (nextRegionId != null) {
        await _firestore.collection('users').doc(userId).update({
          'territoryUnlocked': FieldValue.arrayUnion([nextRegionId])
        });
      }
    }
  }

  String? _getNextRegionId(String current) {
    // Progression: Kerala (start) → Maharashtra → Bihar → Delhi → Uttarakhand (goal)
    const order = [
      'IN-KL', // Start — Environment (unlocked by default)
      'IN-MH', // Economy
      'IN-BR', // History
      'IN-DL', // Polity
      'IN-UT', // Foundation — GOAL
    ];
    final index = order.indexOf(current);
    if (index != -1 && index < order.length - 1) {
      return order[index + 1];
    }
    return null;
  }
}
