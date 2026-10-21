import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coding_provider.dart';
import '../../providers/aptitude_provider.dart';
import '../../providers/interview_provider.dart';

class PracticeHubScreen extends ConsumerWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < AppBreakpoints.compactBreakpoint;

    final codingProblems = ref.watch(codingProblemsProvider).value ?? [];
    final submissions = ref.watch(userSubmissionsProvider).value ?? [];
    final aptitudeQuestions = ref.watch(aptitudeQuestionsProvider).value ?? [];
    final aptitudeResults = ref.watch(userAptitudeResultsProvider).value ?? [];

    final solvedProblemIds = submissions
        .where((s) => s.passed)
        .map((s) => s.problemId)
        .toSet();
    final solvedCount = solvedProblemIds.length;
    final totalProblems = codingProblems.isNotEmpty
        ? codingProblems.length
        : 30;

    final totalAptitude = aptitudeQuestions.isNotEmpty
        ? aptitudeQuestions.length
        : 30;
    final latestAptitude = aptitudeResults.isNotEmpty
        ? aptitudeResults.first
        : null;
    final avgAccuracy = latestAptitude != null
        ? latestAptitude.accuracy.round()
        : 85;

    // Interview Stats
    final user = ref.watch(authStateProvider).value;
    final userId = user?.uid ?? '';
    final interviewAvgState = ref.watch(interviewAverageProvider(userId));
    final interviewHistoryState = ref.watch(interviewHistoryProvider(userId));
    final interviewAvg = interviewAvgState.value ?? 80;
    final interviewCount = interviewHistoryState.value?.length ?? 0;

    return Scaffold(
      backgroundColor: context.appRootBg,
      appBar: AppBar(
        backgroundColor: context.appRootBg,
        title: const Text(
          'Practice Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practice & Master',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a specialized preparation module to sharpen your skills',
                  style: TextStyle(fontSize: 14, color: context.appTextMuted),
                ),
                const SizedBox(height: 24),

                // Responsive Cards Layout
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isCompact ? double.infinity : 360,
                      child: _buildPracticeCard(
                        context,
                        title: 'Coding Practice',
                        description:
                            '$totalProblems Problems available • $solvedCount solved',
                        tags: ['Easy: 10', 'Medium: 12', 'Hard: 8'],
                        icon: Icons.code_rounded,
                        accentColor: AppColors.primary,
                        onTap: () => context.go('/coding-problems'),
                      ),
                    ),
                    SizedBox(
                      width: isCompact ? double.infinity : 360,
                      child: _buildPracticeCard(
                        context,
                        title: 'Aptitude Test',
                        description:
                            '$totalAptitude Questions available • $avgAccuracy% accuracy',
                        tags: ['Quantitative', 'Logical', 'Verbal'],
                        icon: Icons.psychology_outlined,
                        accentColor: AppColors.warning,
                        onTap: () => context.go('/aptitude'),
                      ),
                    ),
                    SizedBox(
                      width: isCompact ? double.infinity : 360,
                      child: _buildPracticeCard(
                        context,
                        title: 'AI Mock Interview',
                        description:
                            '$interviewCount sessions completed • $interviewAvg% avg readiness',
                        tags: [
                          'Technical',
                          'Behavioral',
                          'HR',
                          'System Design',
                        ],
                        icon: Icons.record_voice_over_outlined,
                        accentColor: AppColors.secondary,
                        onTap: () => context.go('/mock-interview'),
                      ),
                    ),
                    SizedBox(
                      width: isCompact ? double.infinity : 360,
                      child: _buildPracticeCard(
                        context,
                        title: 'Leaderboard & Ranks',
                        description:
                            'Compete with peers & track your placement tier',
                        tags: ['Global Ranks', 'Medal Tiers', 'Weekly Points'],
                        icon: Icons.emoji_events_outlined,
                        accentColor: const Color(0xFFEAB308),
                        onTap: () => context.go('/leaderboard'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Roadmap Banner Card
                Container(
                  padding: const EdgeInsets.all(22.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: context.isDark
                          ? [const Color(0xFF1E1435), const Color(0xFF151520)]
                          : [const Color(0xFFF3E8FF), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.alt_route_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personalized Learning Roadmap',
                              style: TextStyle(
                                color: context.appTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Follow a week-by-week structured curriculum customized for your target dream companies',
                              style: TextStyle(
                                color: context.appTextMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => context.go('/roadmap'),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text(
                          'View Roadmap',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeCard(
    BuildContext context, {
    required String title,
    required String description,
    required List<String> tags,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(22.0),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDark ? 0.2 : 0.04,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 26),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.isDark
                          ? AppColors.darkSurfaceSecondary
                          : AppColors.lightSurfaceSecondary,
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: context.appTextSecondary,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 13, color: context.appTextMuted),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? AppColors.darkSurfaceSecondary
                          : AppColors.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.appTextSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
