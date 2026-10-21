import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/aptitude_problem_model.dart';
import '../../providers/aptitude_provider.dart';
import '../../widgets/app_components.dart';

class AptitudeScreen extends ConsumerStatefulWidget {
  const AptitudeScreen({super.key});

  @override
  ConsumerState<AptitudeScreen> createState() => _AptitudeScreenState();
}

class _AptitudeScreenState extends ConsumerState<AptitudeScreen> {
  // Filter States
  String _selectedCategory = 'All';
  String _selectedYear = 'All';
  String _selectedCompany = 'All';
  String _selectedDifficulty = 'All';
  bool _enableTimer = true;

  bool _isTestStarted = false;
  bool _isReviewingMode = false;

  final List<String> _companies = [
    'All',
    'TCS',
    'Infosys',
    'Accenture',
    'Wipro',
    'Cognizant',
    'Tech Mahindra',
    'Capgemini',
    'HCL',
    'IBM',
    'Deloitte',
  ];

  final List<String> _years = ['All', '2024', '2023', '2022', '2021'];

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(aptitudeQuestionsProvider);
    final testState = ref.watch(aptitudeTestControllerProvider);
    final testNotifier = ref.read(aptitudeTestControllerProvider.notifier);

    return Scaffold(
      backgroundColor: context.appRootBg,
      appBar: AppBar(
        title: Text(
          'Aptitude Practice (PYQs)',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        leading: _isTestStarted
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isTestStarted = false;
                    _isReviewingMode = false;
                  });
                },
              )
            : null,
      ),
      body: questionsAsync.when(
        data: (allQuestions) {
          if (allQuestions.isEmpty) {
            return _buildEmptyState(context);
          }

          // If test hasn't started yet, show Filter & Setup Screen
          if (!_isTestStarted) {
            return _buildSetupScreen(context, allQuestions, testNotifier);
          }

          // If test completed, show Results Screen
          if (testState.isCompleted && !_isReviewingMode) {
            return _buildResultsScreen(context, testState, testNotifier);
          }

          // Otherwise show Question Flow or Review Mode
          return _buildQuestionFlowScreen(context, testState, testNotifier);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Error loading aptitude questions: $err',
              style: GoogleFonts.inter(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  // --- SETUP / FILTER SCREEN ---
  Widget _buildSetupScreen(
    BuildContext context,
    List<AptitudeProblemModel> allQuestions,
    AptitudeTestNotifier testNotifier,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = allQuestions.where((q) {
      final matchesCat =
          _selectedCategory == 'All' ||
          q.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesYr =
          _selectedYear == 'All' || q.year.toString() == _selectedYear;
      final matchesComp =
          _selectedCompany == 'All' ||
          q.company.toLowerCase() == _selectedCompany.toLowerCase();
      final matchesDiff =
          _selectedDifficulty == 'All' ||
          q.difficulty.toLowerCase() == _selectedDifficulty.toLowerCase();
      return matchesCat && matchesYr && matchesComp && matchesDiff;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxCardWidthSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aptitude Practice',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Practice Previous Year Questions (PYQs) asked in top IT, product, and tech companies',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.appTextSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Filter Controls Card
              AppCard(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Configure Practice Test',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.appTextPrimary,
                          ),
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
                          ),
                          child: Text(
                            '${filtered.length} PYQs available',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.accent
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: context.appBorder),
                    const SizedBox(height: 16),

                    // Category Chips
                    Text(
                      'Category',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['All', 'Quantitative', 'Logical', 'Verbal']
                          .map((cat) {
                            final isSel = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(
                                cat,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSel
                                      ? (isDark
                                            ? Colors.white
                                            : AppColors.primary)
                                      : context.appTextSecondary,
                                ),
                              ),
                              selected: isSel,
                              selectedColor: AppColors.primary.withValues(
                                alpha: isDark ? 0.25 : 0.15,
                              ),
                              backgroundColor: context.appSurfaceAlt,
                              side: BorderSide(
                                color: isSel
                                    ? AppColors.primary
                                    : context.appBorder,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              onSelected: (sel) {
                                if (sel)
                                  setState(() => _selectedCategory = cat);
                              },
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: 18),

                    // Year & Company Dropdowns
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Exam Year',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: context.appTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedYear,
                                dropdownColor: context.appSurface,
                                style: GoogleFonts.inter(
                                  color: context.appTextPrimary,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: context.appBorder,
                                    ),
                                  ),
                                ),
                                items: _years
                                    .map(
                                      (y) => DropdownMenuItem(
                                        value: y,
                                        child: Text(y),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => setState(
                                  () => _selectedYear = val ?? 'All',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Company',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: context.appTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedCompany,
                                dropdownColor: context.appSurface,
                                style: GoogleFonts.inter(
                                  color: context.appTextPrimary,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: context.appBorder,
                                    ),
                                  ),
                                ),
                                items: _companies
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => setState(
                                  () => _selectedCompany = val ?? 'All',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Difficulty Chips
                    Text(
                      'Difficulty',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['All', 'Easy', 'Medium', 'Hard'].map((diff) {
                        final isSel = _selectedDifficulty == diff;
                        return ChoiceChip(
                          label: Text(
                            diff,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSel
                                  ? (isDark ? Colors.white : AppColors.primary)
                                  : context.appTextSecondary,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.primary.withValues(
                            alpha: isDark ? 0.25 : 0.15,
                          ),
                          backgroundColor: context.appSurfaceAlt,
                          side: BorderSide(
                            color: isSel
                                ? AppColors.primary
                                : context.appBorder,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onSelected: (sel) {
                            if (sel) setState(() => _selectedDifficulty = diff);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Timer Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Timed Exam Mode',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                            Text(
                              '60 seconds per question timed assessment',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: context.appTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _enableTimer,
                          onChanged: (val) =>
                              setState(() => _enableTimer = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Start Test Button
                    SizedBox(
                      width: double.infinity,
                      height: AppBreakpoints.minTouchTarget,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: filtered.isEmpty
                            ? null
                            : () {
                                testNotifier.startTest(
                                  filteredQuestions: filtered,
                                  enableTimer: _enableTimer,
                                );
                                setState(() {
                                  _isTestStarted = true;
                                  _isReviewingMode = false;
                                });
                              },
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: Text(
                          'Start Practice Test (${filtered.length} Questions)',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- QUESTION FLOW VIEW ---
  Widget _buildQuestionFlowScreen(
    BuildContext context,
    AptitudeTestState testState,
    AptitudeTestNotifier testNotifier,
  ) {
    if (testState.questions.isEmpty) return const SizedBox();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentQ = testState.questions[testState.currentIndex];
    final progress = (testState.currentIndex + 1) / testState.questions.length;
    final hasAnswered = testState.answeredState[testState.currentIndex] == true;
    final selectedIdx = testState.userAnswers[testState.currentIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxCardWidthSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar & Counts
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: context.appSurfaceAlt,
                  color: AppColors.primary,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${testState.currentIndex + 1} of ${testState.questions.length}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.2 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Score: ${testState.score}',
                      style: GoogleFonts.inter(
                        color: isDark ? AppColors.accent : AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Question Card
              AppCard(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges Header
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        AppBadge(
                          label: currentQ.category.toUpperCase(),
                          variant: AppBadgeVariant.primary,
                        ),
                        AppBadge(
                          label: currentQ.company,
                          variant: AppBadgeVariant.secondary,
                        ),
                        AppBadge(
                          label: '${currentQ.year}',
                          variant: AppBadgeVariant.neutral,
                          isOutline: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Question Text
                    Text(
                      currentQ.questionText,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // 4 Option Cards (A, B, C, D)
                    ...List.generate(currentQ.options.length, (idx) {
                      final optionText = currentQ.options[idx];
                      final isSelected = selectedIdx == idx;
                      final isCorrect = idx == currentQ.correctOptionIndex;

                      Color cardBg = context.appSurface;
                      Color borderColor = context.appBorder;

                      if (hasAnswered || _isReviewingMode) {
                        if (isCorrect) {
                          cardBg = AppColors.success.withValues(alpha: 0.12);
                          borderColor = AppColors.success;
                        } else if (isSelected) {
                          cardBg = AppColors.error.withValues(alpha: 0.12);
                          borderColor = AppColors.error;
                        }
                      } else if (isSelected) {
                        cardBg = AppColors.primary.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        );
                        borderColor = AppColors.primary;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: (hasAnswered && !_isReviewingMode)
                              ? null
                              : () => testNotifier.selectOption(idx),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : context.appSurfaceAlt,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? null
                                        : Border.all(color: context.appBorder),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + idx),
                                      style: GoogleFonts.inter(
                                        color: isSelected
                                            ? Colors.white
                                            : context.appTextSecondary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    optionText,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: context.appTextPrimary,
                                    ),
                                  ),
                                ),
                                if ((hasAnswered || _isReviewingMode) &&
                                    isCorrect)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    size: 20,
                                  ),
                                if ((hasAnswered || _isReviewingMode) &&
                                    isSelected &&
                                    !isCorrect)
                                  const Icon(
                                    Icons.cancel_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Explanation Box (Visible after answering or in review mode)
              if (hasAnswered || _isReviewingMode) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1B1B27)
                        : const Color(0xFFF0EFF8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Solution & Explanation',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.accent
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentQ.explanation.isNotEmpty
                            ? currentQ.explanation
                            : 'The correct option is ${String.fromCharCode(65 + currentQ.correctOptionIndex)}.',
                        style: GoogleFonts.inter(
                          height: 1.5,
                          fontSize: 13,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Next Question / Finish Button
              SizedBox(
                width: double.infinity,
                height: AppBreakpoints.minTouchTarget,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: (!hasAnswered && !_isReviewingMode)
                      ? null
                      : () => testNotifier.nextQuestion(),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    testState.currentIndex == testState.questions.length - 1
                        ? 'Finish & View Results'
                        : 'Next Question',
                    style: GoogleFonts.inter(
                      fontSize: 14,
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

  // --- RESULTS SCREEN ---
  Widget _buildResultsScreen(
    BuildContext context,
    AptitudeTestState testState,
    AptitudeTestNotifier testNotifier,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = testState.questions.length;
    final correct = testState.score;
    final wrong = total - correct;
    final accuracy = total > 0 ? ((correct / total) * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxCardWidthSmall,
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 34,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Test Completed!',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Great job! Here is your aptitude performance assessment breakdown',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: context.appTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),

                    // Large Accuracy Badge
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$accuracy%',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.accent
                                  : AppColors.primary,
                            ),
                          ),
                          Text(
                            'Accuracy',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Score Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricBox(
                          context,
                          'Total',
                          '$total',
                          context.appTextSecondary,
                        ),
                        _buildMetricBox(
                          context,
                          'Correct',
                          '$correct',
                          AppColors.success,
                        ),
                        _buildMetricBox(
                          context,
                          'Wrong',
                          '$wrong',
                          AppColors.error,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Divider(color: context.appBorder),
                    const SizedBox(height: 16),

                    // Category Breakdown Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Category Breakdown',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._buildCategoryBreakdownList(context, testState),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        setState(() => _isReviewingMode = true);
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Review Answers'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        setState(() => _isTestStarted = false);
                      },
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: const Text('Retake Test'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => context.go('/practice'),
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: const Text('Back to Practice Hub'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryBreakdownList(
    BuildContext context,
    AptitudeTestState testState,
  ) {
    final Map<String, int> totalPerCat = {};
    final Map<String, int> correctPerCat = {};

    for (int i = 0; i < testState.questions.length; i++) {
      final q = testState.questions[i];
      final cat = q.category;
      totalPerCat[cat] = (totalPerCat[cat] ?? 0) + 1;
      if (testState.userAnswers[i] == q.correctOptionIndex) {
        correctPerCat[cat] = (correctPerCat[cat] ?? 0) + 1;
      }
    }

    return totalPerCat.entries.map((entry) {
      final cat = entry.key;
      final total = entry.value;
      final correct = correctPerCat[cat] ?? 0;
      final perc = (correct / total);

      return Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                cat.toUpperCase(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: context.appTextPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: perc,
                  backgroundColor: context.appSurfaceAlt,
                  color: AppColors.success,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '$correct/$total',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: context.appTextPrimary,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildMetricBox(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: context.appTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return AppEmptyState(
      icon: Icons.quiz_outlined,
      title: 'No aptitude questions available',
      message:
          'Run the seed script or use the Admin Question Importer to load previous year placement questions.',
      actionLabel: 'Go to Admin Importer',
      onAction: () => context.go('/admin/importer'),
    );
  }
}
