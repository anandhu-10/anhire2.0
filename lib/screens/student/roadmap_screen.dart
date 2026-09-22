import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/roadmap_model.dart';
import '../../providers/roadmap_provider.dart';

class RoadmapScreen extends ConsumerWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roadmapAsync = ref.watch(userRoadmapProvider);
    final controllerState = ref.watch(roadmapControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalized Learning Roadmap'),
        actions: [
          if (roadmapAsync.value != null && !controllerState.isGenerating)
            IconButton(
              icon: const Icon(Icons.refresh),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _buildErrorState(context, ref, err.toString()),
            ),
    );
  }

  /// 1. Hero / No Roadmap State
  Widget _buildHeroEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.map_outlined,
                  size: 52,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AI Placement Learning Roadmap',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Get a 4-8 week structured study plan tailored to your target role, companies, ATS resume score, aptitude accuracy, and mock interview performance.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              _buildFeatureBullet(
                context,
                Icons.analytics_outlined,
                'Analyzes your real-time performance metrics',
              ),
              const SizedBox(height: 10),
              _buildFeatureBullet(
                context,
                Icons.check_circle_outline,
                'Interactive weekly task checklist saved automatically',
              ),
              const SizedBox(height: 10),
              _buildFeatureBullet(
                context,
                Icons.auto_awesome,
                'Customized Gemini 3.6 AI study recommendations',
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: AppBreakpoints.minTouchTarget,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    ref.read(roadmapControllerProvider.notifier).generatePersonalizedRoadmap();
                  },
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: const Text(
                    'Generate My Roadmap',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  /// 2. Generating Progress State
  Widget _buildGeneratingState(BuildContext context, String? statusMessage) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Crafting Your Personalized Plan...',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              statusMessage ?? 'Evaluating test history & ATS metrics...',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Roadmap View with Timeline
  Widget _buildRoadmapTimeline(BuildContext context, WidgetRef ref, Roadmap roadmap) {
    final theme = Theme.of(context);
    final overallPct = (roadmap.overallProgress * 100).round();

    int totalTasks = 0;
    int completedTasks = 0;
    for (var week in roadmap.weeks) {
      totalTasks += week.totalTasksCount;
      completedTasks += week.completedTasksCount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxCardWidthMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Progress Bar
              Card(
                margin: EdgeInsets.zero,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
                                  'Your Preparation Roadmap',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Target: ${roadmap.role} @ ${roadmap.companies}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                            child: Text(
                              '$overallPct% Completed',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: roadmap.overallProgress.clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$completedTasks of $totalTasks tasks checked off',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
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

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Timeline Column (Numbered Circle + Connecting Vertical Line)
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: week.progressPercentage >= 1.0
                                  ? Colors.green
                                  : (week.completedTasksCount > 0
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surfaceContainerHighest),
                              child: week.progressPercentage >= 1.0
                                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                                  : Text(
                                      '${week.weekNumber}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: week.completedTasksCount > 0 ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: theme.colorScheme.outlineVariant,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        // Right Content Column (ExpansionTile Card)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: ExpansionTile(
                                initiallyExpanded: weekIdx == 0 || (week.completedTasksCount < week.totalTasksCount && weekIdx > 0 && roadmap.weeks[weekIdx - 1].completedTasksCount == roadmap.weeks[weekIdx - 1].totalTasksCount),
                                shape: const RoundedRectangleBorder(side: BorderSide.none),
                                title: Text(
                                  'Week ${week.weekNumber}: ${week.focus}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '${week.completedTasksCount}/${week.totalTasksCount} tasks done',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: week.completedTasksCount == week.totalTasksCount && week.totalTasksCount > 0
                                          ? Colors.green
                                          : AppColors.textSecondary,
                                      fontWeight: week.completedTasksCount == week.totalTasksCount ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Divider(height: 16),
                                        if (week.topics.isNotEmpty) ...[
                                          const Text(
                                            'Topics Covered',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: week.topics.map((topic) {
                                              return Chip(
                                                label: Text(
                                                  topic,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                padding: EdgeInsets.zero,
                                                visualDensity: VisualDensity.compact,
                                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                        const Text(
                                          'Action Items Checklist',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        ...List.generate(week.tasks.length, (taskIdx) {
                                          final task = week.tasks[taskIdx];
                                          return CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            activeColor: theme.colorScheme.primary,
                                            value: task.completed,
                                            title: Text(
                                              task.text,
                                              style: TextStyle(
                                                fontSize: 14,
                                                decoration: task.completed
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                                color: task.completed
                                                    ? AppColors.textMuted
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                            onChanged: (val) {
                                              ref.read(roadmapControllerProvider.notifier).toggleTask(
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
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  onPressed: () => _showRegenerateDialog(context, ref),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Regenerate Roadmap'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String errorMsg) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('Error Loading Roadmap', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(errorMsg, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(roadmapControllerProvider.notifier).generatePersonalizedRoadmap(),
              icon: const Icon(Icons.refresh),
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
        title: const Text('Regenerate Study Plan?'),
        content: const Text(
          'This will analyze your latest test history and replace your current roadmap with an updated study timeline. Checked tasks will be reset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(roadmapControllerProvider.notifier).generatePersonalizedRoadmap();
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }
}
