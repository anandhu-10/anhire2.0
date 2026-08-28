import 'package:cloud_firestore/cloud_firestore.dart';

class ResumeSectionFeedback {
  final String name;
  final int score;
  final String feedback;

  ResumeSectionFeedback({
    required this.name,
    required this.score,
    required this.feedback,
  });

  factory ResumeSectionFeedback.fromMap(Map<String, dynamic> map) {
    return ResumeSectionFeedback(
      name: map['name'] as String? ?? 'General',
      score: (map['score'] as num?)?.toInt() ?? 0,
      feedback: map['feedback'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'score': score,
      'feedback': feedback,
    };
  }
}

class ResumeReportModel {
  final String id;
  final String uid;
  final int overallScore;
  final List<ResumeSectionFeedback> sections;
  final List<String> missingKeywords;
  final List<String> suggestions;
  final String? cloudinaryUrl;
  final DateTime createdAt;

  ResumeReportModel({
    required this.id,
    required this.uid,
    required this.overallScore,
    required this.sections,
    required this.missingKeywords,
    required this.suggestions,
    this.cloudinaryUrl,
    required this.createdAt,
  });

  factory ResumeReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final sectionsRaw = data['sections'] as List<dynamic>? ?? [];
    final missingKeywordsRaw = data['missingKeywords'] as List<dynamic>? ?? [];
    final suggestionsRaw = data['suggestions'] as List<dynamic>? ?? [];

    return ResumeReportModel(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      overallScore: (data['overallScore'] as num?)?.toInt() ?? 0,
      sections: sectionsRaw
          .map((s) => ResumeSectionFeedback.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
      missingKeywords: missingKeywordsRaw.map((e) => e.toString()).toList(),
      suggestions: suggestionsRaw.map((e) => e.toString()).toList(),
      cloudinaryUrl: data['cloudinaryUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'overallScore': overallScore,
      'sections': sections.map((s) => s.toMap()).toList(),
      'missingKeywords': missingKeywords,
      'suggestions': suggestions,
      'cloudinaryUrl': cloudinaryUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
