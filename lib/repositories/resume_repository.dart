import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resume_report_model.dart';

class ResumeRepository {
  final FirebaseFirestore _firestore;

  ResumeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Saves a new ATS resume report to Firestore and updates user profile score.
  Future<void> saveResumeReport(ResumeReportModel report) async {
    final reportRef = _firestore.collection('resume_reports').doc(report.id.isNotEmpty ? report.id : null);
    await reportRef.set(report.toFirestore());

    // Update profile resumeScore & url
    await _firestore.collection('profiles').doc(report.uid).set({
      'resumeScore': report.overallScore,
      if (report.cloudinaryUrl != null) 'resumeCloudinaryUrl': report.cloudinaryUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Streams the latest resume report for the given user uid.
  Stream<ResumeReportModel?> latestReportStream(String uid) {
    return _firestore
        .collection('resume_reports')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ResumeReportModel.fromFirestore(snapshot.docs.first);
    });
  }
}
