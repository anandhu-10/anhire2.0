import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/resume_provider.dart';
import '../../providers/coding_provider.dart';
import '../../providers/aptitude_provider.dart';
import '../../providers/interview_provider.dart';
import '../../providers/roadmap_provider.dart';
import '../../widgets/responsive_grid.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final profileState = ref.watch(profileProvider);
    final latestReport = ref.watch(latestResumeReportProvider).value;
    final submissionsState = ref.watch(userSubmissionsProvider);
    final codingProblemsState = ref.watch(codingProblemsProvider);
    final aptitudeResultsState = ref.watch(userAptitudeResultsProvider);
    final roadmapState = ref.watch(userRoadmapProvider).value;

    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < AppBreakpoints.compactBreakpoint;

    final studentName = profileState.value?.fullName.isNotEmpty == true
        ? profileState.value!.fullName
        : 'Student';

    final resumeScore = latestReport?.overallScore ?? 0;

    // Calculate Coding Problems Solved
    final submissions = submissionsState.value ?? [];
    final totalProblems = codingProblemsState.value?.length ?? 30;
    final solvedProblemIds = submissions.where((s) => s.passed).map((s) => s.problemId).toSet();
    final solvedCount = solvedProblemIds.length;

    // Calculate Aptitude Accuracy
    final aptitudeResults = aptitudeResultsState.value ?? [];
    final latestAptitude = aptitudeResults.isNotEmpty ? aptitudeResults.first : null;
    final aptitudeAccuracy = latestAptitude != null ? latestAptitude.accuracy.round() : 0;

    // Calculate Interview Stats
    final userId = user?.uid ?? '';
    final interviewAvgState = ref.watch(interviewAverageProvider(userId));
    final interviewHistoryState = ref.watch(interviewHistoryProvider(userId));
    final interviewAvg = interviewAvgState.value ?? 0;
    final interviewCount = interviewHistoryState.value?.length ?? 0;

    // Check practice activity today for Notification Banner
    final now = DateTime.now();
    final todaySubmissions = submissions.where((s) =>
        s.submittedAt.year == now.year &&
        s.submittedAt.month == now.month &&
        s.submittedAt.day == now.day).toList();
    final todayAptitude = aptitudeResults.where((a) =>
        a.completedAt.year == now.year &&
        a.completedAt.month == now.month &&
        a.completedAt.day == now.day).toList();
    final hasPracticedToday = todaySubmissions.isNotEmpty || todayAptitude.isNotEmpty;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Greeting
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, $studentName 👋',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Here is your placement prep progress overview',
                            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${_getMonthName(now.month)} ${now.day}, ${now.year}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // In-App Daily Reminder Banner (if not practiced today)
                if (!hasPracticedToday) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade700, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.stars, color: Colors.amber.shade800, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Keep your streak going! 🔥",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "You haven't practiced today. Spend 10 minutes solving a problem or quiz.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => context.go('/coding-problems'),
                          child: const Text('Practice Now', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Responsive 4 KPI Summary Cards Grid
                ResponsiveGrid(
                  minItemWidth: 165.0,
                  spacing: 12.0,
                  children: [
                    _buildSummaryCard(
                      context,
                      title: 'Resume Score',
                      value: resumeScore > 0 ? '$resumeScore/100' : 'Not scanned',
                      subtitle: latestReport != null ? 'Evaluated by AI' : 'Upload PDF in Profile',
                      icon: Icons.description_outlined,
                      iconColor: theme.colorScheme.primary,
                      badgeWidget: resumeScore > 0
                          ? SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                value: resumeScore / 100,
                                strokeWidth: 3,
                                color: theme.colorScheme.primary,
                                backgroundColor: theme.colorScheme.primaryContainer,
                              ),
                            )
                          : null,
                      onTap: () => context.go('/resume-report'),
                    ),
                    _buildSummaryCard(
                      context,
                      title: 'Problems Solved',
                      value: '$solvedCount/$totalProblems',
                      subtitle: '${((solvedCount / (totalProblems > 0 ? totalProblems : 1)) * 100).round()}% solved',
                      icon: Icons.code,
                      iconColor: const Color(0xFF2E7D32),
                      onTap: () => context.go('/coding-problems'),
                    ),
                    _buildSummaryCard(
                      context,
                      title: 'Aptitude Accuracy',
                      value: aptitudeResults.isNotEmpty ? '$aptitudeAccuracy%' : 'No tests',
                      subtitle: latestAptitude != null
                          ? '${latestAptitude.correctAnswers}/${latestAptitude.totalQuestions} correct'
                          : 'Take a quick test',
                      icon: Icons.psychology_outlined,
                      iconColor: const Color(0xFF0288D1),
                      onTap: () => context.go('/aptitude'),
                    ),
                    _buildSummaryCard(
                      context,
                      title: 'Interview Readiness',
                      value: interviewAvg > 0 ? '$interviewAvg%' : 'No sessions',
                      subtitle: interviewCount > 0 ? '$interviewCount sessions completed' : 'Start mock interview',
                      icon: Icons.video_call_outlined,
                      iconColor: const Color(0xFFED6C02),
                      onTap: () => context.go('/mock-interview'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Roadmap CTA Banner
                InkWell(
                  onTap: () => context.go('/roadmap'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.map_outlined, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                roadmapState != null
                                    ? 'Personalized Learning Roadmap'
                                    : 'Generate Your AI Learning Roadmap',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                roadmapState != null
                                    ? 'Target: ${roadmapState.role} — ${(roadmapState.overallProgress * 100).round()}% Completed'
                                    : 'Get a 4-8 week study plan based on your test scores and resume',
                                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // fl_chart Progress Chart
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Text(
                              'Preparation Performance Curves',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Real-time Metrics',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 220,
                          child: LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: 3,
                              minY: 0,
                              maxY: 100,
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (val, meta) {
                                      const categories = ['Resume', 'Coding', 'Aptitude', 'Interview'];
                                      int idx = val.toInt();
                                      if (idx >= 0 && idx < categories.length && val == idx.toDouble()) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            categories[idx],
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    FlSpot(0, resumeScore.toDouble()),
                                    FlSpot(1, ((solvedCount / (totalProblems > 0 ? totalProblems : 1)) * 100).toDouble()),
                                    FlSpot(2, aptitudeAccuracy.toDouble()),
                                    FlSpot(3, interviewAvg.toDouble()),
                                  ],
                                  isCurved: true,
                                  color: theme.colorScheme.primary,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions Section
                Text('Quick Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (isCompact) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(AppBreakpoints.minTouchTarget),
                        ),
                        onPressed: () => context.go('/coding-problems'),
                        icon: const Icon(Icons.code),
                        label: const Text('Practice Coding'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(AppBreakpoints.minTouchTarget),
                        ),
                        onPressed: () => context.go('/aptitude'),
                        icon: const Icon(Icons.psychology),
                        label: const Text('Aptitude Test'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(AppBreakpoints.minTouchTarget),
                        ),
                        onPressed: () => context.go('/mock-interview'),
                        icon: const Icon(Icons.video_call),
                        label: const Text('Mock Interview'),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(AppBreakpoints.minTouchTarget),
                          ),
                          onPressed: () => context.go('/coding-problems'),
                          icon: const Icon(Icons.code),
                          label: const Text('Practice Coding'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(AppBreakpoints.minTouchTarget),
                          ),
                          onPressed: () => context.go('/aptitude'),
                          icon: const Icon(Icons.psychology),
                          label: const Text('Aptitude Test'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(AppBreakpoints.minTouchTarget),
                          ),
                          onPressed: () => context.go('/mock-interview'),
                          icon: const Icon(Icons.video_call),
                          label: const Text('Mock Interview'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Recent Activity Timeline
                Text('Recent Activity', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (submissions.isNotEmpty || aptitudeResults.isNotEmpty || (interviewHistoryState.value?.isNotEmpty == true)) ...[
                          if (submissions.isNotEmpty)
                            _buildActivityItem(
                              context,
                              icon: Icons.code,
                              iconColor: submissions.first.passed ? Colors.green : Colors.orange,
                              title: 'Coding Submission (${submissions.first.language.toUpperCase()}) — ${submissions.first.passed ? "PASSED" : "FAILED"}',
                              time: '${submissions.first.testCasesPassed}/${submissions.first.testCasesTotal} test cases',
                            ),
                          if (aptitudeResults.isNotEmpty) ...[
                            if (submissions.isNotEmpty) const Divider(),
                            _buildActivityItem(
                              context,
                              icon: Icons.psychology,
                              iconColor: theme.colorScheme.primary,
                              title: 'Completed Aptitude Test Session',
                              time: '${aptitudeResults.first.correctAnswers}/${aptitudeResults.first.totalQuestions} correct (${aptitudeResults.first.accuracy.round()}%)',
                            ),
                          ],
                          if (interviewHistoryState.value?.isNotEmpty == true) ...[
                            if (submissions.isNotEmpty || aptitudeResults.isNotEmpty) const Divider(),
                            _buildActivityItem(
                              context,
                              icon: Icons.video_call,
                              iconColor: const Color(0xFFED6C02),
                              title: 'Completed AI Mock Interview Session',
                              time: 'Score: ${interviewHistoryState.value!.first.overallScore}/100',
                            ),
                          ],
                        ] else ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.history, size: 36, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'No recent practice activity yet.',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Complete a coding problem or aptitude test to track your history!',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Widget? badgeWidget,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  if (badgeWidget != null) badgeWidget,
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconColor.withValues(alpha: 0.1),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
