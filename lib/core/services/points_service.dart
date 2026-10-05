import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/gamification.dart';
import '../../models/gamification_models.dart';

class PointsService {
  final FirebaseFirestore _firestore;

  PointsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DateTime _getStartOfISOWeek(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Calculates points from first-time events across submissions, tests, interviews, and resume.
  Future<UserPoints> calculateUserPoints(String uid) async {
    if (uid.isEmpty) {
      return UserPoints(
        uid: uid,
        totalPoints: 0,
        weeklyPoints: 0,
        weekStartDate: _getStartOfISOWeek(DateTime.now()),
        codingPoints: 0,
        aptitudePoints: 0,
        interviewPoints: 0,
        resumePoints: 0,
        updatedAt: DateTime.now(),
      );
    }

    try {
      int codingPts = 0;
      int aptitudePts = 0;
      int interviewPts = 0;
      int resumePts = 0;

      // 1. Scan coding_submissions for unique passed problems
      final codingSubmissionsSnap = await _firestore
          .collection('coding_submissions')
          .where('uid', isEqualTo: uid)
          .get();

      final solvedProblemIds = <String>{};
      for (var doc in codingSubmissionsSnap.docs) {
        final data = doc.data();
        if (data['passed'] == true) {
          final pid = data['problemId']?.toString() ?? '';
          if (pid.isNotEmpty) {
            solvedProblemIds.add(pid);
          }
        }
      }

      // Fetch difficulty for solved problems
      if (solvedProblemIds.isNotEmpty) {
        final problemsSnap = await _firestore.collection('coding_problems').get();
        final problemDiffMap = <String, String>{};
        for (var pDoc in problemsSnap.docs) {
          problemDiffMap[pDoc.id] = (pDoc.data()['difficulty'] as String? ?? 'easy').toLowerCase();
        }

        for (var pid in solvedProblemIds) {
          final diff = problemDiffMap[pid] ?? 'easy';
          if (diff == 'hard') {
            codingPts += PointsRules.hardProblem;
          } else if (diff == 'medium') {
            codingPts += PointsRules.mediumProblem;
          } else {
            codingPts += PointsRules.easyProblem;
          }
        }
      }

      // 2. Scan aptitude_results
      final aptitudeSnap = await _firestore
          .collection('aptitude_results')
          .where('uid', isEqualTo: uid)
          .get();

      for (var doc in aptitudeSnap.docs) {
        final accuracy = (doc.data()['accuracy'] as num?)?.toDouble() ?? 0.0;
        if (accuracy >= 100.0) {
          aptitudePts += PointsRules.aptitudePerfectTest;
        } else if (accuracy >= 70.0) {
          aptitudePts += PointsRules.aptitudeGoodTest;
        }
      }

      // 3. Scan interview_results
      final interviewSnap = await _firestore
          .collection('interview_results')
          .where('uid', isEqualTo: uid)
          .get();

      for (var doc in interviewSnap.docs) {
        interviewPts += PointsRules.interviewCompleted;
        final score = (doc.data()['overallScore'] as num?)?.toInt() ?? 0;
        if (score >= 70) {
          interviewPts += PointsRules.interviewStrong;
        }
      }

      // 4. Scan resume_reports
      final resumeSnap = await _firestore
          .collection('resume_reports')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (resumeSnap.docs.isNotEmpty) {
        resumePts = PointsRules.resumeUploaded;
      }

      final totalPts = codingPts + aptitudePts + interviewPts + resumePts;

      // Handle Weekly Points reset
      final currentWeekStart = _getStartOfISOWeek(DateTime.now());
      final existingDoc = await _firestore.collection('user_points').doc(uid).get();

      int weeklyPts = 0;
      if (existingDoc.exists && existingDoc.data() != null) {
        final existingData = existingDoc.data()!;
        final storedWeekStart = (existingData['weekStartDate'] is Timestamp)
            ? (existingData['weekStartDate'] as Timestamp).toDate()
            : DateTime.now();

        if (storedWeekStart.isBefore(currentWeekStart)) {
          // New week started -> reset weekly points
          weeklyPts = 0;
        } else {
          // Same week -> compute gained points
          final prevTotal = (existingData['totalPoints'] as num?)?.toInt() ?? 0;
          final prevWeekly = (existingData['weeklyPoints'] as num?)?.toInt() ?? 0;
          final diff = totalPts - prevTotal;
          weeklyPts = (prevWeekly + (diff > 0 ? diff : 0));
        }
      } else {
        weeklyPts = totalPts;
      }

      final userPoints = UserPoints(
        uid: uid,
        totalPoints: totalPts,
        weeklyPoints: weeklyPts,
        weekStartDate: currentWeekStart,
        codingPoints: codingPts,
        aptitudePoints: aptitudePts,
        interviewPoints: interviewPts,
        resumePoints: resumePts,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('user_points').doc(uid).set(
            userPoints.toFirestore(),
            SetOptions(merge: true),
          );

      return userPoints;
    } catch (e, st) {
      debugPrint("PointsService calculateUserPoints error: $e\n$st");
      return UserPoints(
        uid: uid,
        totalPoints: 0,
        weeklyPoints: 0,
        weekStartDate: _getStartOfISOWeek(DateTime.now()),
        codingPoints: 0,
        aptitudePoints: 0,
        interviewPoints: 0,
        resumePoints: 0,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Checks milestone criteria and unlocks any newly earned achievement badges.
  Future<List<BadgeDefinition>> checkAndUnlockBadges(String uid) async {
    if (uid.isEmpty) return [];

    try {
      // 1. Fetch user metrics
      final codingSubmissionsSnap = await _firestore
          .collection('coding_submissions')
          .where('uid', isEqualTo: uid)
          .get();

      final solvedProblemIds = <String>{};
      for (var doc in codingSubmissionsSnap.docs) {
        if (doc.data()['passed'] == true) {
          final pid = doc.data()['problemId']?.toString() ?? '';
          if (pid.isNotEmpty) solvedProblemIds.add(pid);
        }
      }
      final solvedCount = solvedProblemIds.length;

      final aptitudeSnap = await _firestore
          .collection('aptitude_results')
          .where('uid', isEqualTo: uid)
          .get();

      final aptitudeCount = aptitudeSnap.docs.length;
      bool hasPerfectAptitude = false;
      for (var doc in aptitudeSnap.docs) {
        final acc = (doc.data()['accuracy'] as num?)?.toDouble() ?? 0.0;
        if (acc >= 100.0) {
          hasPerfectAptitude = true;
          break;
        }
      }

      final interviewSnap = await _firestore
          .collection('interview_results')
          .where('uid', isEqualTo: uid)
          .get();

      final interviewCount = interviewSnap.docs.length;
      double interviewAvg = 0.0;
      if (interviewCount > 0) {
        int totalScore = 0;
        for (var doc in interviewSnap.docs) {
          totalScore += (doc.data()['overallScore'] as num?)?.toInt() ?? 0;
        }
        interviewAvg = totalScore / interviewCount;
      }

      final resumeSnap = await _firestore
          .collection('resume_reports')
          .where('uid', isEqualTo: uid)
          .get();

      int resumeScore = 0;
      if (resumeSnap.docs.isNotEmpty) {
        resumeScore = (resumeSnap.docs.first.data()['overallScore'] as num?)?.toInt() ?? 0;
      }

      // 2. Fetch current unlocked badges
      final badgeDocRef = _firestore.collection('user_badges').doc(uid);
      final badgeDocSnap = await badgeDocRef.get();

      final existingBadgeIds = <String>{};
      final currentBadgesList = <UserBadge>[];

      if (badgeDocSnap.exists && badgeDocSnap.data() != null) {
        final docObj = UserBadgesDoc.fromFirestore(badgeDocSnap.data()!, uid);
        currentBadgesList.addAll(docObj.badges);
        for (var b in docObj.badges) {
          existingBadgeIds.add(b.id);
        }
      }

      final newlyUnlocked = <BadgeDefinition>[];

      void tryUnlock(String id, bool condition) {
        if (condition && !existingBadgeIds.contains(id)) {
          final def = BadgeDefinition.allBadges.firstWhere((b) => b.id == id);
          newlyUnlocked.add(def);
          currentBadgesList.add(UserBadge(
            id: def.id,
            name: def.name,
            description: def.description,
            unlockedAt: DateTime.now(),
          ));
        }
      }

      // 3. Evaluate criteria
      tryUnlock('first_solve', solvedCount >= 1);
      tryUnlock('warming_up', solvedCount >= 5);
      tryUnlock('code_warrior', solvedCount >= 15);
      tryUnlock('code_master', solvedCount >= 30);
      tryUnlock('sharp_mind', aptitudeCount >= 10);
      tryUnlock('perfect_score', hasPerfectAptitude);
      tryUnlock('interview_ready', interviewCount >= 1);
      tryUnlock('interview_star', interviewAvg >= 75);
      tryUnlock('resume_ready', resumeScore >= 70);
      tryUnlock('all_rounder', solvedCount >= 10 && aptitudeCount >= 5 && interviewCount >= 2);

      if (newlyUnlocked.isNotEmpty) {
        final updatedDoc = UserBadgesDoc(uid: uid, badges: currentBadgesList);
        await badgeDocRef.set(updatedDoc.toFirestore(), SetOptions(merge: true));
        debugPrint("Unlocked ${newlyUnlocked.length} new badges for $uid");
      }

      return newlyUnlocked;
    } catch (e, st) {
      debugPrint("PointsService checkAndUnlockBadges error: $e\n$st");
      return [];
    }
  }
}
