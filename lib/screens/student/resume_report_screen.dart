import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/resume_report_model.dart';
import '../../providers/resume_provider.dart';
import '../../widgets/app_components.dart';

class ResumeReportScreen extends ConsumerWidget {
  const ResumeReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < AppBreakpoints.compactBreakpoint;
    final reportAsync = ref.watch(latestResumeReportProvider);

    return Scaffold(
      backgroundColor: context.appRootBg,
      appBar: AppBar(
        backgroundColor: context.appRootBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(
          'Resume Analysis Report',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: reportAsync.when(
        data: (report) {
          if (report == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: AppEmptyState(
                  icon: Icons.description_outlined,
                  title: 'No Resume Report Available',
                  description:
                      'Upload your resume PDF from your Profile page to generate a real-time AI ATS compatibility report.',
                  actionLabel: 'Go to Profile & Upload',
                  onAction: () => context.go('/profile'),
                ),
              ),
            );
          }

          return _buildReportContent(context, report, isCompact);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text(
            'Error loading report: $err',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(
    BuildContext context,
    ResumeReportModel report,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final overallScore = report.overallScore;

    Color scoreColor = AppColors.error;
    if (overallScore >= 50 && overallScore <= 75)
      scoreColor = AppColors.warning;
    if (overallScore > 75) scoreColor = AppColors.success;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxCardWidthMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Score Card with Circular Gauge
              AppCard(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  children: [
                    Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: overallScore / 100),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 140,
                                height: 140,
                                child: CircularProgressIndicator(
                                  value: val,
                                  strokeWidth: 12,
                                  color: scoreColor,
                                  backgroundColor: scoreColor.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(val * 100).toInt()}',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      color: scoreColor,
                                    ),
                                  ),
                                  Text(
                                    '/ 100',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: context.appTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ATS Compatibility Score',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      overallScore >= 80
                          ? 'Excellent! Your resume ranks in the top tier of candidates for your target role.'
                          : (overallScore >= 60
                                ? 'Good score. Make a few targeted keyword improvements to rank higher.'
                                : 'Needs optimization. Review the section feedback and missing keywords below.'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.appTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Expandable Section Breakdown Cards
              Text(
                'Section Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...report.sections.map(
                (sec) => _ExpandableSectionCard(
                  name: sec.name,
                  score: sec.score,
                  feedback: sec.feedback,
                ),
              ),
              const SizedBox(height: 24),

              // Missing Keywords Red Chips
              if (report.missingKeywords.isNotEmpty) ...[
                AppCard(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Missing High-Impact Keywords',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: report.missingKeywords.map((kw) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              kw,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Numbered Actionable Suggestions
              if (report.suggestions.isNotEmpty) ...[
                AppCard(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actionable Optimization Tips',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...List.generate(report.suggestions.length, (i) {
                        return _buildTipRow(
                          context,
                          '${i + 1}',
                          report.suggestions[i],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Upload New Resume Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/profile'),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload New Resume PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipRow(BuildContext context, String numStr, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              numStr,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableSectionCard extends StatefulWidget {
  final String name;
  final int score;
  final String feedback;

  const _ExpandableSectionCard({
    required this.name,
    required this.score,
    required this.feedback,
  });

  @override
  State<_ExpandableSectionCard> createState() => _ExpandableSectionCardState();
}

class _ExpandableSectionCardState extends State<_ExpandableSectionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isLongText = widget.feedback.length > 80;
    final truncatedFeedback = isLongText
        ? '${widget.feedback.substring(0, 80)}...'
        : widget.feedback;

    Color scoreColor = AppColors.error;
    if (widget.score >= 50 && widget.score <= 75)
      scoreColor = AppColors.warning;
    if (widget.score > 75) scoreColor = AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.score}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: context.appTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: context.appTextMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedCrossFade(
                firstChild: Text(
                  truncatedFeedback,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: context.appTextSecondary,
                  ),
                ),
                secondChild: Text(
                  widget.feedback,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: context.appTextPrimary,
                  ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
