import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/gemini_service.dart';
import '../models/interview_models.dart';
import '../repositories/interview_repository.dart';
import 'auth_provider.dart';

enum InterviewStatus {
  idle,
  generating,
  answering,
  evaluating,
  completed,
  error,
}

class InterviewState {
  final InterviewStatus status;
  final List<InterviewQuestion> questions;
  final int currentIndex;
  final String selectedRole;
  final String selectedCompany;
  final String? errorMessage;
  final String? activeSessionId;
  final InterviewSession? completedSession;

  InterviewState({
    this.status = InterviewStatus.idle,
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedRole = '',
    this.selectedCompany = '',
    this.errorMessage,
    this.activeSessionId,
    this.completedSession,
  });

  InterviewQuestion? get currentQuestion =>
      (questions.isNotEmpty && currentIndex < questions.length) ? questions[currentIndex] : null;

  int get runningAverageScore {
    final evaluated = questions.where((q) => q.evaluation != null).toList();
    if (evaluated.isEmpty) return 0;
    final sum = evaluated.fold<int>(0, (acc, q) => acc + q.evaluation!.overallScore);
    return (sum / evaluated.length).round();
  }

  InterviewState copyWith({
    InterviewStatus? status,
    List<InterviewQuestion>? questions,
    int? currentIndex,
    String? selectedRole,
    String? selectedCompany,
    String? errorMessage,
    String? activeSessionId,
    InterviewSession? completedSession,
  }) {
    return InterviewState(
      status: status ?? this.status,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedRole: selectedRole ?? this.selectedRole,
      selectedCompany: selectedCompany ?? this.selectedCompany,
      errorMessage: errorMessage ?? this.errorMessage,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      completedSession: completedSession ?? this.completedSession,
    );
  }
}

final interviewProvider = NotifierProvider<InterviewNotifier, InterviewState>(() {
  return InterviewNotifier();
});

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

final interviewAverageProvider = FutureProvider.family<int, String>((ref, uid) async {
  final repository = ref.watch(interviewRepositoryProvider);
  return repository.getInterviewAverage(uid);
});

final interviewHistoryProvider = FutureProvider.family<List<InterviewSession>, String>((ref, uid) async {
  final repository = ref.watch(interviewRepositoryProvider);
  return repository.getInterviewHistory(uid);
});

class InterviewNotifier extends Notifier<InterviewState> {
  late final GeminiService _geminiService;
  late final InterviewRepository _repository;

  @override
  InterviewState build() {
    _geminiService = ref.watch(geminiServiceProvider);
    _repository = ref.watch(interviewRepositoryProvider);
    return InterviewState();
  }

  /// Starts a new mock interview session by calling Gemini for questions.
  Future<void> startInterview(String role, String company) async {
    state = state.copyWith(
      status: InterviewStatus.generating,
      selectedRole: role,
      selectedCompany: company,
      questions: [],
      currentIndex: 0,
      errorMessage: null,
      activeSessionId: 'sess_${DateTime.now().millisecondsSinceEpoch}',
    );

    try {
      final questions = await _geminiService.generateMockInterviewQuestions(role, company);
      state = state.copyWith(
        status: InterviewStatus.answering,
        questions: questions,
        currentIndex: 0,
      );
    } catch (e) {
      state = state.copyWith(
        status: InterviewStatus.error,
        errorMessage: 'Failed to generate interview questions: $e',
      );
    }
  }

  /// Submits candidate's answer for Gemini evaluation.
  Future<void> submitAnswer(String answer) async {
    final q = state.currentQuestion;
    if (q == null) return;

    state = state.copyWith(status: InterviewStatus.evaluating);

    try {
      final evaluation = await _geminiService.evaluateMockInterviewAnswer(
        question: q.question,
        answer: answer,
        expectedKeywords: q.expectedKeywords.join(', '),
        questionType: q.type,
      );

      final updatedQuestion = q.copyWith(
        userAnswer: answer,
        evaluation: evaluation,
      );

      final updatedList = List<InterviewQuestion>.from(state.questions);
      updatedList[state.currentIndex] = updatedQuestion;

      state = state.copyWith(
        status: InterviewStatus.answering,
        questions: updatedList,
      );
    } catch (e) {
      state = state.copyWith(
        status: InterviewStatus.error,
        errorMessage: 'Failed to evaluate answer: $e',
      );
    }
  }

  /// Advances to the next question or finishes the interview session if last question.
  Future<void> nextQuestion() async {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    } else {
      await finishInterview();
    }
  }

  /// Calculates final overall score and persists the session to Firestore.
  Future<void> finishInterview() async {
    final user = ref.read(authStateProvider).value;
    final uid = user?.uid ?? 'anonymous';

    final totalScore = state.runningAverageScore;

    final session = InterviewSession(
      id: state.activeSessionId ?? 'sess_${DateTime.now().millisecondsSinceEpoch}',
      uid: uid,
      role: state.selectedRole,
      company: state.selectedCompany,
      questions: state.questions,
      overallScore: totalScore,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );

    try {
      await _repository.saveInterviewSession(session);
    } catch (e) {
      // Ignore offline / permission warnings during UI save
    }

    state = state.copyWith(
      status: InterviewStatus.completed,
      completedSession: session,
    );
  }

  /// Resets interview state back to idle.
  void resetInterview() {
    state = InterviewState();
  }
}
