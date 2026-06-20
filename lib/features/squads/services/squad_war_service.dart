import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/squad_entity.dart';

class SquadWarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get or assign a war enemy for this squad.
  /// Returns the enemy SquadEntity, or null if no opponent found yet.
  Future<SquadEntity?> getOrAssignWarEnemy(String squadId) async {
    try {
      final squadDoc = await _firestore.collection('squads').doc(squadId).get();
      if (!squadDoc.exists) return null;

      final squad = SquadEntity.fromMap(squadDoc.data()!);

      // Already has an enemy assigned
      if (squad.enemySquadId != null && squad.enemySquadId!.isNotEmpty) {
        final enemyDoc =
            await _firestore.collection('squads').doc(squad.enemySquadId!).get();
        if (enemyDoc.exists) return SquadEntity.fromMap(enemyDoc.data()!);
      }

      // Find an unmatched squad
      final openSquads = await _firestore
          .collection('squads')
          .where('enemySquadId', isNull: true)
          .limit(5)
          .get();

      final candidates =
          openSquads.docs.where((d) => d.id != squadId).toList();

      if (candidates.isEmpty) return null;

      final enemyId = candidates.first.id;

      // Pair both squads
      final batch = _firestore.batch();
      batch.update(_firestore.collection('squads').doc(squadId), {
        'enemySquadId': enemyId,
        'warScore': 0,
      });
      batch.update(_firestore.collection('squads').doc(enemyId), {
        'enemySquadId': squadId,
        'warScore': 0,
      });
      await batch.commit();

      final enemyDoc = await _firestore.collection('squads').doc(enemyId).get();
      return SquadEntity.fromMap(enemyDoc.data()!);
    } catch (e) {
      debugPrint('SquadWarService.getOrAssignWarEnemy error: $e');
      return null;
    }
  }

  /// Add war score to a squad (called when member passes a quiz).
  Future<void> addWarScore(String squadId, int points) async {
    if (points <= 0) return;
    try {
      await _firestore.collection('squads').doc(squadId).update({
        'warScore': FieldValue.increment(points),
      });
    } catch (e) {
      debugPrint('addWarScore error: $e');
    }
  }

  /// Get real-time stream of your squad and enemy squad for live score view.
  Stream<SquadEntity?> getSquadStream(String squadId) {
    return _firestore.collection('squads').doc(squadId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return SquadEntity.fromMap(doc.data()!);
    });
  }

  /// Resolve the week's war: winner gets territory, scores reset.
  Future<void> resolveWeeklyWar(String squadId) async {
    try {
      final squadDoc = await _firestore.collection('squads').doc(squadId).get();
      if (!squadDoc.exists) return;

      final squad = SquadEntity.fromMap(squadDoc.data()!);
      if (squad.enemySquadId == null) return;

      final enemyDoc =
          await _firestore.collection('squads').doc(squad.enemySquadId!).get();
      if (!enemyDoc.exists) return;

      final enemy = SquadEntity.fromMap(enemyDoc.data()!);

      final String winner =
          squad.warScore >= enemy.warScore ? squadId : squad.enemySquadId!;

      debugPrint('War resolved. Winner: $winner');

      // Reset both squads
      final batch = _firestore.batch();
      batch.update(_firestore.collection('squads').doc(squadId), {
        'warScore': 0,
        'enemySquadId': null,
      });
      batch.update(_firestore.collection('squads').doc(squad.enemySquadId!), {
        'warScore': 0,
        'enemySquadId': null,
      });
      await batch.commit();
    } catch (e) {
      debugPrint('resolveWeeklyWar error: $e');
    }
  }

  /// Calculate days until Monday reset
  int daysUntilMonday() {
    final today = DateTime.now().weekday;
    return today == DateTime.monday ? 7 : (DateTime.monday + 7 - today) % 7;
  }
}
