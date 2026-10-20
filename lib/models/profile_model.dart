import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel {
  final String uid;
  final String fullName;
  final String branch;
  final String targetSemester;
  final String preferredRole;
  final List<String> targetCompanies;
  final double? cgpa;
  final String? resumeCloudinaryUrl;
  final int? resumeScore;
  final DateTime createdAt;
  final String preferredLanguage;
  final String preferredDifficulty;

  ProfileModel({
    required this.uid,
    required this.fullName,
    required this.branch,
    required this.targetSemester,
    required this.preferredRole,
    required this.targetCompanies,
    this.cgpa,
    this.resumeCloudinaryUrl,
    this.resumeScore,
    required this.createdAt,
    this.preferredLanguage = 'python',
    this.preferredDifficulty = 'Medium',
  });

  bool get isComplete =>
      fullName.trim().isNotEmpty &&
      branch.trim().isNotEmpty &&
      targetSemester.trim().isNotEmpty &&
      preferredRole.trim().isNotEmpty &&
      targetCompanies.isNotEmpty;

  ProfileModel copyWith({
    String? uid,
    String? fullName,
    String? branch,
    String? targetSemester,
    String? preferredRole,
    List<String>? targetCompanies,
    double? cgpa,
    String? resumeCloudinaryUrl,
    int? resumeScore,
    DateTime? createdAt,
    String? preferredLanguage,
    String? preferredDifficulty,
  }) {
    return ProfileModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      branch: branch ?? this.branch,
      targetSemester: targetSemester ?? this.targetSemester,
      preferredRole: preferredRole ?? this.preferredRole,
      targetCompanies: targetCompanies ?? this.targetCompanies,
      cgpa: cgpa ?? this.cgpa,
      resumeCloudinaryUrl: resumeCloudinaryUrl ?? this.resumeCloudinaryUrl,
      resumeScore: resumeScore ?? this.resumeScore,
      createdAt: createdAt ?? this.createdAt,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'fullName': fullName,
      'branch': branch,
      'targetSemester': targetSemester,
      'preferredRole': preferredRole,
      'targetCompanies': targetCompanies,
      'cgpa': cgpa,
      'createdAt': createdAt.toIso8601String(),
      'preferredLanguage': preferredLanguage,
      'preferredDifficulty': preferredDifficulty,
    };
    if (resumeCloudinaryUrl != null) {
      map['resumeCloudinaryUrl'] = resumeCloudinaryUrl;
    }
    if (resumeScore != null) {
      map['resumeScore'] = resumeScore;
    }
    return map;
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    List<String> parseCompanies(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    return ProfileModel(
      uid: map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      branch: map['branch'] as String? ?? 'CSE',
      targetSemester: map['targetSemester'] as String? ?? 'Semester 7',
      preferredRole: map['preferredRole'] as String? ?? 'Software Engineer',
      targetCompanies: parseCompanies(map['targetCompanies']),
      cgpa: (map['cgpa'] is num) ? (map['cgpa'] as num).toDouble() : null,
      resumeCloudinaryUrl: map['resumeCloudinaryUrl'] as String?,
      resumeScore: (map['resumeScore'] is num)
          ? (map['resumeScore'] as num).toInt()
          : null,
      createdAt: parseDate(map['createdAt']),
      preferredLanguage: map['preferredLanguage'] as String? ?? 'python',
      preferredDifficulty: map['preferredDifficulty'] as String? ?? 'Medium',
    );
  }
}
