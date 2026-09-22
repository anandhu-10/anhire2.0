import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/roadmap_model.dart';

abstract class IRoadmapRepository {
  Stream<Roadmap?> getRoadmapStream(String uid);
  Future<Roadmap?> getRoadmap(String uid);
  Future<void> saveRoadmap(Roadmap roadmap);
  Future<void> updateTaskCompletion({
    required String uid,
    required int weekIndex,
    required int taskIndex,
    required bool completed,
  });
}

class RoadmapRepository implements IRoadmapRepository {
  final FirebaseFirestore _firestore;

  RoadmapRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _roadmapsRef =>
      _firestore.collection('roadmaps');

  @override
  Stream<Roadmap?> getRoadmapStream(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _roadmapsRef.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return Roadmap.fromFirestore(snapshot.data()!, uid);
    });
  }

  @override
  Future<Roadmap?> getRoadmap(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final doc = await _roadmapsRef.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return Roadmap.fromFirestore(doc.data()!, uid);
    } catch (e) {
      debugPrint("RoadmapRepository getRoadmap error: $e");
      return null;
    }
  }

  @override
  Future<void> saveRoadmap(Roadmap roadmap) async {
    try {
      await _roadmapsRef.doc(roadmap.uid).set(
            roadmap.toFirestore(),
            SetOptions(merge: true),
          );
      debugPrint("Roadmap saved successfully for ${roadmap.uid}");
    } catch (e) {
      debugPrint("RoadmapRepository saveRoadmap error: $e");
      rethrow;
    }
  }

  @override
  Future<void> updateTaskCompletion({
    required String uid,
    required int weekIndex,
    required int taskIndex,
    required bool completed,
  }) async {
    try {
      final roadmap = await getRoadmap(uid);
      if (roadmap == null) return;

      final updatedWeeks = List<RoadmapWeek>.from(roadmap.weeks);
      if (weekIndex < 0 || weekIndex >= updatedWeeks.length) return;

      final targetWeek = updatedWeeks[weekIndex];
      final updatedTasks = List<RoadmapTask>.from(targetWeek.tasks);
      if (taskIndex < 0 || taskIndex >= updatedTasks.length) return;

      updatedTasks[taskIndex] =
          updatedTasks[taskIndex].copyWith(completed: completed);
      updatedWeeks[weekIndex] = targetWeek.copyWith(tasks: updatedTasks);

      int totalTasks = 0;
      int completedTasks = 0;
      for (var w in updatedWeeks) {
        totalTasks += w.totalTasksCount;
        completedTasks += w.completedTasksCount;
      }
      final newProgress = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks);

      final updatedRoadmap = roadmap.copyWith(
        weeks: updatedWeeks,
        overallProgress: newProgress,
        updatedAt: DateTime.now(),
      );

      await saveRoadmap(updatedRoadmap);
    } catch (e) {
      debugPrint("RoadmapRepository updateTaskCompletion error: $e");
      rethrow;
    }
  }
}
