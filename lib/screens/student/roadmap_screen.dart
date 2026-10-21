import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/roadmap_model.dart';
import '../../providers/roadmap_provider.dart';
import '../../widgets/app_components.dart';

class RoadmapScreen extends ConsumerWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roadmapAsync = ref.watch(userRoadmapProvider);
    final controllerState = ref.watch(roadmapControllerProvider);

    return Scaffold(
      backgroundColor: context.appRootBg,
      appBar: AppBar(
        title: Text(
          'Personalized Learning Roadmap',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (roadmapAsync.value != null && !controllerState.isGenerating)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Regenerate Roadmap',
              onPressed: () => _showRegenerateDialog(context, ref),
            ),
        ],
      ),
      body: controllerState.isGenerating
          ? _buildGeneratingState(context, controllerState.statusMessage)
          : roadmapAsync.when(
              data: (roadmap) {
                if (roadmap == null || roadmap.weeks.isEmpty) {
                  return _buildHeroEmptyState(context, ref);
                }
                return _buildRoadmapTimeline(context, ref, roadmap);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) =>
                  _buildErrorState(context, ref, err.toString()),
            ),
    );
  }

  /// 1. Hero / No Roadmap State
  Widget _buildHeroEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.alt_route_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'AI Placement Learning Roadmap',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Generate a 4-8 week structured study plan tailored to your target roles, companies, ATS resume feedback, and aptitude assessment performance.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.appTextSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _buildFeatureBullet(
                context,
                Icons.analytics_outlined,
                'Analyzes your real-time practice metrics & scores',
              ),
              const SizedBox(height: 12),
              _buildFeatureBullet(
                context,
                Icons.check_circle_outline_rounded,
                'Interactive weekly task checklist saved automatically',
              ),
              const SizedBox(height: 12),
              _buildFeatureBullet(
                context,
                Icons.auto_awesome_rounded,
                'Customized AI study recommendations & milestone tracking',
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    ref
                        .read(roadmapControllerProvider.notifier)
                        .generatePersonalizedRoadmap();
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                  label: Text(
                    'Generate My Personalized Roadmap',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBullet(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Generating Progress State
  Widget _buildGeneratingState(BuildContext context, String? statusMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Crafting Your Personalized Plan...',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.3,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusMessage ??
                  'Evaluating test history, coding speed, and ATS metrics...',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Roadmap View with Timeline
  Widget _buildRoadmapTimeline(
    BuildContext context,
    WidgetRef ref,
    Roadmap roadmap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overallPct = (roadmap.overallProgress * 100).round();

    int totalTasks = 0;
    int completedTasks = 0;
    for (var week in roadmap.weeks) {
      totalTasks += week.totalTasksCount;
      completedTasks += week.completedTasksCount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxCardWidthMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Progress Bar
              AppCard(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Placement Roadmap',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: context.appTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Target: ${roadmap.role} @ ${roadmap.companies}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: context.appTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '$overallPct% Completed',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.accent
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: roadmap.overallProgress.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: context.appSurfaceAlt,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completedTasks of $totalTasks action tasks checked off',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Vertical Week-by-Week Timeline List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: roadmap.weeks.length,
                itemBuilder: (context, weekIdx) {
                  final week = roadmap.weeks[weekIdx];
                  final isLast = weekIdx == roadmap.weeks.length - 1;
                  final isWeekDone = week.progressPercentage >= 1.0;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Timeline Column (Numbered Circle + Connecting Vertical Line)
                        Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isWeekDone
                                    ? AppColors.success
                                    : (week.completedTasksCount > 0
                                          ? AppColors.primary
                                          : context.appSurfaceAlt),
                                border:
                                    isWeekDone || week.completedTasksCount > 0
                                    ? null
                                    : Border.all(color: context.appBorder),
                              ),
                              child: Center(
                                child: isWeekDone
                                    ? const Icon(
                                        Icons.check,
                                        size: 18,
                                        color: Colors.white,
                                      )
                                    : Text(
                                        '${week.weekNumber}',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: week.completedTasksCount > 0
                                              ? Colors.white
                                              : context.appTextSecondary,
                                        ),
                                      ),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: isWeekDone
                                      ? AppColors.success.withValues(alpha: 0.5)
                                      : context.appBorder,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        // Right Content Column (Expansion Card)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: AppCard(
                              padding: EdgeInsets.zero,
                              child: ExpansionTile(
                                initiallyExpanded:
                                    weekIdx == 0 ||
                                    (week.completedTasksCount <
                                            week.totalTasksCount &&
                                        weekIdx > 0 &&
                                        roadmap
                                                .weeks[weekIdx - 1]
                                                .completedTasksCount ==
                                            roadmap
                                                .weeks[weekIdx - 1]
                                                .totalTasksCount),
                                shape: const RoundedRectangleBorder(
                                  side: BorderSide.none,
                                ),
                                title: Text(
                                  'Week ${week.weekNumber}: ${week.focus}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: context.appTextPrimary,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '${week.completedTasksCount}/${week.totalTasksCount} tasks completed',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isWeekDone
                                          ? AppColors.success
                                          : context.appTextSecondary,
                                      fontWeight: isWeekDone
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18.0,
                                      0.0,
                                      18.0,
                                      18.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Divider(
                                          color: context.appBorder,
                                          height: 16,
                                        ),
                                        if (week.topics.isNotEmpty) ...[
                                          Text(
                                            'Topics Covered',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: context.appTextSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: week.topics.map((topic) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: context.appSurfaceAlt,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: context.appBorder,
                                                  ),
                                                ),
                                                child: Text(
                                                  topic,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        context.appTextPrimary,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(height: 14),
                                        ],
                                        Text(
                                          'Action Items Checklist',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: context.appTextSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ...List.generate(week.tasks.length, (
                                          taskIdx,
                                        ) {
                                          final task = week.tasks[taskIdx];
                                          return CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            activeColor: AppColors.primary,
                                            value: task.completed,
                                            title: Text(
                                              task.text,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                decoration: task.completed
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                                color: task.completed
                                                    ? context.appTextMuted
                                                    : context.appTextPrimary,
                                              ),
                                            ),
                                            onChanged: (val) {
                                              ref
                                                  .read(
                                                    roadmapControllerProvider
                                                        .notifier,
                                                  )
                                                  .toggleTask(
                                                    weekIndex: weekIdx,
                                                    taskIndex: taskIdx,
                                                    completed: val ?? false,
                                                  );
                                            },
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Bottom Regenerate Button
              Center(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(220, AppBreakpoints.minTouchTarget),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  onPressed: () => _showRegenerateDialog(context, ref),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Regenerate Study Plan'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String errorMsg,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Roadmap',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMsg,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.appTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(roadmapControllerProvider.notifier)
                  .generatePersonalizedRoadmap(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegenerateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Regenerate Study Plan?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will analyze your latest test history and replace your current roadmap with an updated study timeline. Checked tasks will be reset.',
          style: GoogleFonts.inter(
            color: context.appTextSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(roadmapControllerProvider.notifier)
                  .generatePersonalizedRoadmap();
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }
}
