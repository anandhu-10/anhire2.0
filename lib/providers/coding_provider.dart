import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/piston_service.dart';
import '../core/services/gemini_service.dart';
import '../models/coding_problem_model.dart';
import '../models/coding_submission_model.dart';
import '../repositories/coding_repository.dart';
import 'auth_provider.dart';
import 'resume_provider.dart';

final codingRepositoryProvider = Provider<CodingRepository>((ref) {
  return CodingRepository();
});

final pistonServiceProvider = Provider<PistonService>((ref) {
  return PistonService();
});

/// Streams all coding problems from Firestore with fallback to assets/data/coding_problems.json.
final codingProblemsProvider = StreamProvider<List<CodingProblemModel>>((ref) async* {
  final repo = ref.watch(codingRepositoryProvider);
  await for (final problems in repo.streamProblems()) {
    if (problems.isEmpty) {
      try {
        final jsonStr = await rootBundle.loadString('assets/data/coding_problems.json');
        final List<dynamic> list = jsonDecode(jsonStr);
        final assetProblems = list.map((e) => CodingProblemModel.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        yield assetProblems;
      } catch (e) {
        yield [];
      }
    } else {
      yield problems;
    }
  }
});

/// Streams all user coding submissions.
final userSubmissionsProvider = StreamProvider<List<CodingSubmissionModel>>((ref) {
  final repo = ref.watch(codingRepositoryProvider);
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return repo.streamUserSubmissions(user.uid);
});

/// Returns status for a problem ('solved', 'attempted', 'unsolved').
final problemStatusProvider = Provider.family<String, String>((ref, problemId) {
  final submissionsAsync = ref.watch(userSubmissionsProvider);
  final submissions = submissionsAsync.value ?? [];
  final problemSubmissions = submissions.where((s) => s.problemId == problemId);

  if (problemSubmissions.isEmpty) return 'unsolved';
  if (problemSubmissions.any((s) => s.passed)) return 'solved';
  return 'attempted';
});

/// Controller for executing user code and submitting solutions.
class ExecutionState {
  final bool isExecuting;
  final String? logs;
  final List<SubmissionTestResult>? testResults;
  final String? aiHint;
  final bool? isSubmitted;
  final bool? allPassed;

  ExecutionState({
    this.isExecuting = false,
    this.logs,
    this.testResults,
    this.aiHint,
    this.isSubmitted,
    this.allPassed,
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? logs,
    List<SubmissionTestResult>? testResults,
    String? aiHint,
    bool? isSubmitted,
    bool? allPassed,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      logs: logs ?? this.logs,
      testResults: testResults ?? this.testResults,
      aiHint: aiHint ?? this.aiHint,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      allPassed: allPassed ?? this.allPassed,
    );
  }
}

class ExecutionNotifier extends Notifier<ExecutionState> {
  @override
  ExecutionState build() {
    return ExecutionState();
  }

  /// Runs code against sample test cases via Piston API.
  Future<void> runCode({
    required CodingProblemModel problem,
    required String language,
    required String code,
  }) async {
    state = state.copyWith(isExecuting: true, logs: "Running sample test cases...\n", aiHint: null);
    final piston = ref.read(pistonServiceProvider);
    final results = <SubmissionTestResult>[];
    bool allPass = true;

    for (int i = 0; i < problem.testCases.length; i++) {
      final testCase = problem.testCases[i];
      final res = await piston.executeCode(
        language: language,
        code: code,
        stdin: testCase.input,
      );

      final expected = testCase.output.trim();
      final actual = res.stdout.trim();

      final isMatch = res.success && expected.replaceAll('\r', '') == actual.replaceAll('\r', '');
      if (!isMatch) allPass = false;

      results.add(SubmissionTestResult(
        testIndex: i + 1,
        passed: isMatch,
        stdout: res.stdout,
        stderr: res.stderr,
        expected: expected,
        actual: actual,
      ));
    }

    state = state.copyWith(
      isExecuting: false,
      testResults: results,
      allPassed: allPass,
      logs: "Execution finished. ${results.where((r) => r.passed).length}/${results.length} sample test cases passed.",
    );

    if (!allPass) {
      await fetchAiHint(problem: problem, language: language, code: code);
    }
  }

  /// Submits solution against all test cases and records to Firestore.
  Future<void> submitCode({
    required CodingProblemModel problem,
    required String language,
    required String code,
  }) async {
    state = state.copyWith(isExecuting: true, logs: "Submitting against all hidden test cases...\n", aiHint: null);
    final piston = ref.read(pistonServiceProvider);
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final results = <SubmissionTestResult>[];
    int passedCount = 0;

    for (int i = 0; i < problem.testCases.length; i++) {
      final testCase = problem.testCases[i];
      final res = await piston.executeCode(
        language: language,
        code: code,
        stdin: testCase.input,
      );

      final expected = testCase.output.trim();
      final actual = res.stdout.trim();
      final isMatch = res.success && expected.replaceAll('\r', '') == actual.replaceAll('\r', '');

      if (isMatch) passedCount++;

      results.add(SubmissionTestResult(
        testIndex: i + 1,
        passed: isMatch,
        stdout: res.stdout,
        stderr: res.stderr,
        expected: expected,
        actual: actual,
      ));
    }

    final isAllPassed = passedCount == problem.testCases.length;

    final submission = CodingSubmissionModel(
      uid: user.uid,
      problemId: problem.id,
      code: code,
      language: language,
      testResults: results,
      passed: isAllPassed,
      testCasesPassed: passedCount,
      testCasesTotal: problem.testCases.length,
      submittedAt: DateTime.now(),
    );

    final repo = ref.read(codingRepositoryProvider);
    await repo.saveSubmission(submission);

    state = state.copyWith(
      isExecuting: false,
      testResults: results,
      allPassed: isAllPassed,
      isSubmitted: true,
      logs: "Submission Recorded! $passedCount/${problem.testCases.length} test cases passed. Status: ${isAllPassed ? 'PASSED' : 'FAILED'}",
    );

    if (!isAllPassed) {
      await fetchAiHint(problem: problem, language: language, code: code);
    }
  }

  /// Calls Gemini to get AI hint on code failure.
  Future<void> fetchAiHint({
    required CodingProblemModel problem,
    required String language,
    required String code,
  }) async {
    final gemini = ref.read(geminiServiceProvider);
    final failedResult = state.testResults?.firstWhere((r) => !r.passed, orElse: () => state.testResults!.first);
    final errorText = failedResult != null
        ? "Expected: ${failedResult.expected}\nActual: ${failedResult.actual}\nStderr: ${failedResult.stderr}"
        : "Failed test cases.";

    final hint = await gemini.generateCodingFailureHint(
      problemTitle: problem.title,
      problemDescription: problem.description,
      language: language,
      code: code,
      errorOutput: errorText,
    );

    state = state.copyWith(aiHint: hint);
  }
}

final executionProvider = NotifierProvider<ExecutionNotifier, ExecutionState>(() {
  return ExecutionNotifier();
});
