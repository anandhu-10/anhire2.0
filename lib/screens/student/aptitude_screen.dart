import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/aptitude_problem_model.dart';
import '../../providers/aptitude_provider.dart';

class AptitudeScreen extends ConsumerStatefulWidget {
  const AptitudeScreen({Key? key}) : super(key: key);

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
    final theme = Theme.of(context);
    final questionsAsync = ref.watch(aptitudeQuestionsProvider);
    final testState = ref.watch(aptitudeTestControllerProvider);
    final testNotifier = ref.read(aptitudeTestControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aptitude Practice (PYQs)'),
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
            return _buildEmptyState(theme);
          }

          // If test hasn't started yet, show Filter & Setup Screen
          if (!_isTestStarted) {
            return _buildSetupScreen(context, theme, allQuestions, testNotifier);
          }

          // If test completed, show Results Screen
          if (testState.isCompleted && !_isReviewingMode) {
            return _buildResultsScreen(context, theme, testState, testNotifier);
          }

          // Otherwise show Question Flow or Review Mode
          return _buildQuestionFlowScreen(context, theme, testState, testNotifier);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading aptitude questions: $err')),
      ),
    );
  }

  // --- SETUP / FILTER SCREEN ---
  Widget _buildSetupScreen(
    BuildContext context,
    ThemeData theme,
    List<AptitudeProblemModel> allQuestions,
    AptitudeTestNotifier testNotifier,
  ) {
    final filtered = allQuestions.where((q) {
      final matchesCat = _selectedCategory == 'All' ||
          q.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesYr = _selectedYear == 'All' || q.year.toString() == _selectedYear;
      final matchesComp = _selectedCompany == 'All' ||
          q.company.toLowerCase() == _selectedCompany.toLowerCase();
      final matchesDiff = _selectedDifficulty == 'All' ||
          q.difficulty.toLowerCase() == _selectedDifficulty.toLowerCase();
      return matchesCat && matchesYr && matchesComp && matchesDiff;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxCardWidthSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Aptitude Practice', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(
                'Practice Previous Year Questions (PYQs) asked in top IT & tech companies',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Filter Controls Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Configure Practice Test', style: theme.textTheme.titleMedium),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Category Chips
                      Text('Category', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Quantitative', 'Logical', 'Verbal'].map((cat) {
                          final isSel = _selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(
                              cat,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: const Color(0xFF6750A4),
                            backgroundColor: const Color(0xFF2B2930),
                            side: BorderSide(
                              color: isSel ? const Color(0xFF6750A4) : const Color(0xFF3A383F),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (sel) {
                              if (sel) setState(() => _selectedCategory = cat);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Year & Company Dropdowns
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Year', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _selectedYear,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                                  onChanged: (val) => setState(() => _selectedYear = val ?? 'All'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Company', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _selectedCompany,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: _companies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (val) => setState(() => _selectedCompany = val ?? 'All'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Difficulty Chips
                      Text('Difficulty', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Easy', 'Medium', 'Hard'].map((diff) {
                          final isSel = _selectedDifficulty == diff;
                          return ChoiceChip(
                            label: Text(
                              diff,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: const Color(0xFF6750A4),
                            backgroundColor: const Color(0xFF2B2930),
                            side: BorderSide(
                              color: isSel ? const Color(0xFF6750A4) : const Color(0xFF3A383F),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (sel) {
                              if (sel) setState(() => _selectedDifficulty = diff);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Timer Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Enable 30-min Timer', style: TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Switch(
                            value: _enableTimer,
                            onChanged: (val) => setState(() => _enableTimer = val),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Start Test Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
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
                  icon: const Icon(Icons.play_arrow),
                  label: Text('Start Test (${filtered.length} Questions)'),
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
    ThemeData theme,
    AptitudeTestState testState,
    AptitudeTestNotifier testNotifier,
  ) {
    if (testState.questions.isEmpty) return const SizedBox();
    final currentQ = testState.questions[testState.currentIndex];
    final progress = (testState.currentIndex + 1) / testState.questions.length;
    final hasAnswered = testState.answeredState[testState.currentIndex] == true;
    final selectedIdx = testState.userAnswers[testState.currentIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxCardWidthSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar & Counts
              LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.primaryContainer,
                color: theme.colorScheme.primary,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${testState.currentIndex + 1} of ${testState.questions.length}',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Score: ${testState.score}',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Question Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges Header
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(
                            label: Text(currentQ.category.toUpperCase()),
                            backgroundColor: theme.colorScheme.primaryContainer,
                            labelStyle: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          Chip(
                            label: Text(currentQ.company),
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            labelStyle: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          Chip(
                            label: Text('${currentQ.year}'),
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            labelStyle: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Question Text
                      Text(
                        currentQ.questionText,
                        style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, height: 1.4),
                      ),
                      const SizedBox(height: 20),

                      // 4 Option Cards (A, B, C, D)
                      ...List.generate(currentQ.options.length, (idx) {
                        final optionText = currentQ.options[idx];
                        final isSelected = selectedIdx == idx;
                        final isCorrect = idx == currentQ.correctOptionIndex;

                        Color cardBg = theme.colorScheme.surface;
                        Color borderColor = Colors.grey[300]!;

                        if (hasAnswered || _isReviewingMode) {
                          if (isCorrect) {
                            cardBg = Colors.green.withOpacity(0.12);
                            borderColor = Colors.green;
                          } else if (isSelected) {
                            cardBg = Colors.red.withOpacity(0.12);
                            borderColor = Colors.red;
                          }
                        } else if (isSelected) {
                          cardBg = theme.colorScheme.primaryContainer;
                          borderColor = theme.colorScheme.primary;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: InkWell(
                            onTap: (hasAnswered && !_isReviewingMode) ? null : () => testNotifier.selectOption(idx),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isSelected ? const Color(0xFF6750A4) : const Color(0xFF3A383F),
                                    child: Text(
                                      String.fromCharCode(65 + idx),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      optionText,
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.white),
                                    ),
                                  ),
                                  if ((hasAnswered || _isReviewingMode) && isCorrect)
                                    const Icon(Icons.check_circle, color: Colors.green),
                                  if ((hasAnswered || _isReviewingMode) && isSelected && !isCorrect)
                                    const Icon(Icons.cancel, color: Colors.red),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Explanation Box (Visible after answering or in review mode)
              if (hasAnswered || _isReviewingMode) ...[
                const SizedBox(height: 16),
                Card(
                  color: AppColors.bgLavender,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Color(0xFF6750A4)),
                            SizedBox(width: 8),
                            Text('Explanation', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6750A4))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentQ.explanation.isNotEmpty
                              ? currentQ.explanation
                              : 'Correct option is ${String.fromCharCode(65 + currentQ.correctOptionIndex)}.',
                          style: const TextStyle(height: 1.4, fontSize: 14, color: AppColors.textOnLavender),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Next Question / Finish Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: (!hasAnswered && !_isReviewingMode)
                      ? null
                      : () => testNotifier.nextQuestion(),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    testState.currentIndex == testState.questions.length - 1
                        ? 'Finish & View Results'
                        : 'Next Question',
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
    ThemeData theme,
    AptitudeTestState testState,
    AptitudeTestNotifier testNotifier,
  ) {
    final total = testState.questions.length;
    final correct = testState.score;
    final wrong = total - correct;
    final accuracy = total > 0 ? ((correct / total) * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxCardWidthSmall),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events_outlined, size: 64, color: Colors.amber),
                      const SizedBox(height: 12),
                      Text('Test Completed!', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 16),

                      // Large Accuracy Badge
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$accuracy%',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Text('Accuracy', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Score Metrics Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricBox('Total', '$total', Colors.grey),
                          _buildMetricBox('Correct', '$correct', Colors.green),
                          _buildMetricBox('Wrong', '$wrong', Colors.red),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Category Breakdown Section
                      Text('Category Breakdown', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ..._buildCategoryBreakdownList(testState),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _isReviewingMode = true);
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Review Answers'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _isTestStarted = false);
                      },
                      icon: const Icon(Icons.replay),
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
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Practice Hub'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryBreakdownList(AptitudeTestState testState) {
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
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                cat.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 3,
              child: LinearProgressIndicator(
                value: perc,
                backgroundColor: Colors.grey[200],
                color: Colors.green,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Text('$correct/$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildMetricBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('No aptitude questions found in Firestore', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Run seed script or use Admin Importer to load questions.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
