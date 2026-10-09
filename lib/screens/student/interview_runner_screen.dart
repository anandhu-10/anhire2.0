import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/interview_models.dart';
import '../../providers/interview_provider.dart';
import '../../core/utils/answer_validator.dart';

class InterviewRunnerScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const InterviewRunnerScreen({super.key, required this.sessionId});

  @override
  ConsumerState<InterviewRunnerScreen> createState() => _InterviewRunnerScreenState();
}

class _InterviewRunnerScreenState extends ConsumerState<InterviewRunnerScreen> {
  final _answerController = TextEditingController();
  String? _activeQuestionId;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    AnswerValidator.loadDictionary();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _syncAnswerController(InterviewQuestion question) {
    if (_activeQuestionId != question.id) {
      _activeQuestionId = question.id;
      _isEditing = false;
      _answerController.text = question.userAnswer ?? '';
    }
  }

  void _handleSubmitAnswer() async {
    final text = _answerController.text.trim();
    final validation = await AnswerValidator.validateAnswerLayerA(text);

    if (!validation.isValid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            validation.errorMessage.isNotEmpty
                ? validation.errorMessage
                : "This doesn't look like a meaningful answer. Please write a proper response to the question.",
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final notifier = ref.read(interviewProvider.notifier);
    await notifier.submitAnswer(text);
  }

  void _handleStartEdit() {
    final currentQ = ref.read(interviewProvider).currentQuestion;
    if (currentQ == null) return;
    setState(() {
      _isEditing = true;
      _answerController.text = currentQ.userAnswer ?? '';
    });
  }

  void _handleCancelEdit() {
    final currentQ = ref.read(interviewProvider).currentQuestion;
    if (currentQ == null) return;
    setState(() {
      _isEditing = false;
      _answerController.text = currentQ.userAnswer ?? '';
    });
  }

  void _handlePreviousQuestion() {
    final notifier = ref.read(interviewProvider.notifier);
    notifier.updateDraftAnswer(_answerController.text.trim());
    setState(() {
      _isEditing = false;
    });
    notifier.previousQuestion();
  }

  void _handleNextQuestion() async {
    final state = ref.read(interviewProvider);
    final notifier = ref.read(interviewProvider.notifier);

    notifier.updateDraftAnswer(_answerController.text.trim());
    setState(() {
      _isEditing = false;
    });

    if (state.hasNextQuestion) {
      notifier.nextQuestion();
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
    final isQuestionEvaluating = isEvaluating && state.evaluatingQuestionId == currentQ?.id;
    final hasEvaluated = currentQ?.evaluation != null;
    final bool showEvaluatedView = hasEvaluated && !_isEditing;

    // Listen for completion of evaluation or error messages
    ref.listen<InterviewState>(interviewProvider, (previous, next) {
      if (previous?.status == InterviewStatus.evaluating &&
          next.status == InterviewStatus.answering &&
          next.errorMessage == null) {
        if (mounted) {
          setState(() {
            _isEditing = false;
          });
        }
      }
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

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

    _syncAnswerController(currentQ);
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
                        color: _getTypeBadgeColor(currentQ.type).withAlpha(51),
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

                        // Answer Input Area (Initial Submission OR Edit Mode)
                        if (!showEvaluatedView) ...[
                          TextField(
                            controller: _answerController,
                            maxLines: 6,
                            minLines: 4,
                            enabled: !isQuestionEvaluating,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: _isEditing
                                  ? 'Edit your answer here (minimum 50 characters)...'
                                  : 'Type your answer here (minimum 50 characters)...',
                              hintStyle: const TextStyle(color: AppColors.textMuted),
                              filled: true,
                              fillColor: AppColors.bgDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.chipBorder),
                              ),
                            ),
                            onChanged: (val) {
                              ref.read(interviewProvider.notifier).updateDraftAnswer(val);
                              setState(() {});
                            },
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

                          // Initial Submission Button OR Edit Action Buttons
                          if (!_isEditing) ...[
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
                                child: isQuestionEvaluating
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          ),
                                          SizedBox(width: 12),
                                          Text('AI is evaluating your answer...',
                                              style: TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      )
                                    : const Text('Submit Answer',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ] else ...[
                            // Edit Mode Button Row: [ Cancel Editing ] & [ Resubmit Answer ]
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      onPressed: isEvaluating ? null : _handleCancelEdit,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.textPrimary,
                                        side: const BorderSide(color: AppColors.chipBorder),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(Icons.close, size: 18),
                                      label: const Text(
                                        'Cancel Editing',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: (charCount < 50 || isEvaluating) ? null : _handleSubmitAnswer,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.bgPurple,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: AppColors.chipBorder,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: isQuestionEvaluating
                                          ? null
                                          : const Icon(Icons.refresh, size: 18),
                                      label: isQuestionEvaluating
                                          ? const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                ),
                                                SizedBox(width: 8),
                                                Text('Evaluating...', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ],
                                            )
                                          : const Text(
                                              'Resubmit Answer',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 24),
                        ] else ...[
                          // Read-Only Evaluated View with Edit Button
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Your Response:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _handleStartEdit,
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 14, color: AppColors.textAccent),
                                            SizedBox(width: 4),
                                            Text(
                                              'Edit Answer',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
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
                                color: AppColors.bgPurple.withAlpha(38),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.bgPurple.withAlpha(102)),
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

                          // AI Evaluation Card
                          _buildEvaluationCard(currentQ.evaluation!),
                          const SizedBox(height: 16),

                          // Explicit Edit & Resubmit Button
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _handleStartEdit,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textAccent,
                                side: const BorderSide(color: AppColors.bgPurple),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text(
                                'Edit & Resubmit Answer',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Navigation Buttons Row: Previous Question & Next Question
                        Row(
                          children: [
                            // Previous Question Button
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: (state.hasPreviousQuestion && !isEvaluating)
                                      ? _handlePreviousQuestion
                                      : null,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textPrimary,
                                    disabledForegroundColor: AppColors.textMuted.withAlpha(102),
                                    side: BorderSide(
                                      color: (state.hasPreviousQuestion && !isEvaluating)
                                          ? AppColors.chipBorder
                                          : AppColors.chipBorder.withAlpha(77),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.arrow_back, size: 18),
                                  label: const Text(
                                    'Previous Question',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Next Question / Finish Interview Button
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: isEvaluating ? null : _handleNextQuestion,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.bgPurple,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: AppColors.chipBorder,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: Icon(
                                    state.hasNextQuestion ? Icons.arrow_forward : Icons.check_circle_outline,
                                    size: 18,
                                  ),
                                  label: Text(
                                    state.hasNextQuestion ? 'Next Question' : 'Finish Interview',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildEvaluationCard(AnswerEvaluation eval) {
    final bool isValid = eval.valid && eval.overallScore > 0;
    final scoreColor = isValid ? _getScoreColor(eval.overallScore) : Colors.red;

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
              Row(
                children: [
                  Icon(
                    isValid ? Icons.auto_awesome : Icons.warning_amber_rounded,
                    color: isValid ? AppColors.textAccent : Colors.red,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isValid ? 'AI Evaluation' : 'Invalid answer — 0/100',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isValid ? AppColors.textAccent : Colors.red,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scoreColor),
                ),
                child: Text(
                  isValid ? 'Score: ${eval.overallScore}/100' : '0/100',
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

          if (isValid) ...[
            _buildScoreBar('Clarity', eval.clarityScore),
            const SizedBox(height: 8),
            _buildScoreBar('Correctness', eval.correctnessScore),
            const SizedBox(height: 8),
            _buildScoreBar('Confidence', eval.confidenceScore),
            const SizedBox(height: 16),
          ],

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

          // Strengths (only when valid)
          if (eval.valid && eval.strengths.isNotEmpty) ...[
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
            Text(
              eval.valid ? 'Areas to Improve:' : 'Action Required:',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange),
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
