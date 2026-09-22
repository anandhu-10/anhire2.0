import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/roadmap_model.dart';
import '../repositories/roadmap_repository.dart';
import '../services/gemini_service.dart';
import 'auth_provider.dart';
import 'user_provider.dart';
import 'resume_provider.dart';
import 'coding_provider.dart';
import 'aptitude_provider.dart';
import 'interview_provider.dart';

final roadmapRepositoryProvider = Provider<IRoadmapRepository>((ref) {
  return RoadmapRepository();
});

final userRoadmapProvider = StreamProvider<Roadmap?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);

  final repo = ref.watch(roadmapRepositoryProvider);
  return repo.getRoadmapStream(user.uid);
});

class RoadmapState {
  final bool isGenerating;
  final String? statusMessage;
  final String? error;

  const RoadmapState({
    this.isGenerating = false,
    this.statusMessage,
    this.error,
  });

  RoadmapState copyWith({
    bool? isGenerating,
    String? statusMessage,
    String? error,
  }) {
    return RoadmapState(
      isGenerating: isGenerating ?? this.isGenerating,
      statusMessage: statusMessage,
      error: error,
    );
  }
}

class RoadmapController extends StateNotifier<RoadmapState> {
  final Ref ref;

  RoadmapController(this.ref) : super(const RoadmapState());

  Future<bool> generatePersonalizedRoadmap() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      state = state.copyWith(error: "User not authenticated.");
      return false;
    }

    state = state.copyWith(
      isGenerating: true,
      statusMessage: "Fetching your performance profile & test scores...",
      error: null,
    );

    try {
      // 1. Gather profile data
      final profile = ref.read(profileProvider).value;
      final role = profile?.preferredRole.isNotEmpty == true
          ? profile!.preferredRole
          : "Software Engineer";
      final companiesStr = profile?.targetCompanies.isNotEmpty == true
          ? profile!.targetCompanies.join(', ')
          : "Google, Microsoft, Amazon";

      // 2. Gather metrics
      state = state.copyWith(statusMessage: "Analyzing Resume ATS score...");
      final resumeReport = ref.read(latestResumeReportProvider).value;
      final resumeScore = resumeReport?.overallScore ?? 75;

      state = state.copyWith(statusMessage: "Checking Coding problem submissions...");
      final submissions = ref.read(userSubmissionsProvider).value ?? [];
      final codingSolved = submissions.where((s) => s.passed).map((s) => s.problemId).toSet().length;

      state = state.copyWith(statusMessage: "Calculating Aptitude quiz accuracy...");
      final aptitudeResults = ref.read(userAptitudeResultsProvider).value ?? [];
      double aptitudeAccuracy = 0.0;
      if (aptitudeResults.isNotEmpty) {
        aptitudeAccuracy = aptitudeResults.first.accuracy;
      } else {
        aptitudeAccuracy = 80.0;
      }

      state = state.copyWith(statusMessage: "Evaluating Interview readiness...");
      final interviewAvg = ref.read(interviewAverageProvider(user.uid)).value ?? 70;

      // Determine weakest area
      String weakestArea = "Coding Data Structures";
      if (resumeScore < 70) {
        weakestArea = "Resume ATS & Industry Alignment";
      } else if (aptitudeAccuracy < 70) {
        weakestArea = "Aptitude Quantitative & Logical Skills";
      } else if (interviewAvg < 70) {
        weakestArea = "Technical Mock Interview Communication";
      } else if (codingSolved < 5) {
        weakestArea = "Coding Algorithms & Hands-on Implementation";
      }

      state = state.copyWith(statusMessage: "Consulting Gemini AI Placement Coach...");
      final geminiService = ref.read(geminiServiceProvider);
      final jsonResult = await geminiService.generateRoadmap(
        role: role,
        companies: companiesStr,
        resumeScore: resumeScore,
        codingSolved: codingSolved,
        aptitudeAccuracy: aptitudeAccuracy,
        interviewAvg: interviewAvg,
        weakestArea: weakestArea,
      );

      final rawWeeks = jsonResult['weeks'] as List<dynamic>? ?? [];
      final weeks = rawWeeks.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return RoadmapWeek.fromMap(map);
      }).toList();

      if (weeks.isEmpty) {
        throw Exception("Failed to generate weekly plan structure.");
      }

      final roadmap = Roadmap(
        uid: user.uid,
        role: role,
        companies: companiesStr,
        weeks: weeks,
        overallProgress: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(statusMessage: "Saving roadmap to your account...");
      final repo = ref.read(roadmapRepositoryProvider);
      await repo.saveRoadmap(roadmap);

      state = state.copyWith(isGenerating: false, statusMessage: null);
      return true;
    } catch (e, st) {
      debugPrint("RoadmapController generatePersonalizedRoadmap error: $e\n$st");
      state = state.copyWith(
        isGenerating: false,
        statusMessage: null,
        error: "Failed to generate roadmap. Please try again.",
      );
      return false;
    }
  }

  Future<void> toggleTask({
    required int weekIndex,
    required int taskIndex,
    required bool completed,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final repo = ref.read(roadmapRepositoryProvider);
    await repo.updateTaskCompletion(
      uid: user.uid,
      weekIndex: weekIndex,
      taskIndex: taskIndex,
      completed: completed,
    );
  }
}

final roadmapControllerProvider =
    StateNotifierProvider<RoadmapController, RoadmapState>((ref) {
  return RoadmapController(ref);
});
