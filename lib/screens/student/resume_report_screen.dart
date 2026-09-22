import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/resume_report_model.dart';
import '../../providers/resume_provider.dart';

class ResumeReportScreen extends ConsumerWidget {
  const ResumeReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < AppBreakpoints.compactBreakpoint;
    final reportAsync = ref.watch(latestResumeReportProvider);

    return Scaffold(
      appBar: AppBar(
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
        title: const Text('Resume Analysis Report'),
      ),
      body: reportAsync.when(
        data: (report) {
          if (report == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No Resume Report Available',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload your resume PDF from your Profile page to generate a real-time AI ATS compatibility report.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/profile'),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Go to Profile & Upload'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildReportContent(context, report, isCompact);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text('Error loading report: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, ResumeReportModel report, bool isCompact) {
    final theme = Theme.of(context);
    final overallScore = report.overallScore;

    Color scoreColor = Colors.red;
    if (overallScore >= 50 && overallScore <= 75) scoreColor = Colors.orange;
    if (overallScore > 75) scoreColor = Colors.green;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxCardWidthMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Score Card with Circular Gauge
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
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
                                    backgroundColor: scoreColor.withOpacity(0.15),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(val * 100).toInt()}',
                                      style: TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: scoreColor,
                                      ),
                                    ),
                                    const Text(
                                      '/ 100',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('ATS Compatibility Score', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        overallScore >= 80
                            ? 'Excellent! Your resume ranks in the top tier of candidates for your target role.'
                            : (overallScore >= 60
                                ? 'Good score. Make a few targeted keyword improvements to rank higher.'
                                : 'Needs optimization. Review the section feedback and missing keywords below.'),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Expandable Section Breakdown Cards
              Text('Section Breakdown', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              ...report.sections.map((sec) => _ExpandableSectionCard(
                    name: sec.name,
                    score: sec.score,
                    feedback: sec.feedback,
                  )),
              const SizedBox(height: 20),

              // Missing Keywords Red Chips
              if (report.missingKeywords.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('Missing High-Impact Keywords', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: report.missingKeywords.map((kw) {
                            return Chip(
                              label: Text(kw),
                              backgroundColor: Colors.red.withOpacity(0.1),
                              labelStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Numbered Actionable Suggestions
              if (report.suggestions.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Actionable Optimization Tips', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        ...List.generate(report.suggestions.length, (i) {
                          return _buildTipRow('${i + 1}', report.suggestions[i]);
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Upload New Resume Button
              SizedBox(
                width: double.infinity,
                height: AppBreakpoints.minTouchTarget,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/profile-setup'),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload New Resume PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipRow(String numStr, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: const Color(0xFF6750A4),
            child: Text(numStr, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
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
    super.key,
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
    final theme = Theme.of(context);
    final isLongText = widget.feedback.length > 80;
    final truncatedFeedback = isLongText
        ? '${widget.feedback.substring(0, 80)}...'
        : widget.feedback;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      '${widget.score}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedCrossFade(
                firstChild: Text(
                  truncatedFeedback,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                secondChild: Text(
                  widget.feedback,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
                crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
