import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/squad_entity.dart';

class SquadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new squad
  Future<SquadEntity> createSquad(String name, String leaderId) async {
    if (name.isEmpty) {
      throw Exception('Squad name cannot be empty');
    }

    final newSquadRef = _firestore.collection('squads').doc();
    
    final newSquad = SquadEntity(
      id: newSquadRef.id,
      name: name,
      memberIds: [leaderId],
      squadXp: 0,
    );

    await newSquadRef.set(newSquad.toMap());

    // Update user's squadId
    await _firestore.collection('users').doc(leaderId).update({'squadId': newSquadRef.id});

    return newSquad;
  }

  // Join an existing squad
  Future<void> joinSquad(String squadId, String userId) async {
    return _firestore.runTransaction((transaction) async {
      final squadRef = _firestore.collection('squads').doc(squadId);
      final squadDoc = await transaction.get(squadRef);

      if (!squadDoc.exists) {
        throw Exception('Squad not found');
      }

      final squad = SquadEntity.fromMap(squadDoc.data()!);

      if (squad.memberIds.length >= 5) {
        throw Exception('Squad is full (Max 5 residents allowed)');
      }

      if (squad.memberIds.contains(userId)) {
        throw Exception('User is already in this squad');
      }

      // Add user to squad
      transaction.update(squadRef, {
        'memberIds': FieldValue.arrayUnion([userId])
      });

      // Update user's squadId
      final userRef = _firestore.collection('users').doc(userId);
      transaction.update(userRef, {'squadId': squadId});
    });
  }
  
  // Get Squad Stream (Real-time updates)
  Stream<SquadEntity?> getSquadStream(String squadId) {
    return _firestore.collection('squads').doc(squadId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return SquadEntity.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Get All Squads (Limit 10 for "Join Squad" list)
  Future<List<SquadEntity>> getAvailableSquads() async {
    final snapshot = await _firestore.collection('squads').limit(10).get();
    return snapshot.docs.map((doc) => SquadEntity.fromMap(doc.data())).toList();
  }

  // Leave a squad
  Future<void> leaveSquad(String squadId, String userId) async {
    return _firestore.runTransaction((transaction) async {
      final squadRef = _firestore.collection('squads').doc(squadId);
      final squadDoc = await transaction.get(squadRef);

      if (!squadDoc.exists) {
        throw Exception('Squad not found');
      }

      final squad = SquadEntity.fromMap(squadDoc.data()!);

      if (!squad.memberIds.contains(userId)) {
        throw Exception('User is not in this squad');
      }

      // Remove user from squad
      transaction.update(squadRef, {
        'memberIds': FieldValue.arrayRemove([userId])
      });

      // Update user's squadId (set to null)
      final userRef = _firestore.collection('users').doc(userId);
      transaction.update(userRef, {'squadId': null});
    });
  }

  // Phase 15: Squad Comms (Real-Time Chat)
  Stream<List<Map<String, dynamic>>> getMessagesStream(String squadId) {
    return _firestore
        .collection('squads')
        .doc(squadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50) // Phase 18-B: Data Valve
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> sendMessage(String collectionPath, String text, String userId, String userName, {bool isSystem = false}) async {
    // Note: collectionPath passed from UI is 'squads/{id}/messages'
    // But firestore.collection() expects a path.
    // If the UI passes 'squads/XYZ/messages', we can use it directly via firestore.collectionGroup? No. 
    // firestore.collection(path) works with subcollection paths like 'col/doc/subcol'.
    
    await _firestore.collection(collectionPath).add({
      'text': text,
      'senderId': userId,
      'senderName': userName,
      'timestamp': FieldValue.serverTimestamp(),
      'isSystem': isSystem,
    });
  }


  // Phase 16: True "Wolf Pack" Presence (Real Activity Feed)
  // Read from subcollection 'activity_log'
  Stream<List<SquadActivity>> getSquadActivityStream(String squadId) {
    return _firestore
        .collection('squads')
        .doc(squadId)
        .collection('activity_log')
        .orderBy('timestamp', descending: true)
        .limit(10) // Show last 10 activities
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SquadActivity(
          userName: data['userName'] ?? 'Unknown',
          actionType: data['actionType'] ?? 'studying',
          description: data['description'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  // Phase 43: Squad XP Updates (Real-Time Growth)
  Future<void> updateSquadXP(String squadId, int xpGained) async {
    if (xpGained <= 0) return;

    try {
      // 1. Increment Squad XP
      // 2. Increment Weekly Hours (Simulated: 20 XP = 1 minute approx for this gamification model)
      //    We can treat score as minutes for simplicity or just a separate metric.
      //    Let's say 1 point = 0.5 minutes of study impact.
      
      final double hoursToAdd = (xpGained * 0.5) / 60; 

      await _firestore.collection('squads').doc(squadId).update({
        'squadXp': FieldValue.increment(xpGained),
        'currentWeeklyHours': FieldValue.increment(hoursToAdd),
      });

    } catch (e) {
      // Fail silently for gamification updates
    }
  }

  // Phase 19: Squad Leaderboard
  Stream<List<SquadEntity>> getSquadLeaderboardStream() {
    return _firestore
        .collection('squads')
        .orderBy('squadXp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SquadEntity.fromMap(doc.data())).toList();
    });
  }
}

class SquadActivity {
  final String userName;
  final String actionType; // 'studying', 'conquered', 'failed'
  final String description;
  final DateTime timestamp;

  SquadActivity({
    required this.userName, 
    required this.actionType,
    required this.description, 
    required this.timestamp, 
  });
  
  // Helper to format time relative (e.g. "2m ago")
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
