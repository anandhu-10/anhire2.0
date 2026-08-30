import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/interview_models.dart';
import '../../providers/interview_provider.dart';

class InterviewRunnerScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const InterviewRunnerScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  ConsumerState<InterviewRunnerScreen> createState() => _InterviewRunnerScreenState();
}

class _InterviewRunnerScreenState extends ConsumerState<InterviewRunnerScreen> {
  final _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _handleSubmitAnswer() async {
    final text = _answerController.text.trim();
    if (text.length < 50) return;

    final notifier = ref.read(interviewProvider.notifier);
    await notifier.submitAnswer(text);
  }

  void _handleNextQuestion() async {
    final state = ref.read(interviewProvider);
    final notifier = ref.read(interviewProvider.notifier);

    _answerController.clear();

    if (state.currentIndex < state.questions.length - 1) {
      await notifier.nextQuestion();
    } else {
      await notifier.finishInterview();
      if (mounted) {
        context.go('/interview-results/${widget.sessionId}');
      }
    }
  }

  Color _getTypeBadgeColor(String type) {
    switch (type.toLowerCase()) {
      case 'technical':
        return const Color(0xFF2196F3);
      case 'behavioral':
        return const Color(0xFF9C27B0);
      case 'hr':
        return const Color(0xFFFF9800);
      case 'situational':
        return const Color(0xFF009688);
      default:
        return AppColors.bgPurple;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return const Color(0xFF4CAF50);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interviewProvider);
    final currentQ = state.currentQuestion;
    final totalQ = state.questions.length;
    final currentIndex = state.currentIndex;
    final isEvaluating = state.status == InterviewStatus.evaluating;
    final hasEvaluated = currentQ?.evaluation != null;

    if (currentQ == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.bgPurple),
              const SizedBox(height: 16),
              const Text('Preparing interview runner...', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/mock-interview'),
                child: const Text('Back to Setup'),
              ),
            ],
          ),
        ),
      );
    }

    final progress = totalQ > 0 ? (currentIndex + 1) / totalQ : 0.0;
    final charCount = _answerController.text.trim().length;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(
          '${state.selectedRole} @ ${state.selectedCompany}',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        backgroundColor: AppColors.bgDark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgPurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Avg: ${state.runningAverageScore}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Progress Bar
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.bgCard,
                  color: AppColors.bgPurple,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${currentIndex + 1} of $totalQ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTypeBadgeColor(currentQ.type).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getTypeBadgeColor(currentQ.type)),
                      ),
                      child: Text(
                        currentQ.type.toUpperCase(),
                        style: TextStyle(
                          color: _getTypeBadgeColor(currentQ.type),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Question Card
                Card(
                  color: AppColors.bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.chipBorder, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentQ.question,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Answer Box (Active or Evaluated)
                        if (!hasEvaluated) ...[
                          TextField(
                            controller: _answerController,
                            maxLines: 6,
                            minLines: 4,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Type your answer here (minimum 50 characters)...',
                              hintStyle: const TextStyle(color: AppColors.textMuted),
                              filled: true,
                              fillColor: AppColors.bgDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.chipBorder),
                              ),
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                charCount < 50
                                    ? 'Minimum 50 characters required (${50 - charCount} more needed)'
                                    : 'Ready to submit',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: charCount < 50 ? Colors.orange : Colors.green,
                                ),
                              ),
                              Text(
                                '$charCount / 2000',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: (charCount < 50 || isEvaluating) ? null : _handleSubmitAnswer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.bgPurple,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.chipBorder,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isEvaluating
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        ),
                                        SizedBox(width: 12),
                                        Text('Gemini is evaluating your answer...',
                                            style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    )
                                  : const Text('Submit Answer',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ] else ...[
                          // Display User Answer
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.bgDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.chipBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Response:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  currentQ.userAnswer ?? '',
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Revealed Tip Keywords
                          if (currentQ.expectedKeywords.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.bgPurple.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.bgPurple.withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lightbulb_outline, color: AppColors.textAccent, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Expected Keywords: ${currentQ.expectedKeywords.join(", ")}',
                                      style: const TextStyle(color: AppColors.textAccent, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Gemini Evaluation Card
                          _buildEvaluationCard(currentQ.evaluation!),
                          const SizedBox(height: 24),

                          // Next Question Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _handleNextQuestion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.bgPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(
                                currentIndex < totalQ - 1 ? Icons.arrow_forward : Icons.check_circle_outline,
                              ),
                              label: Text(
                                currentIndex < totalQ - 1 ? 'Next Question' : 'Finish Interview',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildEvaluationCard(AnswerEvaluation eval) {
    final scoreColor = _getScoreColor(eval.overallScore);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.textAccent, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Gemini Evaluation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textAccent,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scoreColor),
                ),
                child: Text(
                  'Score: ${eval.overallScore}/100',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Score Meters (Clarity, Correctness, Confidence)
          _buildScoreBar('Clarity', eval.clarityScore),
          const SizedBox(height: 8),
          _buildScoreBar('Correctness', eval.correctnessScore),
          const SizedBox(height: 8),
          _buildScoreBar('Confidence', eval.confidenceScore),
          const SizedBox(height: 16),

          // Feedback Text
          Text(
            eval.feedback,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Strengths
          if (eval.strengths.isNotEmpty) ...[
            const Text(
              'Strengths:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 4),
            ...eval.strengths.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check, color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(s, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
          ],

          // Improvements
          if (eval.improvements.isNotEmpty) ...[
            const Text(
              'Areas to Improve:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 4),
            ...eval.improvements.map((imp) => Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.orange, size: 8),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(imp, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, int scoreOutOf10) {
    final percent = (scoreOutOf10 / 10.0).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: AppColors.chipBorder,
            color: AppColors.bgPurple,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$scoreOutOf10/10',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
