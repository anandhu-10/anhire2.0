class ProfileModel {
  final String uid;
  final String fullName;
  final String branch;
  final String targetSemester;
  final String preferredRole;
  final List<String> targetCompanies;
  final double? cgpa;
  final String? resumeCloudinaryUrl;
  final DateTime createdAt;

  ProfileModel({
    required this.uid,
    required this.fullName,
    required this.branch,
    required this.targetSemester,
    required this.preferredRole,
    required this.targetCompanies,
    this.cgpa,
    this.resumeCloudinaryUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'branch': branch,
      'targetSemester': targetSemester,
      'preferredRole': preferredRole,
      'targetCompanies': targetCompanies,
      'cgpa': cgpa,
      'resumeCloudinaryUrl': resumeCloudinaryUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      uid: map['uid'],
      fullName: map['fullName'],
      branch: map['branch'],
      targetSemester: map['targetSemester'],
      preferredRole: map['preferredRole'],
      targetCompanies: List<String>.from(map['targetCompanies']),
      cgpa: map['cgpa']?.toDouble(),
      resumeCloudinaryUrl: map['resumeCloudinaryUrl'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
