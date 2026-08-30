import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/coding_problem_model.dart';
import '../../providers/coding_provider.dart';

class CodingPlaygroundScreen extends ConsumerStatefulWidget {
  final String problemId;

  const CodingPlaygroundScreen({
    super.key,
    required this.problemId,
  });

  @override
  ConsumerState<CodingPlaygroundScreen> createState() => _CodingPlaygroundScreenState();
}

class _CodingPlaygroundScreenState extends ConsumerState<CodingPlaygroundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mobileTabController;
  late TextEditingController _codeController;
  String _selectedLanguage = 'python';
  double _fontSize = 14.0;
  bool _isConsoleCollapsed = false;

  CodingProblemModel? _loadedProblem;

  @override
  void initState() {
    super.initState();
    _mobileTabController = TabController(length: 3, vsync: this);
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _mobileTabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _initializeCode(CodingProblemModel problem) {
    if (_loadedProblem?.id != problem.id) {
      _loadedProblem = problem;
      final starter = problem.starterCode[_selectedLanguage] ??
          problem.starterCode['python'] ??
          '# Write code here';
      _codeController.text = starter;
    }
  }

  void _onLanguageChanged(String? newLang, CodingProblemModel problem) {
    if (newLang == null || newLang == _selectedLanguage) return;
    setState(() {
      _selectedLanguage = newLang;
      _codeController.text = problem.starterCode[newLang] ?? '# Write code here';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < AppBreakpoints.compactBreakpoint;
    final isTablet = width >= AppBreakpoints.compactBreakpoint && width < 1024;
    final isDesktop = width >= 1024;

    final problemsAsync = ref.watch(codingProblemsProvider);
    final execState = ref.watch(executionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_loadedProblem?.title ?? 'Coding Playground'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Reset Starter Code',
            onPressed: () {
              if (_loadedProblem != null) {
                setState(() {
                  _codeController.text = _loadedProblem!.starterCode[_selectedLanguage] ?? '';
                });
              }
            },
          ),
        ],
        bottom: isMobile
            ? TabBar(
                controller: _mobileTabController,
                tabs: const [
                  Tab(icon: Icon(Icons.description_outlined), text: 'Problem'),
                  Tab(icon: Icon(Icons.code), text: 'Editor'),
                  Tab(icon: Icon(Icons.terminal), text: 'Console'),
                ],
              )
            : null,
      ),
      body: problemsAsync.when(
        data: (problems) {
          final problem = problems.firstWhere(
            (p) => p.id == widget.problemId,
            orElse: () => problems.isNotEmpty ? problems.first : _fallbackProblem(),
          );
          _initializeCode(problem);

          if (isMobile) {
            return TabBarView(
              controller: _mobileTabController,
              children: [
                _buildProblemPane(context, problem),
                _buildEditorPane(context, problem, execState),
                _buildConsolePane(context, execState),
              ],
            );
          }

          // Tablet / Desktop Split View Layout
          final leftFlex = isTablet ? 40 : 35;
          final rightFlex = isTablet ? 60 : 65;

          return Row(
            children: [
              // Left Pane: Problem Description (Scrollable)
              Expanded(
                flex: leftFlex,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: theme.dividerColor)),
                  ),
                  child: _buildProblemPane(context, problem),
                ),
              ),

              // Right Pane: Code Editor + Console
              Expanded(
                flex: rightFlex,
                child: Column(
                  children: [
                    // Code Editor Section
                    Expanded(
                      flex: _isConsoleCollapsed ? 100 : (isDesktop ? 70 : 60),
                      child: _buildEditorPane(context, problem, execState),
                    ),

                    // Collapsible Terminal Console
                    if (!_isConsoleCollapsed)
                      Expanded(
                        flex: isDesktop ? 30 : 40,
                        child: _buildConsolePane(context, execState),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading problem: $err')),
      ),
    );
  }

  // --- LEFT PANE: PROBLEM DESCRIPTION ---
  Widget _buildProblemPane(BuildContext context, CodingProblemModel problem) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  problem.title,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _buildDifficultyBadge(problem.difficulty),
            ],
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(problem.category.toUpperCase()),
            backgroundColor: theme.colorScheme.primaryContainer,
            labelStyle: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Problem Description
          Text('Description', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            problem.description,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 20),

          // Constraints
          if (problem.constraints.isNotEmpty) ...[
            Text('Constraints', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...problem.constraints.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          c,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
          ],

          // Sample Input / Output
          Text('Sample Input & Output', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildCodeBlock(title: 'Sample Input', content: problem.sampleInput),
          const SizedBox(height: 12),
          _buildCodeBlock(title: 'Sample Output', content: problem.sampleOutput),
        ],
      ),
    );
  }

  Widget _buildCodeBlock({required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          SelectableText(
            content,
            style: const TextStyle(color: Color(0xFFCE9178), fontFamily: 'monospace', fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --- RIGHT PANE: EDITOR ---
  Widget _buildEditorPane(BuildContext context, CodingProblemModel problem, ExecutionState execState) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Editor Controls Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
          child: Row(
            children: [
              // Language Selector Dropdown
              DropdownButton<String>(
                value: _selectedLanguage,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'python', child: Text('Python 3.10')),
                  DropdownMenuItem(value: 'java', child: Text('Java 15')),
                ],
                onChanged: (val) => _onLanguageChanged(val, problem),
              ),

              const Spacer(),

              // Font Size Controls
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                tooltip: 'Decrease font size',
                onPressed: () {
                  if (_fontSize > 12) setState(() => _fontSize -= 1);
                },
              ),
              Text('${_fontSize.toInt()}pt', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                tooltip: 'Increase font size',
                onPressed: () {
                  if (_fontSize < 24) setState(() => _fontSize += 1);
                },
              ),

              const SizedBox(width: 8),

              // Run Code Button (Purple)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6750A4),
                  foregroundColor: Colors.white,
                ),
                onPressed: execState.isExecuting
                    ? null
                    : () {
                        ref.read(executionProvider.notifier).runCode(
                              problem: problem,
                              language: _selectedLanguage,
                              code: _codeController.text,
                            );
                        if (MediaQuery.of(context).size.width < AppBreakpoints.compactBreakpoint) {
                          _mobileTabController.animateTo(2); // Switch to console tab on mobile
                        }
                      },
                icon: execState.isExecuting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow, size: 18),
                label: const Text('Run Code'),
              ),

              const SizedBox(width: 8),

              // Submit Button (Green outline)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  side: BorderSide(color: Colors.green[700]!),
                ),
                onPressed: execState.isExecuting
                    ? null
                    : () {
                        ref.read(executionProvider.notifier).submitCode(
                              problem: problem,
                              language: _selectedLanguage,
                              code: _codeController.text,
                            );
                        if (MediaQuery.of(context).size.width < AppBreakpoints.compactBreakpoint) {
                          _mobileTabController.animateTo(2); // Switch to console tab on mobile
                        }
                      },
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('Submit'),
              ),
            ],
          ),
        ),

        // Code Editor Box
        Expanded(
          child: Container(
            color: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _codeController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: _fontSize,
                color: const Color(0xFFD4D4D4),
                height: 1.4,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '// Write your solution here...',
                hintStyle: TextStyle(color: Colors.grey, fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- BOTTOM CONSOLE: TERMINAL & RESULTS ---
  Widget _buildConsolePane(BuildContext context, ExecutionState execState) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF141414),
      child: Column(
        children: [
          // Console Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF252526),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'CONSOLE / OUTPUT',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isConsoleCollapsed ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _isConsoleCollapsed = !_isConsoleCollapsed),
                ),
              ],
            ),
          ),

          // Console Output Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (execState.logs != null) ...[
                    Text(
                      execState.logs!,
                      style: const TextStyle(color: Color(0xFF4EC9B0), fontFamily: 'monospace', fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Test Case Results Cards
                  if (execState.testResults != null) ...[
                    ...execState.testResults!.map((res) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          border: Border.all(
                            color: res.passed ? Colors.green : Colors.red,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  res.passed ? Icons.check_circle : Icons.cancel,
                                  color: res.passed ? Colors.green : Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Test Case #${res.testIndex}: ${res.passed ? "PASSED" : "FAILED"}',
                                  style: TextStyle(
                                    color: res.passed ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (res.stdout.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Stdout: ${res.stdout}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace')),
                            ],
                            if (res.stderr.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Stderr: ${res.stderr}', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontFamily: 'monospace')),
                            ],
                            if (res.expected != null && res.actual != null && !res.passed) ...[
                              const SizedBox(height: 4),
                              Text('Expected: ${res.expected}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace')),
                              Text('Actual:   ${res.actual}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontFamily: 'monospace')),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],

                  // Gemini AI Feedback Highlighted Box
                  if (execState.aiHint != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1B4E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF9C27B0), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'AI Feedback & Hint',
                                style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            execState.aiHint!,
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color = Colors.green;
    final dLower = difficulty.toLowerCase();
    if (dLower == 'medium') color = Colors.orange;
    if (dLower == 'hard') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  CodingProblemModel _fallbackProblem() {
    return CodingProblemModel(
      id: 'cp_001',
      title: 'Two Sum',
      difficulty: 'easy',
      category: 'arrays',
      description: 'Given an array of integers nums and an integer target, return indices of the two numbers such that they add up to target.',
      constraints: ['2 <= nums.length <= 10^4'],
      sampleInput: '[2, 7, 11, 15]\n9',
      sampleOutput: '[0, 1]',
      testCases: [TestCase(input: '[2, 7, 11, 15]\n9', output: '[0, 1]')],
      starterCode: {
        'python': 'def two_sum(nums, target):\n    # Write code here\n    pass',
        'java': 'public class Solution {\n    public int[] twoSum(int[] nums, int target) {\n        return new int[]{};\n    }\n}'
      },
      timeLimit: 5,
      memoryLimit: 256,
    );
  }
}
