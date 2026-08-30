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
  const PracticeHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < AppBreakpoints.compactBreakpoint;

    final codingProblems = ref.watch(codingProblemsProvider).value ?? [];
    final submissions = ref.watch(userSubmissionsProvider).value ?? [];
    final aptitudeQuestions = ref.watch(aptitudeQuestionsProvider).value ?? [];
    final aptitudeResults = ref.watch(userAptitudeResultsProvider).value ?? [];

    final solvedProblemIds = submissions.where((s) => s.passed).map((s) => s.problemId).toSet();
    final solvedCount = solvedProblemIds.length;
    final totalProblems = codingProblems.isNotEmpty ? codingProblems.length : 30;

    final totalAptitude = aptitudeQuestions.isNotEmpty ? aptitudeQuestions.length : 30;
    final latestAptitude = aptitudeResults.isNotEmpty ? aptitudeResults.first : null;
    final avgAccuracy = latestAptitude != null ? latestAptitude.accuracy.round() : 85;

    // Interview Stats
    final user = ref.watch(authStateProvider).value;
    final userId = user?.uid ?? '';
    final interviewAvgState = ref.watch(interviewAverageProvider(userId));
    final interviewHistoryState = ref.watch(interviewHistoryProvider(userId));
    final interviewAvg = interviewAvgState.value ?? 80;
    final interviewCount = interviewHistoryState.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Hub'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practice & Master',
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a module to sharpen your technical and analytical skills',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Responsive Cards Layout (Stacked on Mobile, Column Grid on Desktop)
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isCompact ? double.infinity : 350,
                      child: _buildPracticeCard(
                        context,
                        title: 'CODING PRACTICE',
                        description: '$totalProblems Problems available ($solvedCount solved)',
                        tags: ['Easy: 10', 'Medium: 12', 'Hard: 8'],
                        icon: Icons.code,
                        iconBgColor: const Color(0xFF6750A4),
                        onTap: () => context.go('/coding-problems'),
                      ),
                    ),
                    SizedBox(
                      width: isCompact ? double.infinity : 350,
                      child: _buildPracticeCard(
                        context,
                        title: 'APTITUDE TEST',
                        description: '$totalAptitude Questions available ($avgAccuracy% avg accuracy)',
                        tags: ['Quantitative', 'Logical', 'Verbal'],
                        icon: Icons.psychology,
                        iconBgColor: const Color(0xFFED6C02),
                        onTap: () => context.go('/aptitude'),
                      ),
                    ),
                    SizedBox(
                      width: isCompact ? double.infinity : 350,
                      child: _buildPracticeCard(
                        context,
                        title: 'AI MOCK INTERVIEW',
                        description: '$interviewCount interviews completed ($interviewAvg% avg score)',
                        tags: ['Technical', 'Behavioral', 'HR', 'Situational'],
                        icon: Icons.record_voice_over,
                        iconBgColor: const Color(0xFF2196F3),
                        onTap: () => context.go('/mock-interview'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Roadmap Banner Card
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.alt_route, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personalized Learning Roadmap',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF6750A4),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Follow a structured week-by-week timeline tailored for your target roles',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF1C1B1F),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6750A4),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => context.go('/roadmap'),
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('View Roadmap'),
                        ),
                      ],
                    ),
                  ),
                ),
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
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFEADDFF),
                    child: Icon(Icons.arrow_forward, color: Color(0xFF6750A4), size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
