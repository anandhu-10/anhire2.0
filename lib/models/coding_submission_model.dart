import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionTestResult {
  final int testIndex;
  final bool passed;
  final String stdout;
  final String stderr;
  final String? expected;
  final String? actual;
  final String? input;
  final int? executionTimeMs;
  final String? status;

  SubmissionTestResult({
    required this.testIndex,
    required this.passed,
    required this.stdout,
    required this.stderr,
    this.expected,
    this.actual,
    this.input,
    this.executionTimeMs,
    this.status,
  });

  factory SubmissionTestResult.fromMap(Map<String, dynamic> map) {
    return SubmissionTestResult(
      testIndex: (map['testIndex'] as num?)?.toInt() ?? 0,
      passed: map['passed'] as bool? ?? false,
      stdout: map['stdout']?.toString() ?? '',
      stderr: map['stderr']?.toString() ?? '',
      expected: map['expected']?.toString(),
      actual: map['actual']?.toString(),
      input: map['input']?.toString(),
      executionTimeMs: (map['executionTimeMs'] as num?)?.toInt(),
      status: map['status']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'testIndex': testIndex,
      'passed': passed,
      'stdout': stdout,
      'stderr': stderr,
      if (expected != null) 'expected': expected,
      if (actual != null) 'actual': actual,
      if (input != null) 'input': input,
      if (executionTimeMs != null) 'executionTimeMs': executionTimeMs,
      if (status != null) 'status': status,
    };
  }
}

class CodingSubmissionModel {
  final String? id;
  final String uid;
  final String problemId;
  final String code;
  final String language;
  final List<SubmissionTestResult> testResults;
  final bool passed;
  final int testCasesPassed;
  final int testCasesTotal;
  final String? verdict;
  final DateTime submittedAt;

  CodingSubmissionModel({
    this.id,
    required this.uid,
    required this.problemId,
    required this.code,
    required this.language,
    required this.testResults,
    required this.passed,
    required this.testCasesPassed,
    required this.testCasesTotal,
    this.verdict,
    required this.submittedAt,
  });

  factory CodingSubmissionModel.fromMap(
    Map<String, dynamic> map, [
    String? docId,
  ]) {
    final rawResults = map['testResults'] as List<dynamic>? ?? [];
    DateTime parsedDate;
    if (map['submittedAt'] is Timestamp) {
      parsedDate = (map['submittedAt'] as Timestamp).toDate();
    } else if (map['submittedAt'] is String) {
      parsedDate =
          DateTime.tryParse(map['submittedAt'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return CodingSubmissionModel(
      id: docId ?? map['id']?.toString(),
      uid: map['uid']?.toString() ?? '',
      problemId: map['problemId']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      language: map['language']?.toString() ?? 'python',
      testResults: rawResults
          .map(
            (e) => SubmissionTestResult.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      passed: map['passed'] as bool? ?? false,
      testCasesPassed: (map['testCasesPassed'] as num?)?.toInt() ?? 0,
      testCasesTotal: (map['testCasesTotal'] as num?)?.toInt() ?? 0,
      verdict: map['verdict']?.toString(),
      submittedAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uid': uid,
      'problemId': problemId,
      'code': code,
      'language': language,
      'testResults': testResults.map((e) => e.toMap()).toList(),
      'passed': passed,
      'testCasesPassed': testCasesPassed,
      'testCasesTotal': testCasesTotal,
      if (verdict != null) 'verdict': verdict,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }
}
