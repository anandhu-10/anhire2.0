import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gamification_models.dart';
import '../core/constants/gamification.dart';
import '../core/services/points_service.dart';
import 'auth_provider.dart';

final pointsServiceProvider = Provider<PointsService>((ref) {
  return PointsService();
});

final userPointsProvider = StreamProvider.family<UserPoints?, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('user_points')
      .doc(uid)
      .snapshots()
      .map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    return UserPoints.fromFirestore(snap.data()!, uid);
  });
});

final userBadgesProvider = StreamProvider.family<UserBadgesDoc?, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('user_badges')
      .doc(uid)
      .snapshots()
      .map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    return UserBadgesDoc.fromFirestore(snap.data()!, uid);
  });
});

/// Query top 50 user_points ordered by totalPoints DESC for All-Time Leaderboard.
final leaderboardProvider = FutureProvider<List<UserPoints>>((ref) async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('user_points')
        .orderBy('totalPoints', descending: true)
        .limit(50)
        .get();

    return snap.docs
        .map((doc) => UserPoints.fromFirestore(doc.data(), doc.id))
        .toList();
  } catch (e) {
    debugPrint("leaderboardProvider error: $e");
    return [];
  }
});

/// Query top 50 user_points ordered by weeklyPoints DESC for Weekly Leaderboard.
final weeklyLeaderboardProvider = FutureProvider<List<UserPoints>>((ref) async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('user_points')
        .orderBy('weeklyPoints', descending: true)
        .limit(50)
        .get();

    return snap.docs
        .map((doc) => UserPoints.fromFirestore(doc.data(), doc.id))
        .toList();
  } catch (e) {
    debugPrint("weeklyLeaderboardProvider error: $e");
    return [];
  }
});

class GamificationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<List<BadgeDefinition>> syncPointsAndCheckBadges() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return [];

    state = const AsyncValue.loading();
    try {
      final pointsService = ref.read(pointsServiceProvider);
      await pointsService.calculateUserPoints(user.uid);
      final unlocked = await pointsService.checkAndUnlockBadges(user.uid);
      state = const AsyncValue.data(null);
      return unlocked;
    } catch (e, st) {
      debugPrint("GamificationController sync error: $e\n$st");
      state = AsyncValue.error(e, st);
      return [];
    }
  }
}

final gamificationControllerProvider =
    AsyncNotifierProvider<GamificationController, void>(() {
  return GamificationController();
});
