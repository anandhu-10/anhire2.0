import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/aptitude_problem_model.dart';
import '../models/aptitude_result_model.dart';
import '../repositories/aptitude_repository.dart';
import 'auth_provider.dart';

final aptitudeRepositoryProvider = Provider<AptitudeRepository>((ref) {
  return AptitudeRepository();
});

/// Streams all aptitude questions from Firestore with fallback to assets/data/aptitude_problems.json.
final aptitudeQuestionsProvider = StreamProvider<List<AptitudeProblemModel>>((ref) async* {
  final repo = ref.watch(aptitudeRepositoryProvider);
  await for (final questions in repo.streamQuestions()) {
    if (questions.isEmpty) {
      try {
        final jsonStr = await rootBundle.loadString('assets/data/aptitude_problems.json');
        final List<dynamic> list = jsonDecode(jsonStr);
        final assetQuestions = list.map((e) => AptitudeProblemModel.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        yield assetQuestions;
      } catch (e) {
        yield [];
      }
    } else {
      yield questions;
    }
  }
});

/// Streams user's past aptitude test results.
final userAptitudeResultsProvider = StreamProvider<List<AptitudeResultModel>>((ref) {
  final repo = ref.watch(aptitudeRepositoryProvider);
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return repo.streamUserResults(user.uid);
});

class AptitudeTestState {
  final List<AptitudeProblemModel> questions;
  final int currentIndex;
  final Map<int, int> userAnswers; // question index -> selected option index
  final Map<int, bool> answeredState; // question index -> has answered
  final int score;
  final bool isCompleted;
  final bool enableTimer;
  final int remainingSeconds;

  AptitudeTestState({
    this.questions = const [],
    this.currentIndex = 0,
    this.userAnswers = const {},
    this.answeredState = const {},
    this.score = 0,
    this.isCompleted = false,
    this.enableTimer = true,
    this.remainingSeconds = 1800, // 30 minutes
  });

  AptitudeTestState copyWith({
    List<AptitudeProblemModel>? questions,
    int? currentIndex,
    Map<int, int>? userAnswers,
    Map<int, bool>? answeredState,
    int? score,
    bool? isCompleted,
    bool? enableTimer,
    int? remainingSeconds,
  }) {
    return AptitudeTestState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      answeredState: answeredState ?? this.answeredState,
      score: score ?? this.score,
      isCompleted: isCompleted ?? this.isCompleted,
      enableTimer: enableTimer ?? this.enableTimer,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}

class AptitudeTestNotifier extends Notifier<AptitudeTestState> {
  @override
  AptitudeTestState build() {
    return AptitudeTestState();
  }

  /// Starts a new practice test session with filtered questions.
  void startTest({
    required List<AptitudeProblemModel> filteredQuestions,
    bool enableTimer = true,
  }) {
    state = AptitudeTestState(
      questions: filteredQuestions,
      currentIndex: 0,
      userAnswers: {},
      answeredState: {},
      score: 0,
      isCompleted: false,
      enableTimer: enableTimer,
      remainingSeconds: 1800,
    );
  }

  /// Selects an option for the current question.
  void selectOption(int optionIndex) {
    if (state.isCompleted) return;
    if (state.answeredState[state.currentIndex] == true) return;

    final currentQ = state.questions[state.currentIndex];
    final isCorrect = optionIndex == currentQ.correctOptionIndex;

    final newAnswers = Map<int, int>.from(state.userAnswers)..[state.currentIndex] = optionIndex;
    final newAnswered = Map<int, bool>.from(state.answeredState)..[state.currentIndex] = true;
    final newScore = isCorrect ? state.score + 1 : state.score;

    state = state.copyWith(
      userAnswers: newAnswers,
      answeredState: newAnswered,
      score: newScore,
    );
  }

  /// Moves to next question or completes test.
  Future<void> nextQuestion() async {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    } else {
      await finishTest();
    }
  }

  /// Finishes test session and saves result to Firestore.
  Future<void> finishTest() async {
    final user = ref.read(authStateProvider).value;
    final total = state.questions.length;
    final correct = state.score;
    final accuracy = total > 0 ? (correct / total) * 100 : 0.0;

    final Map<String, int> totalPerCat = {};
    final Map<String, int> correctPerCat = {};

    for (int i = 0; i < state.questions.length; i++) {
      final q = state.questions[i];
      final cat = q.category;
      totalPerCat[cat] = (totalPerCat[cat] ?? 0) + 1;
      if (state.userAnswers[i] == q.correctOptionIndex) {
        correctPerCat[cat] = (correctPerCat[cat] ?? 0) + 1;
      }
    }

    final Map<String, dynamic> breakdown = {};
    totalPerCat.forEach((cat, count) {
      final corr = correctPerCat[cat] ?? 0;
      breakdown[cat] = '$corr/$count';
    });

    if (user != null && total > 0) {
      final resultModel = AptitudeResultModel(
        uid: user.uid,
        totalQuestions: total,
        correctAnswers: correct,
        accuracy: accuracy,
        categoryBreakdown: breakdown,
        filterUsed: {'total': total},
        completedAt: DateTime.now(),
      );

      final repo = ref.read(aptitudeRepositoryProvider);
      await repo.saveResult(resultModel);
    }

    state = state.copyWith(isCompleted: true);
  }
}

final aptitudeTestControllerProvider =
    NotifierProvider<AptitudeTestNotifier, AptitudeTestState>(() {
  return AptitudeTestNotifier();
});
