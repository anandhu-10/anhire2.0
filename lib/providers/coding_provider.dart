import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/gamification.dart';
import '../core/services/piston_service.dart';
import '../models/coding_problem_model.dart';
import '../models/coding_submission_model.dart';
import '../repositories/coding_repository.dart';
import 'auth_provider.dart';
import 'gamification_provider.dart';
import 'resume_provider.dart';

final codingRepositoryProvider = Provider<CodingRepository>((ref) {
  return CodingRepository();
});

final pistonServiceProvider = Provider<PistonService>((ref) {
  return PistonService();
});

/// Streams all coding problems from Firestore with fallback to assets/data/coding_problems.json.
final codingProblemsProvider = StreamProvider<List<CodingProblemModel>>((
  ref,
) async* {
  final repo = ref.watch(codingRepositoryProvider);
  await for (final problems in repo.streamProblems()) {
    if (problems.isEmpty) {
      try {
        final jsonStr = await rootBundle.loadString(
          'assets/data/coding_problems.json',
        );
        final List<dynamic> list = jsonDecode(jsonStr);
        final assetProblems = list
            .map(
              (e) => CodingProblemModel.fromMap(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
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
final userSubmissionsProvider = StreamProvider<List<CodingSubmissionModel>>((
  ref,
) {
  final repo = ref.watch(codingRepositoryProvider);
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return repo.streamUserSubmissions(user.uid);
});

/// Submissions specifically for a single problem.
final problemSubmissionsProvider =
    Provider.family<List<CodingSubmissionModel>, String>((ref, problemId) {
      final submissionsAsync = ref.watch(userSubmissionsProvider);
      final submissions = submissionsAsync.value ?? [];
      return submissions.where((s) => s.problemId == problemId).toList();
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
  final bool isSubmitting;
  final String? logs;
  final List<SubmissionTestResult>? testResults;
  final String? aiHint;
  final bool isLoadingAiHint;
  final bool? isSubmitted;
  final bool? allPassed;
  final String? overallVerdict;
  final int? executionTimeMs;
  final String? customOutput;
  final bool isFirstTimeSolve;
  final int pointsEarned;

  ExecutionState({
    this.isExecuting = false,
    this.isSubmitting = false,
    this.logs,
    this.testResults,
    this.aiHint,
    this.isLoadingAiHint = false,
    this.isSubmitted,
    this.allPassed,
    this.overallVerdict,
    this.executionTimeMs,
    this.customOutput,
    this.isFirstTimeSolve = false,
    this.pointsEarned = 0,
  });

  ExecutionState copyWith({
    bool? isExecuting,
    bool? isSubmitting,
    String? logs,
    List<SubmissionTestResult>? testResults,
    String? aiHint,
    bool? isLoadingAiHint,
    bool? isSubmitted,
    bool? allPassed,
    String? overallVerdict,
    int? executionTimeMs,
    String? customOutput,
    bool? isFirstTimeSolve,
    int? pointsEarned,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      logs: logs ?? this.logs,
      testResults: testResults ?? this.testResults,
      aiHint: aiHint ?? this.aiHint,
      isLoadingAiHint: isLoadingAiHint ?? this.isLoadingAiHint,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      allPassed: allPassed ?? this.allPassed,
      overallVerdict: overallVerdict ?? this.overallVerdict,
      executionTimeMs: executionTimeMs ?? this.executionTimeMs,
      customOutput: customOutput ?? this.customOutput,
      isFirstTimeSolve: isFirstTimeSolve ?? this.isFirstTimeSolve,
      pointsEarned: pointsEarned ?? this.pointsEarned,
    );
  }

  void reset() {}
}

class ExecutionNotifier extends Notifier<ExecutionState> {
  @override
  ExecutionState build() {
    return ExecutionState();
  }

  void clearResults() {
    state = ExecutionState();
  }

  /// Normalizes output string for fair comparison (strips trailing whitespace, CRLF, and spaces inside JSON arrays).
  static String normalizeOutput(String raw) {
    return raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n')
        .trim();
  }

  /// Runs code against custom stdin input.
  Future<void> runCustomInput({
    required CodingProblemModel problem,
    required String language,
    required String code,
    required String customStdin,
  }) async {
    state = state.copyWith(
      isExecuting: true,
      logs: "Executing code against custom input...\n",
      customOutput: null,
    );

    final piston = ref.read(pistonServiceProvider);
    final res = await piston.executeCode(
      language: language,
      code: code,
      stdin: customStdin,
    );

    final outputText = res.output.isNotEmpty
        ? res.output
        : (res.stdout.isNotEmpty
              ? res.stdout
              : (res.stderr.isNotEmpty ? res.stderr : "(No output produced)"));

    state = state.copyWith(
      isExecuting: false,
      logs: res.success
          ? "Execution successful."
          : "Execution finished with errors.",
      customOutput: outputText,
      executionTimeMs: res.executionTimeMs,
    );
  }

  /// Runs code against sample test cases via Piston API (Run Code).
  /// Run Code does NOT mark problem as solved and does NOT award points.
  Future<void> runCode({
    required CodingProblemModel problem,
    required String language,
    required String code,
  }) async {
    state = state.copyWith(
      isExecuting: true,
      isSubmitting: false,
      logs: "Running sample test cases...\n",
      aiHint: null,
      isSubmitted: false,
    );

    final piston = ref.read(pistonServiceProvider);
    final results = <SubmissionTestResult>[];
    bool allPass = true;
    int totalElapsedMs = 0;
    String verdict = 'Accepted';

    for (int i = 0; i < problem.testCases.length; i++) {
      final testCase = problem.testCases[i];
      final res = await piston.executeCode(
        language: language,
        code: code,
        stdin: testCase.input,
      );

      totalElapsedMs += res.executionTimeMs ?? 0;
      final expectedNorm = normalizeOutput(testCase.output);
      final actualNorm = normalizeOutput(res.stdout);

      bool isMatch = false;
      String testStatus = 'Passed';

      if (res.isCompilationError) {
        testStatus = 'Compilation Error';
        verdict = 'Compilation Error';
        allPass = false;
      } else if (res.isTimeout) {
        testStatus = 'Time Limit Exceeded';
        verdict = 'Time Limit Exceeded';
        allPass = false;
      } else if (!res.success && res.stderr.isNotEmpty) {
        testStatus = 'Runtime Error';
        verdict = 'Runtime Error';
        allPass = false;
      } else if (expectedNorm == actualNorm) {
        isMatch = true;
        testStatus = 'Passed';
      } else {
        testStatus = 'Wrong Answer';
        if (verdict == 'Accepted') verdict = 'Wrong Answer';
        allPass = false;
      }

      results.add(
        SubmissionTestResult(
          testIndex: i + 1,
          passed: isMatch,
          stdout: res.stdout,
          stderr: res.stderr,
          expected: testCase.output,
          actual: res.stdout.isNotEmpty
              ? res.stdout
              : (res.stderr.isNotEmpty ? res.stderr : ''),
          input: testCase.input,
          executionTimeMs: res.executionTimeMs,
          status: testStatus,
        ),
      );
    }

    final passedCount = results.where((r) => r.passed).length;
    final finalVerdict = allPass ? 'Accepted' : verdict;

    state = state.copyWith(
      isExecuting: false,
      testResults: results,
      allPassed: allPass,
      overallVerdict: finalVerdict,
      executionTimeMs: totalElapsedMs,
      logs:
          "Execution finished. $passedCount/${results.length} sample test cases passed.",
    );
  }

  /// Submits solution against all test cases, evaluates verdict, awards points (first solve only),
  /// and records submission to Firestore.
  Future<void> submitCode({
    required CodingProblemModel problem,
    required String language,
    required String code,
  }) async {
    state = state.copyWith(
      isExecuting: true,
      isSubmitting: true,
      logs: "Evaluating solution against all test cases...\n",
      aiHint: null,
      isSubmitted: false,
    );

    final piston = ref.read(pistonServiceProvider);
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      state = state.copyWith(
        isExecuting: false,
        isSubmitting: false,
        logs: "Error: User is not authenticated.",
      );
      return;
    }

    final results = <SubmissionTestResult>[];
    int passedCount = 0;
    int totalElapsedMs = 0;
    String verdict = 'Accepted';
    bool allPass = true;

    for (int i = 0; i < problem.testCases.length; i++) {
      final testCase = problem.testCases[i];
      final res = await piston.executeCode(
        language: language,
        code: code,
        stdin: testCase.input,
      );

      totalElapsedMs += res.executionTimeMs ?? 0;
      final expectedNorm = normalizeOutput(testCase.output);
      final actualNorm = normalizeOutput(res.stdout);

      bool isMatch = false;
      String testStatus = 'Passed';

      if (res.isCompilationError) {
        testStatus = 'Compilation Error';
        verdict = 'Compilation Error';
        allPass = false;
      } else if (res.isTimeout) {
        testStatus = 'Time Limit Exceeded';
        verdict = 'Time Limit Exceeded';
        allPass = false;
      } else if (!res.success && res.stderr.isNotEmpty) {
        testStatus = 'Runtime Error';
        verdict = 'Runtime Error';
        allPass = false;
      } else if (expectedNorm == actualNorm) {
        isMatch = true;
        testStatus = 'Passed';
        passedCount++;
      } else {
        testStatus = 'Wrong Answer';
        if (verdict == 'Accepted') verdict = 'Wrong Answer';
        allPass = false;
      }

      results.add(
        SubmissionTestResult(
          testIndex: i + 1,
          passed: isMatch,
          stdout: res.stdout,
          stderr: res.stderr,
          expected: testCase.output,
          actual: res.stdout.isNotEmpty
              ? res.stdout
              : (res.stderr.isNotEmpty ? res.stderr : ''),
          input: testCase.input,
          executionTimeMs: res.executionTimeMs,
          status: testStatus,
        ),
      );
    }

    final isAllPassed = allPass && passedCount == problem.testCases.length;
    final finalVerdict = isAllPassed ? 'Accepted' : verdict;

    // Check if the user has ALREADY solved this problem in the past
    final submissionsList = ref.read(userSubmissionsProvider).value ?? [];
    final hasAlreadySolved = submissionsList.any(
      (s) => s.problemId == problem.id && s.passed,
    );

    bool isFirstTimeSolve = false;
    int pointsEarned = 0;

    if (isAllPassed && !hasAlreadySolved) {
      isFirstTimeSolve = true;
      final diff = problem.difficulty.toLowerCase();
      if (diff == 'hard') {
        pointsEarned = PointsRules.hardProblem;
      } else if (diff == 'medium') {
        pointsEarned = PointsRules.mediumProblem;
      } else {
        pointsEarned = PointsRules.easyProblem;
      }
    }

    // Save submission to Firestore
    final submission = CodingSubmissionModel(
      uid: user.uid,
      problemId: problem.id,
      code: code,
      language: language,
      testResults: results,
      passed: isAllPassed,
      testCasesPassed: passedCount,
      testCasesTotal: problem.testCases.length,
      verdict: finalVerdict,
      submittedAt: DateTime.now(),
    );

    final repo = ref.read(codingRepositoryProvider);
    await repo.saveSubmission(submission);

    // If first-time solve, synchronize points and check badge unlocks
    if (isFirstTimeSolve) {
      await ref
          .read(gamificationControllerProvider.notifier)
          .syncPointsAndCheckBadges();
    }

    state = state.copyWith(
      isExecuting: false,
      isSubmitting: false,
      testResults: results,
      allPassed: isAllPassed,
      isSubmitted: true,
      overallVerdict: finalVerdict,
      executionTimeMs: totalElapsedMs,
      isFirstTimeSolve: isFirstTimeSolve,
      pointsEarned: pointsEarned,
      logs:
          "Verdict: $finalVerdict ($passedCount/${problem.testCases.length} test cases passed)",
    );

    // Automatically trigger AI hint generation if submission failed
    if (!isAllPassed) {
      fetchAiHint(problem: problem, language: language, code: code);
    }
  }

  /// Calls Gemini / Groq via Cloudflare Worker to get AI hint on code failure.
  Future<void> fetchAiHint({
    required CodingProblemModel problem,
    required String language,
    required String code,
  }) async {
    state = state.copyWith(isLoadingAiHint: true, aiHint: null);
    try {
      final gemini = ref.read(geminiServiceProvider);
      final failedResult = state.testResults?.firstWhere(
        (r) => !r.passed,
        orElse: () => state.testResults?.isNotEmpty == true
            ? state.testResults!.first
            : SubmissionTestResult(
                testIndex: 1,
                passed: false,
                stdout: '',
                stderr: 'Execution Error',
              ),
      );

      final errorText = failedResult != null
          ? "Status: ${failedResult.status ?? 'Failed'}\nExpected: ${failedResult.expected}\nActual: ${failedResult.actual}\nStderr: ${failedResult.stderr}"
          : "Some test cases failed.";

      final hint = await gemini.generateCodingFailureHint(
        problemTitle: problem.title,
        problemDescription: problem.description,
        language: language,
        code: code,
        errorOutput: errorText,
      );

      state = state.copyWith(aiHint: hint, isLoadingAiHint: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingAiHint: false,
        aiHint:
            "Could not generate AI hint at this moment ($e). Check your logic and boundary cases!",
      );
    }
  }
}

final executionProvider = NotifierProvider<ExecutionNotifier, ExecutionState>(
  () {
    return ExecutionNotifier();
  },
);
