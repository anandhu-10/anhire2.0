import 'package:cloud_firestore/cloud_firestore.dart';

class AnswerEvaluation {
  final int clarityScore;
  final int correctnessScore;
  final int confidenceScore;
  final int overallScore;
  final String feedback;
  final List<String> strengths;
  final List<String> improvements;

  AnswerEvaluation({
    required this.clarityScore,
    required this.correctnessScore,
    required this.confidenceScore,
    required this.overallScore,
    required this.feedback,
    required this.strengths,
    required this.improvements,
  });

  factory AnswerEvaluation.fromJson(Map<String, dynamic> json) {
    return AnswerEvaluation(
      clarityScore: (json['clarityScore'] as num?)?.toInt() ?? 0,
      correctnessScore: (json['correctnessScore'] as num?)?.toInt() ?? 0,
      confidenceScore: (json['confidenceScore'] as num?)?.toInt() ?? 0,
      overallScore: (json['overallScore'] as num?)?.toInt() ?? 0,
      feedback: json['feedback'] as String? ?? '',
      strengths: (json['strengths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      improvements: (json['improvements'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clarityScore': clarityScore,
      'correctnessScore': correctnessScore,
      'confidenceScore': confidenceScore,
      'overallScore': overallScore,
      'feedback': feedback,
      'strengths': strengths,
      'improvements': improvements,
    };
  }
}

class InterviewQuestion {
  final String id;
  final String type; // technical, behavioral, hr, situational
  final String question;
  final List<String> expectedKeywords;
  final String? userAnswer;
  final AnswerEvaluation? evaluation;

  InterviewQuestion({
    required this.id,
    required this.type,
    required this.question,
    required this.expectedKeywords,
    this.userAnswer,
    this.evaluation,
  });

  InterviewQuestion copyWith({
    String? id,
    String? type,
    String? question,
    List<String>? expectedKeywords,
    String? userAnswer,
    AnswerEvaluation? evaluation,
  }) {
    return InterviewQuestion(
      id: id ?? this.id,
      type: type ?? this.type,
      question: question ?? this.question,
      expectedKeywords: expectedKeywords ?? this.expectedKeywords,
      userAnswer: userAnswer ?? this.userAnswer,
      evaluation: evaluation ?? this.evaluation,
    );
  }

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) {
    return InterviewQuestion(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'technical',
      question: json['question'] as String? ?? '',
      expectedKeywords: (json['expectedKeywords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      userAnswer: json['userAnswer'] as String?,
      evaluation: json['evaluation'] != null
          ? AnswerEvaluation.fromJson(Map<String, dynamic>.from(json['evaluation'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'question': question,
      'expectedKeywords': expectedKeywords,
      'userAnswer': userAnswer,
      'evaluation': evaluation?.toJson(),
    };
  }
}

class InterviewSession {
  final String id;
  final String uid;
  final String role;
  final String company;
  final List<InterviewQuestion> questions;
  final int overallScore;
  final DateTime createdAt;
  final DateTime? completedAt;

  InterviewSession({
    required this.id,
    required this.uid,
    required this.role,
    required this.company,
    required this.questions,
    required this.overallScore,
    required this.createdAt,
    this.completedAt,
  });

  factory InterviewSession.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return InterviewSession(
      id: json['id'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      role: json['role'] as String? ?? '',
      company: json['company'] as String? ?? '',
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => InterviewQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      overallScore: (json['overallScore'] as num?)?.toInt() ?? 0,
      createdAt: parseDateTime(json['createdAt']),
      completedAt: json['completedAt'] != null ? parseDateTime(json['completedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'role': role,
      'company': company,
      'questions': questions.map((q) => q.toJson()).toList(),
      'overallScore': overallScore,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}
