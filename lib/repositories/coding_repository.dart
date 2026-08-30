import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coding_problem_model.dart';
import '../models/coding_submission_model.dart';

class CodingRepository {
  final FirebaseFirestore _firestore;

  CodingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches all coding problems from Firestore.
  Stream<List<CodingProblemModel>> streamProblems() {
    return _firestore.collection('coding_problems').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CodingProblemModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  /// Fetches a single coding problem by ID.
  Future<CodingProblemModel?> getProblemById(String problemId) async {
    final doc = await _firestore.collection('coding_problems').doc(problemId).get();
    if (!doc.exists || doc.data() == null) return null;
    return CodingProblemModel.fromMap(doc.data()!, doc.id);
  }

  /// Streams user's coding submissions.
  Stream<List<CodingSubmissionModel>> streamUserSubmissions(String uid) {
    return _firestore
        .collection('coding_submissions')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CodingSubmissionModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    });
  }

  /// Saves a user submission to Firestore.
  Future<void> saveSubmission(CodingSubmissionModel submission) async {
    final ref = _firestore.collection('coding_submissions').doc();
    await ref.set(submission.toMap());
  }
}
