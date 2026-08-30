import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/aptitude_problem_model.dart';
import '../models/aptitude_result_model.dart';

class AptitudeRepository {
  final FirebaseFirestore _firestore;

  AptitudeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Streams all aptitude questions.
  Stream<List<AptitudeProblemModel>> streamQuestions() {
    return _firestore.collection('aptitude_problems').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AptitudeProblemModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Streams user's past aptitude results.
  Stream<List<AptitudeResultModel>> streamUserResults(String uid) {
    return _firestore
        .collection('aptitude_results')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AptitudeResultModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return list;
    });
  }

  /// Saves an aptitude test result.
  Future<void> saveResult(AptitudeResultModel result) async {
    final ref = _firestore.collection('aptitude_results').doc();
    await ref.set(result.toMap());
  }

  /// Admin: Save single question.
  Future<void> saveQuestion(AptitudeProblemModel question) async {
    final docId = question.id.isNotEmpty
        ? question.id
        : 'ap_${DateTime.now().millisecondsSinceEpoch}';
    await _firestore.collection('aptitude_problems').doc(docId).set(question.toMap());
  }

  /// Admin: Save batch of questions.
  Future<void> saveQuestionsBatch(List<AptitudeProblemModel> questions) async {
    final batch = _firestore.batch();
    for (final q in questions) {
      final docId = q.id.isNotEmpty
          ? q.id
          : 'ap_${DateTime.now().millisecondsSinceEpoch}_${q.hashCode.abs()}';
      final ref = _firestore.collection('aptitude_problems').doc(docId);
      batch.set(ref, q.toMap());
    }
    await batch.commit();
  }

  /// Admin: Get total question count.
  Future<int> getQuestionCount() async {
    final snapshot = await _firestore.collection('aptitude_problems').get();
    return snapshot.docs.length;
  }

  /// Admin: Delete all questions.
  Future<void> deleteAllQuestions() async {
    final snapshot = await _firestore.collection('aptitude_problems').get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
