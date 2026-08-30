import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/interview_models.dart';

final interviewRepositoryProvider = Provider<InterviewRepository>((ref) {
  return InterviewRepository();
});

class InterviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('interview_results');

  /// Saves a completed interview session to Firestore.
  Future<void> saveInterviewSession(InterviewSession session) async {
    await _collection.doc(session.id).set(session.toJson());
  }

  /// Fetches all past interview sessions for a user, sorted by date descending.
  Future<List<InterviewSession>> getInterviewHistory(String uid) async {
    final query = await _collection.where('uid', isEqualTo: uid).orderBy('createdAt', descending: true).get();
    return query.docs.map((doc) => InterviewSession.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  /// Returns the overall score of the most recent interview session, or null if none.
  Future<int?> getLatestInterviewScore(String uid) async {
    final history = await getInterviewHistory(uid);
    if (history.isEmpty) return null;
    return history.first.overallScore;
  }

  /// Returns the average overall score across all interview sessions for a user, or 0 if none.
  Future<int> getInterviewAverage(String uid) async {
    final history = await getInterviewHistory(uid);
    if (history.isEmpty) return 0;
    final total = history.fold<int>(0, (sum, item) => sum + item.overallScore);
    return (total / history.length).round();
  }
}
