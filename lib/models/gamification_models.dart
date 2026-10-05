import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/gamification.dart';

class UserPoints {
  final String uid;
  final int totalPoints;
  final int weeklyPoints;
  final DateTime weekStartDate;
  final int codingPoints;
  final int aptitudePoints;
  final int interviewPoints;
  final int resumePoints;
  final DateTime updatedAt;

  UserPoints({
    required this.uid,
    required this.totalPoints,
    required this.weeklyPoints,
    required this.weekStartDate,
    required this.codingPoints,
    required this.aptitudePoints,
    required this.interviewPoints,
    required this.resumePoints,
    required this.updatedAt,
  });

  MedalTier get tier => MedalTier.fromPoints(totalPoints);

  factory UserPoints.fromFirestore(Map<String, dynamic> data, String uid) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserPoints(
      uid: uid,
      totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
      weeklyPoints: (data['weeklyPoints'] as num?)?.toInt() ?? 0,
      weekStartDate: parseDate(data['weekStartDate']),
      codingPoints: (data['codingPoints'] as num?)?.toInt() ?? 0,
      aptitudePoints: (data['aptitudePoints'] as num?)?.toInt() ?? 0,
      interviewPoints: (data['interviewPoints'] as num?)?.toInt() ?? 0,
      resumePoints: (data['resumePoints'] as num?)?.toInt() ?? 0,
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'totalPoints': totalPoints,
      'weeklyPoints': weeklyPoints,
      'weekStartDate': Timestamp.fromDate(weekStartDate),
      'codingPoints': codingPoints,
      'aptitudePoints': aptitudePoints,
      'interviewPoints': interviewPoints,
      'resumePoints': resumePoints,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserPoints copyWith({
    String? uid,
    int? totalPoints,
    int? weeklyPoints,
    DateTime? weekStartDate,
    int? codingPoints,
    int? aptitudePoints,
    int? interviewPoints,
    int? resumePoints,
    DateTime? updatedAt,
  }) {
    return UserPoints(
      uid: uid ?? this.uid,
      totalPoints: totalPoints ?? this.totalPoints,
      weeklyPoints: weeklyPoints ?? this.weeklyPoints,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      codingPoints: codingPoints ?? this.codingPoints,
      aptitudePoints: aptitudePoints ?? this.aptitudePoints,
      interviewPoints: interviewPoints ?? this.interviewPoints,
      resumePoints: resumePoints ?? this.resumePoints,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserBadge {
  final String id;
  final String name;
  final String description;
  final DateTime unlockedAt;

  UserBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.unlockedAt,
  });

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserBadge(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      unlockedAt: parseDate(map['unlockedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
    };
  }
}

class UserBadgesDoc {
  final String uid;
  final List<UserBadge> badges;

  UserBadgesDoc({
    required this.uid,
    required this.badges,
  });

  factory UserBadgesDoc.fromFirestore(Map<String, dynamic> data, String uid) {
    final rawList = data['badges'] as List<dynamic>? ?? [];
    final list = rawList
        .map((e) => UserBadge.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return UserBadgesDoc(uid: uid, badges: list);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'badges': badges.map((b) => b.toMap()).toList(),
    };
  }
}
