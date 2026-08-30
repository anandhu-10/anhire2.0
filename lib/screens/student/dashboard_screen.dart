import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/resume_provider.dart';
import '../../providers/coding_provider.dart';
import '../../providers/aptitude_provider.dart';
import '../../providers/interview_provider.dart';
import '../../widgets/responsive_grid.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final profileState = ref.watch(profileProvider);
    final latestReport = ref.watch(latestResumeReportProvider).value;
    final submissionsState = ref.watch(userSubmissionsProvider);
    final codingProblemsState = ref.watch(codingProblemsProvider);
    final aptitudeResultsState = ref.watch(userAptitudeResultsProvider);

    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < AppBreakpoints.compactBreakpoint;

    final studentName = profileState.value?.fullName.isNotEmpty == true
        ? profileState.value!.fullName
        : (AppConstants.USE_MOCK_DATA ? 'Alex Morgan' : 'Student');

    final resumeScore = latestReport?.overallScore ?? (AppConstants.USE_MOCK_DATA ? 82 : 0);

    // Calculate Coding Problems Solved
    final submissions = submissionsState.value ?? [];
    final totalProblems = codingProblemsState.value?.length ?? 30;
    final solvedProblemIds = submissions.where((s) => s.passed).map((s) => s.problemId).toSet();
    final solvedCount = solvedProblemIds.length;

    // Calculate Aptitude Accuracy
    final aptitudeResults = aptitudeResultsState.value ?? [];
    final latestAptitude = aptitudeResults.isNotEmpty ? aptitudeResults.first : null;
    final aptitudeAccuracy = latestAptitude != null
        ? latestAptitude.accuracy.round()
        : (AppConstants.USE_MOCK_DATA ? 92 : 0);

    // Calculate Interview Stats
    final userId = user?.uid ?? '';
    final interviewAvgState = ref.watch(interviewAverageProvider(userId));
    final interviewHistoryState = ref.watch(interviewHistoryProvider(userId));
    final interviewAvg = interviewAvgState.value ?? (AppConstants.USE_MOCK_DATA ? 80 : 0);
    final interviewCount = interviewHistoryState.value?.length ?? 0;

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
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, $studentName 👋',
                            style: theme.textTheme.headlineLarge,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgLavender,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: AppColors.textOnLavender),
                          SizedBox(width: 6),
                          Text(
                            'Aug 24, 2026',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnLavender,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Responsive KPI Summary Cards Grid
                ResponsiveGrid(
                  minItemWidth: 165.0,
                  spacing: 12.0,
                  children: [
                    _buildSummaryCard(
                      context,
                      title: 'Resume Score',
                      value: '$resumeScore/100',
                      subtitle: latestReport != null ? 'Scanned & Evaluated' : 'Not scanned',
                      icon: Icons.description_outlined,
                      iconColor: theme.colorScheme.primary,
                      badgeWidget: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          value: resumeScore / 100,
                          strokeWidth: 3,
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.primaryContainer,
                        ),
                      ),
                      onTap: () => context.go('/resume-report'),
                    ),
                    _buildSummaryCard(
                      context,
                      title: 'Problems Solved',
                      value: '$solvedCount/$totalProblems',
                      subtitle: '${((solvedCount / (totalProblems > 0 ? totalProblems : 1)) * 100).round()}% completed',
                      icon: Icons.code,
                      iconColor: const Color(0xFF2E7D32),
                      onTap: () => context.go('/coding-problems'),
                    ),
                    _buildSummaryCard(
                      context,
                      title: 'Aptitude Accuracy',
                      value: '$aptitudeAccuracy%',
                      subtitle: latestAptitude != null
                          ? '${latestAptitude.correctAnswers}/${latestAptitude.totalQuestions} correct'
                          : 'No tests taken yet',
                      icon: Icons.psychology_outlined,
                      iconColor: const Color(0xFF0288D1),
                      onTap: () => context.go('/aptitude'),
                    ),
                    _buildSummaryCard(
                      context,
                      title: 'Interview Readiness',
                      value: interviewAvg > 0 ? '$interviewAvg%' : '—',
                      subtitle: interviewCount > 0 ? '$interviewCount sessions completed' : 'Take your first interview',
                      icon: Icons.video_call_outlined,
                      iconColor: const Color(0xFFED6C02),
                      onTap: () => context.go('/mock-interview'),
                    ),
                  ],
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
                              'Preparation Progress Over Time',
                              style: theme.textTheme.titleMedium,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Last 6 Weeks',
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
                              maxX: 5,
                              minY: 0,
                              maxY: 100,
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (val, meta) {
                                      const weeks = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'];
                                      int idx = val.toInt();
                                      if (idx >= 0 && idx < weeks.length && val == idx.toDouble()) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            weeks[idx],
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
                                    const FlSpot(0, 30),
                                    const FlSpot(1, 45),
                                    const FlSpot(2, 58),
                                    FlSpot(3, (resumeScore).toDouble()),
                                    FlSpot(4, (aptitudeAccuracy).toDouble()),
                                    FlSpot(5, (solvedCount * 3.3).clamp(0, 100).toDouble()),
                                  ],
                                  isCurved: true,
                                  color: theme.colorScheme.primary,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: theme.colorScheme.primary.withOpacity(0.15),
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
                Text('Quick Actions', style: theme.textTheme.titleMedium),
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
                        onPressed: () => context.go('/interviews'),
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
                          onPressed: () => context.go('/interviews'),
                          icon: const Icon(Icons.video_call),
                          label: const Text('Mock Interview'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Recent Activity Timeline
                Text('Recent Activity', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (submissions.isNotEmpty || aptitudeResults.isNotEmpty) ...[
                          if (submissions.isNotEmpty)
                            _buildActivityItem(
                              context,
                              icon: Icons.code,
                              iconColor: submissions.first.passed ? Colors.green : Colors.orange,
                              title: 'Submitted problem (Language: ${submissions.first.language.toUpperCase()}) — ${submissions.first.passed ? "PASSED" : "FAILED"}',
                              time: '${submissions.first.testCasesPassed}/${submissions.first.testCasesTotal} passed',
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
                        ] else if (AppConstants.USE_MOCK_DATA) ...[
                          _buildActivityItem(
                            context,
                            icon: Icons.check_circle_outline,
                            iconColor: Colors.green,
                            title: 'Solved "Two Sum" in Python',
                            time: '2 hours ago',
                          ),
                          const Divider(),
                          _buildActivityItem(
                            context,
                            icon: Icons.video_call,
                            iconColor: theme.colorScheme.primary,
                            title: 'Completed Technical Mock Interview (SDE)',
                            time: 'Yesterday',
                          ),
                        ] else ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Text(
                                'No recent activity yet. Start practicing to see your progress!',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
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
            backgroundColor: iconColor.withOpacity(0.1),
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
}
