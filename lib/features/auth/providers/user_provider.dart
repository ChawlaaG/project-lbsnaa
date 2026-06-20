import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadre_upsc/core/models/user_entity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/offline_mode_service.dart';

// A simple provider to hold the current user state
// In a real app, this would fetch from Firebase
class UserNotifier extends StateNotifier<UserEntity> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserNotifier() : super(const UserEntity(uid: 'guest', currentLevel: 1, xpPoints: 0, territoryUnlocked: ['IN-UT'])) {
    _initUser();
  }

  void _initUser() {
    // Listen to Auth Changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // If logged in, fetch/sync with Firestore
        _syncWithFirestore(user.uid);
      } else {
        // Guest mode or reset
        state = const UserEntity(uid: 'guest', currentLevel: 1, xpPoints: 0, territoryUnlocked: ['IN-UT']);
      }
    });
  }

  StreamSubscription? _userSubscription;

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _syncWithFirestore(String uid) {
    _userSubscription?.cancel();

    // Fix: Do NOT pre-load Hive cache unconditionally. Doing so causes a
    // flash of stale user data (old XP/level/streaks) on first launch after
    // a new APK install, because the cache from the old version is shown
    // before the Firestore stream fires with fresh data.
    //
    // Hive cache is now only used as a fallback inside the stream's error
    // handler — i.e., only when the device is truly offline.

    _userSubscription = _firestore.collection('users').doc(uid).snapshots().listen((doc) async {
      if (doc.exists && doc.data() != null) {
        state = UserEntity.fromMap(doc.data()!);
        // Phase 2: Bunker Mode - Update Cache with latest data
        OfflineModeService().cacheUserProfile(doc.data()!);
      } else if (!doc.exists) {
        // Create new user doc if doesn't exist (First Login)
        final newUser = UserEntity(
          uid: uid,
          currentLevel: 1,
          xpPoints: 100, // Welcome bonus
          territoryUnlocked: ['IN-KL'],
        );
        await _firestore.collection('users').doc(uid).set(newUser.toMap());
        state = newUser;
        OfflineModeService().cacheUserProfile(newUser.toMap());
      }
    }, onError: (e) {
      debugPrint('Error syncing user stream: $e — falling back to Hive cache.');
      // Fallback: Only use Hive cache when Firestore is unreachable (offline)
      final cachedData = OfflineModeService().getCachedUserProfile();
      if (cachedData != null) {
        debugPrint("BUNKER MODE: Loaded Profile from Hive.");
        state = UserEntity.fromMap(cachedData);
      }
    });
  }

  void addXp(int amount) {
    state = state.copyWith(xpPoints: state.xpPoints + amount);
    // Sync to Firestore
    if (state.uid != 'guest') {
       _firestore.collection('users').doc(state.uid).update({
         'xpPoints': FieldValue.increment(amount)
       });
    }
  }
  
  void levelUp() {
    state = state.copyWith(currentLevel: state.currentLevel + 1);
     if (state.uid != 'guest') {
       _firestore.collection('users').doc(state.uid).update({
         'currentLevel': FieldValue.increment(1)
       });
    }
  }

  void updateProfile(String name, String bio, String targetYear) {
    state = state.copyWith(name: name, bio: bio, targetYear: targetYear);
  }

  void updateAvatar(String url) {
    state = state.copyWith(avatarUrl: url);
  }

  void updateDifficulty(String level) {
    state = state.copyWith(difficultyLevel: level);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserEntity>((ref) {
  return UserNotifier();
});
