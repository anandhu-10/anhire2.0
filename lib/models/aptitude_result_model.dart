import 'package:cloud_firestore/cloud_firestore.dart';

class AptitudeResultModel {
  final String? id;
  final String uid;
  final int totalQuestions;
  final int correctAnswers;
  final double accuracy;
  final Map<String, dynamic> categoryBreakdown; // e.g. {"quantitative": "7/10", "logical": "6/10"}
  final Map<String, dynamic> filterUsed;
  final DateTime completedAt;

  AptitudeResultModel({
    this.id,
    required this.uid,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracy,
    required this.categoryBreakdown,
    required this.filterUsed,
    required this.completedAt,
  });

  factory AptitudeResultModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parsedDate;
    if (map['completedAt'] is Timestamp) {
      parsedDate = (map['completedAt'] as Timestamp).toDate();
    } else if (map['completedAt'] is String) {
      parsedDate = DateTime.tryParse(map['completedAt'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return AptitudeResultModel(
      id: docId ?? map['id']?.toString(),
      uid: map['uid']?.toString() ?? '',
      totalQuestions: (map['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (map['correctAnswers'] as num?)?.toInt() ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      categoryBreakdown: Map<String, dynamic>.from(map['categoryBreakdown'] as Map? ?? {}),
      filterUsed: Map<String, dynamic>.from(map['filterUsed'] as Map? ?? {}),
      completedAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uid': uid,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'accuracy': accuracy,
      'categoryBreakdown': categoryBreakdown,
      'filterUsed': filterUsed,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }
}
