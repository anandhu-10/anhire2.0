import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/interview_models.dart';
import '../../providers/interview_provider.dart';
import '../../widgets/responsive_grid.dart';

class InterviewResultsScreen extends ConsumerWidget {
  final String sessionId;

  const InterviewResultsScreen({Key? key, required this.sessionId}) : super(key: key);

  Color _getScoreColor(int score) {
    if (score >= 70) return const Color(0xFF4CAF50);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  Map<String, double> _calculateCategoryAverages(List<InterviewQuestion> questions) {
    final Map<String, List<int>> scores = {
      'technical': [],
      'behavioral': [],
      'hr': [],
      'situational': [],
    };

    for (final q in questions) {
      if (q.evaluation != null) {
        final key = q.type.toLowerCase();
        if (scores.containsKey(key)) {
          scores[key]!.add(q.evaluation!.overallScore);
        }
      }
    }

    final Map<String, double> averages = {};
    scores.forEach((cat, list) {
      if (list.isEmpty) {
        averages[cat] = 0.0;
      } else {
        final sum = list.fold<int>(0, (a, b) => a + b);
        averages[cat] = (sum / list.length) / 10.0; // out of 10
      }
    });

    return averages;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interviewProvider);
    final session = state.completedSession;
    final questions = session?.questions ?? state.questions;
    final overallScore = session?.overallScore ?? state.runningAverageScore;
    final role = session?.role ?? state.selectedRole;
    final company = session?.company ?? state.selectedCompany;
    final scoreColor = _getScoreColor(overallScore);

    final catAverages = _calculateCategoryAverages(questions);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Interview Performance Report', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.bgDark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Score Gauge Card
                Card(
                  color: AppColors.bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.chipBorder, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      children: [
                        const Text(
                          'Interview Complete!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$role Candidate @ $company',
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),

                        // Circular Score Gauge
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: CircularProgressIndicator(
                                value: (overallScore / 100).clamp(0.0, 1.0),
                                strokeWidth: 12,
                                backgroundColor: AppColors.chipBorder,
                                color: scoreColor,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$overallScore%',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: scoreColor,
                                  ),
                                ),
                                const Text(
                                  'Overall Score',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Category Averages Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCategoryScoreTile('Technical', catAverages['technical'] ?? 0.0),
                            _buildCategoryScoreTile('Behavioral', catAverages['behavioral'] ?? 0.0),
                            _buildCategoryScoreTile('HR', catAverages['hr'] ?? 0.0),
                            _buildCategoryScoreTile('Situational', catAverages['situational'] ?? 0.0),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section Title
                const Text(
                  'Per-Question Detailed Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Questions Grid
                ResponsiveGrid(
                  minItemWidth: 440,
                  children: List.generate(questions.length, (idx) {
                    final q = questions[idx];
                    final eval = q.evaluation;
                    final qScore = eval?.overallScore ?? 0;
                    final qScoreColor = _getScoreColor(qScore);

                    return Card(
                      color: AppColors.bgCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.chipBorder, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Question ${idx + 1}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: qScoreColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: qScoreColor),
                                  ),
                                  child: Text(
                                    '$qScore / 100',
                                    style: TextStyle(
                                      color: qScoreColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Text(
                              q.question,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),

                            if (q.userAnswer != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.bgDark,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Response: ${q.userAnswer}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            if (eval != null) ...[
                              _buildMiniBar('Clarity', eval.clarityScore),
                              const SizedBox(height: 4),
                              _buildMiniBar('Correctness', eval.correctnessScore),
                              const SizedBox(height: 4),
                              _buildMiniBar('Confidence', eval.confidenceScore),
                              const SizedBox(height: 10),
                              Text(
                                eval.feedback,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),

                // Bottom Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(interviewProvider.notifier).resetInterview();
                            context.go('/mock-interview');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textAccent,
                            side: const BorderSide(color: AppColors.bgPurple, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Retake Interview', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(interviewProvider.notifier).resetInterview();
                            context.go('/dashboard');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bgPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryScoreTile(String label, double scoreOutOf10) {
    return Column(
      children: [
        Text(
          '${scoreOutOf10.toStringAsFixed(1)}/10',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildMiniBar(String label, int scoreOutOf10) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: (scoreOutOf10 / 10.0).clamp(0.0, 1.0),
            backgroundColor: AppColors.chipBorder,
            color: AppColors.bgPurple,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text('$scoreOutOf10/10', style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
      ],
    );
  }
}
