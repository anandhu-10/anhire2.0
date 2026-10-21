import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/resume_provider.dart';
import '../../providers/coding_provider.dart';
import '../../providers/aptitude_provider.dart';
import '../../providers/interview_provider.dart';
import '../../providers/roadmap_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../core/constants/gamification.dart';
import '../../widgets/medal_badge_widget.dart';
import '../../widgets/responsive_grid.dart';
import '../../widgets/app_components.dart';

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < AppBreakpoints.compactBreakpoint;

    final studentName = profileState.value?.fullName.isNotEmpty == true
        ? profileState.value!.fullName
        : 'Student';

    final resumeScore = latestReport?.overallScore ?? 0;

    // Calculate Coding Problems Solved
    final submissions = submissionsState.value ?? [];
    final totalProblems = codingProblemsState.value?.length ?? 30;
    final solvedProblemIds = submissions
        .where((s) => s.passed)
        .map((s) => s.problemId)
        .toSet();
    final solvedCount = solvedProblemIds.length;
    final codingPercent =
        ((solvedCount / (totalProblems > 0 ? totalProblems : 1)) * 100).round();

    // Calculate Aptitude Accuracy
    final aptitudeResults = aptitudeResultsState.value ?? [];
    final latestAptitude = aptitudeResults.isNotEmpty
        ? aptitudeResults.first
        : null;
    final aptitudeAccuracy = latestAptitude != null
        ? latestAptitude.accuracy.round()
        : 0;

    // Calculate Interview Stats
    final userId = user?.uid ?? '';
    final interviewAvgState = ref.watch(interviewAverageProvider(userId));
    final interviewHistoryState = ref.watch(interviewHistoryProvider(userId));
    final interviewAvg = interviewAvgState.value ?? 0;
    final interviewCount = interviewHistoryState.value?.length ?? 0;

    // Check practice activity today for Notification Banner
    final now = DateTime.now();
    final todaySubmissions = submissions
        .where(
          (s) =>
              s.submittedAt.year == now.year &&
              s.submittedAt.month == now.month &&
              s.submittedAt.day == now.day,
        )
        .toList();
    final todayAptitude = aptitudeResults
        .where(
          (a) =>
              a.completedAt.year == now.year &&
              a.completedAt.month == now.month &&
              a.completedAt.day == now.day,
        )
        .toList();
    final hasPracticedToday =
        todaySubmissions.isNotEmpty || todayAptitude.isNotEmpty;

    // Time of day greeting
    String timeGreeting = 'Hello';
    final hour = now.hour;
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }

    return Scaffold(
      backgroundColor: context.appRootBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Greeting
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '$timeGreeting, $studentName 👋',
                                  style: GoogleFonts.inter(
                                    fontSize: isCompact ? 22 : 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: context.appTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Consumer(
                                builder: (context, ref, _) {
                                  final ptsObj = ref
                                      .watch(userPointsProvider(userId))
                                      .value;
                                  final pts = ptsObj?.totalPoints ?? 0;
                                  final tier = MedalTier.fromPoints(pts);
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      MedalBadgeWidget(
                                        tier: tier,
                                        isChip: true,
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: isDark ? 0.2 : 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          '$pts pts',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.accent
                                                : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Here is your placement readiness and preparation overview',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B1B27)
                            : const Color(0xFFF0EFF8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF292938)
                              : const Color(0xFFE5E4EF),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: isDark
                                ? AppColors.accent
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_getMonthName(now.month)} ${now.day}, ${now.year}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.accent
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // In-App Daily Streak Reminder Banner (if not practiced today)
                if (!hasPracticedToday) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.warning.withValues(
                            alpha: isDark ? 0.15 : 0.10,
                          ),
                          AppColors.warning.withValues(
                            alpha: isDark ? 0.08 : 0.04,
                          ),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: AppColors.warning,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Keep your preparation streak alive! 🔥",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFFF5F5FA)
                                      : const Color(0xFF191927),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "You haven't practiced today. Spend 10 minutes solving a challenge or quiz.",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.appTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            visualDensity: VisualDensity.compact,
                            textStyle: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () => context.go('/coding-problems'),
                          child: const Text('Practice Now'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 4 KPI Summary Cards Grid
                ResponsiveGrid(
                  minItemWidth: 200.0,
                  spacing: 14.0,
                  children: [
                    AppMetricCard(
                      title: 'Resume Score',
                      value: resumeScore > 0
                          ? '$resumeScore/100'
                          : 'Not scanned',
                      subtitle: latestReport != null
                          ? 'Evaluated by AI'
                          : 'Upload PDF in Profile',
                      icon: Icons.description_outlined,
                      iconColor: AppColors.primary,
                      trailingBadge: resumeScore > 0
                          ? SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                value: resumeScore / 100,
                                strokeWidth: 3,
                                color: AppColors.primary,
                                backgroundColor: isDark
                                    ? const Color(0xFF1B1B27)
                                    : const Color(0xFFEDE9FE),
                              ),
                            )
                          : null,
                      onTap: () => context.go('/resume-report'),
                    ),
                    AppMetricCard(
                      title: 'Problems Solved',
                      value: '$solvedCount/$totalProblems',
                      subtitle: '$codingPercent% of challenges',
                      icon: Icons.terminal_rounded,
                      iconColor: AppColors.success,
                      trailingBadge: AppBadge(
                        label: '$codingPercent%',
                        variant: AppBadgeVariant.success,
                      ),
                      onTap: () => context.go('/coding-problems'),
                    ),
                    AppMetricCard(
                      title: 'Aptitude Accuracy',
                      value: aptitudeResults.isNotEmpty
                          ? '$aptitudeAccuracy%'
                          : 'No tests',
                      subtitle: latestAptitude != null
                          ? '${latestAptitude.correctAnswers}/${latestAptitude.totalQuestions} correct'
                          : 'Take a PYQ quiz',
                      icon: Icons.psychology_outlined,
                      iconColor: AppColors.secondary,
                      trailingBadge: aptitudeResults.isNotEmpty
                          ? AppBadge(
                              label: 'PYQs',
                              variant: AppBadgeVariant.secondary,
                            )
                          : null,
                      onTap: () => context.go('/aptitude'),
                    ),
                    AppMetricCard(
                      title: 'Interview Readiness',
                      value: interviewAvg > 0
                          ? '$interviewAvg%'
                          : 'No sessions',
                      subtitle: interviewCount > 0
                          ? '$interviewCount sessions completed'
                          : 'Start mock interview',
                      icon: Icons.video_call_outlined,
                      iconColor: AppColors.warning,
                      trailingBadge: interviewCount > 0
                          ? AppBadge(
                              label: '$interviewCount done',
                              variant: AppBadgeVariant.warning,
                            )
                          : null,
                      onTap: () => context.go('/mock-interview'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Roadmap CTA Banner
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go('/roadmap'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22.0,
                        vertical: 20.0,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.35),
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
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.alt_route_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
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
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  roadmapState != null
                                      ? 'Target: ${roadmapState.role} — ${(roadmapState.overallProgress * 100).round()}% Completed'
                                      : 'Get a 4-8 week structured study plan tailored to your profile & test scores',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Performance Chart Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Preparation Performance Curves',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: context.appTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Multi-dimensional readiness breakdown',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.appTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(
                                alpha: isDark ? 0.2 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Real-time Metrics',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.accent
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: 3,
                            minY: 0,
                            maxY: 100,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 25,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: isDark
                                    ? const Color(0xFF292938)
                                    : const Color(0xFFE5E4EF),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (val, meta) {
                                    const categories = [
                                      'Resume',
                                      'Coding',
                                      'Aptitude',
                                      'Interview',
                                    ];
                                    int idx = val.toInt();
                                    if (idx >= 0 &&
                                        idx < categories.length &&
                                        val == idx.toDouble()) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          categories[idx],
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: context.appTextSecondary,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 25,
                                  reservedSize: 32,
                                  getTitlesWidget: (val, meta) {
                                    return Text(
                                      '${val.toInt()}%',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: context.appTextMuted,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  FlSpot(0, resumeScore.toDouble()),
                                  FlSpot(
                                    1,
                                    ((solvedCount /
                                                (totalProblems > 0
                                                    ? totalProblems
                                                    : 1)) *
                                            100)
                                        .toDouble(),
                                  ),
                                  FlSpot(2, aptitudeAccuracy.toDouble()),
                                  FlSpot(3, interviewAvg.toDouble()),
                                ],
                                isCurved: true,
                                curveSmoothness: 0.35,
                                color: AppColors.primary,
                                barWidth: 3.5,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) {
                                        return FlDotCirclePainter(
                                          radius: 4.5,
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                          strokeColor: AppColors.primary,
                                        );
                                      },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withValues(
                                        alpha: isDark ? 0.35 : 0.20,
                                      ),
                                      AppColors.primary.withValues(alpha: 0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions Section
                AppSectionHeader(
                  title: 'Quick Actions',
                  subtitle:
                      'Jump directly into your target placement preparation modules',
                ),
                const SizedBox(height: 14),
                if (isCompact) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            AppBreakpoints.minTouchTarget,
                          ),
                        ),
                        onPressed: () => context.go('/coding-problems'),
                        icon: const Icon(Icons.terminal_rounded, size: 18),
                        label: const Text('Practice Coding'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            AppBreakpoints.minTouchTarget,
                          ),
                        ),
                        onPressed: () => context.go('/aptitude'),
                        icon: const Icon(Icons.psychology_outlined, size: 18),
                        label: const Text('Aptitude Test'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            AppBreakpoints.minTouchTarget,
                          ),
                        ),
                        onPressed: () => context.go('/mock-interview'),
                        icon: const Icon(Icons.video_call_outlined, size: 18),
                        label: const Text('Mock Interview'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            AppBreakpoints.minTouchTarget,
                          ),
                        ),
                        onPressed: () => context.go('/leaderboard'),
                        icon: const Icon(Icons.emoji_events_outlined, size: 18),
                        label: const Text('Leaderboard'),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppBreakpoints.minTouchTarget,
                            ),
                          ),
                          onPressed: () => context.go('/coding-problems'),
                          icon: const Icon(Icons.terminal_rounded, size: 18),
                          label: const Text('Practice Coding'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppBreakpoints.minTouchTarget,
                            ),
                          ),
                          onPressed: () => context.go('/aptitude'),
                          icon: const Icon(Icons.psychology_outlined, size: 18),
                          label: const Text('Aptitude Test'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppBreakpoints.minTouchTarget,
                            ),
                          ),
                          onPressed: () => context.go('/mock-interview'),
                          icon: const Icon(Icons.video_call_outlined, size: 18),
                          label: const Text('Mock Interview'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppBreakpoints.minTouchTarget,
                            ),
                          ),
                          onPressed: () => context.go('/leaderboard'),
                          icon: const Icon(
                            Icons.emoji_events_outlined,
                            size: 18,
                          ),
                          label: const Text('Leaderboard'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 26),

                // Recent Activity Timeline
                AppSectionHeader(
                  title: 'Recent Activity',
                  subtitle:
                      'Your latest coding submissions and assessment sessions',
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    children: [
                      if (submissions.isNotEmpty ||
                          aptitudeResults.isNotEmpty ||
                          (interviewHistoryState.value?.isNotEmpty ==
                              true)) ...[
                        if (submissions.isNotEmpty)
                          _buildActivityItem(
                            context,
                            icon: Icons.terminal_rounded,
                            iconColor: submissions.first.passed
                                ? AppColors.success
                                : AppColors.warning,
                            title:
                                'Coding: ${submissions.first.language.toUpperCase()} Submission',
                            subtitle:
                                '${submissions.first.testCasesPassed}/${submissions.first.testCasesTotal} testcases passed — ${submissions.first.verdict}',
                            statusBadge: AppBadge(
                              label: submissions.first.passed
                                  ? 'PASSED'
                                  : 'RETRY',
                              variant: submissions.first.passed
                                  ? AppBadgeVariant.success
                                  : AppBadgeVariant.warning,
                            ),
                          ),
                        if (aptitudeResults.isNotEmpty) ...[
                          if (submissions.isNotEmpty) const Divider(height: 24),
                          _buildActivityItem(
                            context,
                            icon: Icons.psychology_outlined,
                            iconColor: AppColors.secondary,
                            title: 'Completed Aptitude Test Session',
                            subtitle:
                                '${aptitudeResults.first.correctAnswers}/${aptitudeResults.first.totalQuestions} correct (${aptitudeResults.first.accuracy.round()}%)',
                            statusBadge: AppBadge(
                              label:
                                  '${aptitudeResults.first.accuracy.round()}% ACCURACY',
                              variant: AppBadgeVariant.secondary,
                            ),
                          ),
                        ],
                        if (interviewHistoryState.value?.isNotEmpty ==
                            true) ...[
                          if (submissions.isNotEmpty ||
                              aptitudeResults.isNotEmpty)
                            const Divider(height: 24),
                          _buildActivityItem(
                            context,
                            icon: Icons.video_call_outlined,
                            iconColor: AppColors.warning,
                            title: 'Completed AI Mock Interview Session',
                            subtitle:
                                'Overall Readiness Score: ${interviewHistoryState.value!.first.overallScore}/100',
                            statusBadge: AppBadge(
                              label:
                                  '${interviewHistoryState.value!.first.overallScore}/100',
                              variant: AppBadgeVariant.warning,
                            ),
                          ),
                        ],
                      ] else ...[
                        AppEmptyState(
                          icon: Icons.history_rounded,
                          title: 'No recent practice activity yet',
                          message:
                              'Complete a coding problem or aptitude test to track your performance history here!',
                          actionLabel: 'Solve First Problem',
                          onAction: () => context.go('/coding-problems'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
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
    required String subtitle,
    Widget? statusBadge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),
        ?statusBadge,
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
