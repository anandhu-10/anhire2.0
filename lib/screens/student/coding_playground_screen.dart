import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/java.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/coding_problem_model.dart';
import '../../models/coding_submission_model.dart';
import '../../providers/coding_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/celebration_dialog.dart';

class CodingPlaygroundScreen extends ConsumerStatefulWidget {
  final String problemId;

  const CodingPlaygroundScreen({super.key, required this.problemId});

  @override
  ConsumerState<CodingPlaygroundScreen> createState() =>
      _CodingPlaygroundScreenState();
}

class _CodingPlaygroundScreenState extends ConsumerState<CodingPlaygroundScreen>
    with TickerProviderStateMixin {
  late TabController _mobileTabController;
  late TabController _consoleTabController;

  late CodeController _codeController;
  final TextEditingController _customInputController = TextEditingController();

  String _selectedLanguage = 'python';
  double _fontSize = 14.0;

  // Split-pane ratio (Desktop): Left flex 40, Right flex 60
  bool _isConsoleExpanded = false;
  bool _isConsoleCollapsed = false;

  int _selectedTestCaseIndex = 0;

  // Draft persistence per language so switching language does not lose edits
  final Map<String, String> _languageDrafts = {};

  CodingProblemModel? _loadedProblem;

  @override
  void initState() {
    super.initState();
    _mobileTabController = TabController(length: 3, vsync: this);
    _consoleTabController = TabController(length: 4, vsync: this);

    _codeController = CodeController(
      text: '# Loading starter code...',
      language: python,
    );
  }

  @override
  void dispose() {
    _mobileTabController.dispose();
    _consoleTabController.dispose();
    _codeController.dispose();
    _customInputController.dispose();
    super.dispose();
  }

  void _initializeCode(CodingProblemModel problem) {
    if (_loadedProblem?.id != problem.id) {
      _loadedProblem = problem;
      _languageDrafts.clear();

      final settings = ref.read(settingsProvider);
      if (settings.preferredLanguage == 'python' ||
          settings.preferredLanguage == 'java') {
        _selectedLanguage = settings.preferredLanguage;
      }
      _fontSize = settings.editorFontSize;

      final pythonStarter =
          problem.starterCode['python'] ??
          'def solution():\n    # Write your solution here\n    pass';
      final javaStarter =
          problem.starterCode['java'] ??
          'public class Solution {\n    // Write your solution here\n}';

      _languageDrafts['python'] = pythonStarter;
      _languageDrafts['java'] = javaStarter;

      final initialDraft = _languageDrafts[_selectedLanguage] ?? pythonStarter;
      _codeController.language = _selectedLanguage == 'python' ? python : java;
      _codeController.text = initialDraft;

      _selectedTestCaseIndex = 0;
      ref.read(executionProvider.notifier).clearResults();
    }
  }

  void _onLanguageChanged(String? newLang, CodingProblemModel problem) {
    if (newLang == null || newLang == _selectedLanguage) return;

    // Save current language draft
    _languageDrafts[_selectedLanguage] = _codeController.text;

    setState(() {
      _selectedLanguage = newLang;
      _codeController.language = newLang == 'python' ? python : java;

      final draft =
          _languageDrafts[newLang] ??
          problem.starterCode[newLang] ??
          (newLang == 'python' ? '# Write code here' : '// Write code here');
      _codeController.text = draft;
    });
  }

  void _confirmResetCode(CodingProblemModel problem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: const Row(
          children: [
            Icon(Icons.refresh, color: AppColors.warning),
            SizedBox(width: 8),
            Text(
              'Reset to Starter Code?',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'All your current edits in ${_selectedLanguage.toUpperCase()} will be replaced with the default starter template. This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPurple,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final starter = problem.starterCode[_selectedLanguage] ?? '';
              setState(() {
                _codeController.text = starter;
                _languageDrafts[_selectedLanguage] = starter;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Starter code reset successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Reset Code',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _copyCodeToClipboard() {
    Clipboard.setData(ClipboardData(text: _codeController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleRunCode(CodingProblemModel problem) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write some code before running!')),
      );
      return;
    }

    _languageDrafts[_selectedLanguage] = _codeController.text;

    // Switch to Test Results tab
    _consoleTabController.animateTo(0);
    if (_isConsoleCollapsed) {
      setState(() => _isConsoleCollapsed = false);
    }
    if (MediaQuery.of(context).size.width < AppBreakpoints.compactBreakpoint) {
      _mobileTabController.animateTo(2);
    }

    await ref
        .read(executionProvider.notifier)
        .runCode(
          problem: problem,
          language: _selectedLanguage,
          code: _codeController.text,
        );
  }

  void _handleSubmitCode(CodingProblemModel problem) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write some code before submitting!'),
        ),
      );
      return;
    }

    _languageDrafts[_selectedLanguage] = _codeController.text;

    // Switch to Test Results tab
    _consoleTabController.animateTo(0);
    if (_isConsoleCollapsed) {
      setState(() => _isConsoleCollapsed = false);
    }
    if (MediaQuery.of(context).size.width < AppBreakpoints.compactBreakpoint) {
      _mobileTabController.animateTo(2);
    }

    await ref
        .read(executionProvider.notifier)
        .submitCode(
          problem: problem,
          language: _selectedLanguage,
          code: _codeController.text,
        );

    final execState = ref.read(executionProvider);

    if (mounted && execState.isSubmitted == true) {
      if (execState.allPassed == true) {
        if (execState.isFirstTimeSolve) {
          final newlyUnlocked = await ref
              .read(gamificationControllerProvider.notifier)
              .syncPointsAndCheckBadges();

          if (mounted) {
            if (newlyUnlocked.isNotEmpty) {
              CelebrationDialog.show(context, newlyUnlocked.first);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green[800],
                  content: Text(
                    '🎉 First-Time Solve! +${execState.pointsEarned} Points Added to your Profile!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                '✓ Solution Accepted! (Problem already solved previously)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[800],
            content: Text(
              'Verdict: ${execState.overallVerdict ?? "Failed"} - Check console results.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleRunCustomInput(CodingProblemModel problem) async {
    final code = _codeController.text.trim();
    final customStdin = _customInputController.text;

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write code before running!')),
      );
      return;
    }

    _consoleTabController.animateTo(1);
    if (_isConsoleCollapsed) {
      setState(() => _isConsoleCollapsed = false);
    }

    await ref
        .read(executionProvider.notifier)
        .runCustomInput(
          problem: problem,
          language: _selectedLanguage,
          code: _codeController.text,
          customStdin: customStdin,
        );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < AppBreakpoints.compactBreakpoint;
    final isTablet = width >= AppBreakpoints.compactBreakpoint && width < 1024;
    final isDesktop = width >= 1024;

    final problemsAsync = ref.watch(codingProblemsProvider);
    final execState = ref.watch(executionProvider);

    return Scaffold(
      backgroundColor: context.appRootBg,
      appBar: AppBar(
        backgroundColor: context.appSidebarBg,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: context.appTextPrimary),
              tooltip: 'Back to Problems Catalogue',
              onPressed: () => context.go('/coding-problems'),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _loadedProblem?.title ?? 'Coding Playground',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Solved Status Indicator Chip in AppBar
          if (_loadedProblem != null)
            Consumer(
              builder: (context, ref, _) {
                final status = ref.watch(
                  problemStatusProvider(_loadedProblem!.id),
                );
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _buildSolvedStatusBadge(status),
                );
              },
            ),

          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Starter Code',
            onPressed: _loadedProblem == null
                ? null
                : () => _confirmResetCode(_loadedProblem!),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Code',
            onPressed: _copyCodeToClipboard,
          ),
          const SizedBox(width: 8),
        ],
        bottom: isMobile
            ? TabBar(
                controller: _mobileTabController,
                indicatorColor: AppColors.accentPurpleLight,
                labelColor: AppColors.accentPurpleLight,
                unselectedLabelColor: AppColors.textMuted,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.description_outlined, size: 18),
                    text: 'Problem',
                  ),
                  Tab(icon: Icon(Icons.code, size: 18), text: 'Editor'),
                  Tab(icon: Icon(Icons.terminal, size: 18), text: 'Console'),
                ],
              )
            : null,
      ),
      body: problemsAsync.when(
        data: (problems) {
          final problem = problems.firstWhere(
            (p) => p.id == widget.problemId,
            orElse: () =>
                problems.isNotEmpty ? problems.first : _fallbackProblem(),
          );
          _initializeCode(problem);

          if (isMobile) {
            return TabBarView(
              controller: _mobileTabController,
              children: [
                _buildProblemPane(context, problem, problems),
                _buildEditorPane(context, problem, execState, isMobile: true),
                _buildConsolePane(context, problem, execState),
              ],
            );
          }

          // Tablet & Desktop Split-Pane Layout
          final leftFlex = isTablet ? 42 : 38;
          final rightFlex = isTablet ? 58 : 62;

          return Row(
            children: [
              // Left Pane: Problem Statement & Navigation
              Expanded(
                flex: leftFlex,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    border: Border(right: BorderSide(color: context.appBorder)),
                  ),
                  child: _buildProblemPane(context, problem, problems),
                ),
              ),

              // Right Pane: Code Editor (Top) & Interactive Console (Bottom)
              Expanded(
                flex: rightFlex,
                child: Column(
                  children: [
                    // Code Editor Section
                    Expanded(
                      flex: _isConsoleCollapsed
                          ? 100
                          : (_isConsoleExpanded ? 35 : (isDesktop ? 60 : 55)),
                      child: _buildEditorPane(
                        context,
                        problem,
                        execState,
                        isMobile: false,
                      ),
                    ),

                    // Collapsible / Expandable Console Section
                    if (!_isConsoleCollapsed)
                      Expanded(
                        flex: _isConsoleExpanded ? 65 : (isDesktop ? 40 : 45),
                        child: _buildConsolePane(context, problem, execState),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentPurple),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Error loading problem: $err',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(codingProblemsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // LEFT PANE: PROBLEM STATEMENT & SPECIFICATIONS
  // ===========================================================================
  Widget _buildProblemPane(
    BuildContext context,
    CodingProblemModel problem,
    List<CodingProblemModel> allProblems,
  ) {
    final currentIndex = allProblems.indexWhere((p) => p.id == problem.id);
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex >= 0 && currentIndex < allProblems.length - 1;

    return Column(
      children: [
        // Top Navigation Bar (Prev / Next problem switcher)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.bgSurfaceAlt,
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              Text(
                'Problem ${currentIndex >= 0 ? currentIndex + 1 : 1} of ${allProblems.length}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                tooltip: hasPrev
                    ? 'Previous Problem (${allProblems[currentIndex - 1].title})'
                    : 'No Previous Problem',
                onPressed: hasPrev
                    ? () => context.go(
                        '/coding-playground/${allProblems[currentIndex - 1].id}',
                      )
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                tooltip: hasNext
                    ? 'Next Problem (${allProblems[currentIndex + 1].title})'
                    : 'No Next Problem',
                onPressed: hasNext
                    ? () => context.go(
                        '/coding-playground/${allProblems[currentIndex + 1].id}',
                      )
                    : null,
              ),
            ],
          ),
        ),

        // Problem Description Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Problem Title & Tags
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        problem.title,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildDifficultyBadge(problem.difficulty),
                  ],
                ),
                const SizedBox(height: 10),

                // Category & Constraints Meta Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accentPurple.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        problem.category.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accentPurpleLight,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Time Limit: ${problem.timeLimit}s',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.memory,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Memory: ${problem.memoryLimit}MB',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.borderSubtle),
                const SizedBox(height: 12),

                // Description Text
                const Text(
                  'Problem Description',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  problem.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.6,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Constraints Section
                if (problem.constraints.isNotEmpty) ...[
                  const Text(
                    'Constraints',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: problem.constraints.map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(
                                  color: AppColors.accentPurpleLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  c,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Sample Input & Output Section
                const Text(
                  'Sample Test Cases',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCodeSnippetBox(
                  title: 'Sample Input',
                  content: problem.sampleInput,
                ),
                const SizedBox(height: 12),
                _buildCodeSnippetBox(
                  title: 'Sample Output',
                  content: problem.sampleOutput,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeSnippetBox({
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.codeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: AppColors.codeHeader,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$title copied!'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.copy, size: 12, color: AppColors.textMuted),
                      SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              content.isEmpty ? '(Empty)' : content,
              style: const TextStyle(
                color: AppColors.codeString,
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RIGHT PANE (TOP): PROFESSIONAL CODE EDITOR
  // ===========================================================================
  Widget _buildEditorPane(
    BuildContext context,
    CodingProblemModel problem,
    ExecutionState execState, {
    required bool isMobile,
  }) {
    return Container(
      color: AppColors.codeBgDark,
      child: Column(
        children: [
          // Editor Toolbar Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: AppColors.bgSurfaceAlt,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Language Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      dropdownColor: AppColors.bgCard,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textSecondary,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'python',
                          child: Row(
                            children: [
                              Icon(
                                Icons.code,
                                size: 16,
                                color: Colors.yellowAccent,
                              ),
                              SizedBox(width: 8),
                              Text('Python 3.10'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'java',
                          child: Row(
                            children: [
                              Icon(
                                Icons.coffee,
                                size: 16,
                                color: Colors.orangeAccent,
                              ),
                              SizedBox(width: 8),
                              Text('Java 15'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) => _onLanguageChanged(val, problem),
                    ),
                  ),
                ),

                // Font Size & Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: 'Decrease Font Size',
                      onPressed: () {
                        if (_fontSize > 12) setState(() => _fontSize -= 1);
                      },
                    ),
                    Text(
                      '${_fontSize.toInt()}pt',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: 'Increase Font Size',
                      onPressed: () {
                        if (_fontSize < 22) setState(() => _fontSize += 1);
                      },
                    ),

                    if (!isMobile) ...[
                      const SizedBox(width: 8),
                      // Collapse / Expand Console View Button
                      IconButton(
                        icon: Icon(
                          _isConsoleExpanded
                              ? Icons.fullscreen_exit
                              : Icons.splitscreen,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        tooltip: _isConsoleExpanded
                            ? 'Restore Console Split'
                            : 'Maximize Console',
                        onPressed: () {
                          setState(() {
                            _isConsoleExpanded = !_isConsoleExpanded;
                            _isConsoleCollapsed = false;
                          });
                        },
                      ),
                    ],

                    const SizedBox(width: 8),

                    // Run Code Button (Purple)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: execState.isExecuting
                          ? null
                          : () => _handleRunCode(problem),
                      icon: execState.isExecuting && !execState.isSubmitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow, size: 18),
                      label: const Text(
                        'Run Code',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Submit Code Button (Green outline / solid)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: execState.isExecuting
                          ? null
                          : () => _handleSubmitCode(problem),
                      icon: execState.isSubmitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text(
                        'Submit',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // CodeField Editor Canvas with Line Numbers & Monospace Font
          Expanded(
            child: CodeTheme(
              data: CodeThemeData(styles: atomOneDarkTheme),
              child: SingleChildScrollView(
                child: CodeField(
                  controller: _codeController,
                  textStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: _fontSize,
                    height: 1.45,
                  ),
                  gutterStyle: GutterStyle(
                    width: 48,
                    textAlign: TextAlign.right,
                    textStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'monospace',
                      fontSize: _fontSize * 0.85,
                    ),
                    background: AppColors.codeBgDark,
                  ),
                  background: AppColors.codeBg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RIGHT PANE (BOTTOM): MULTI-TAB CONSOLE & EXECUTION RESULTS
  // ===========================================================================
  Widget _buildConsolePane(
    BuildContext context,
    CodingProblemModel problem,
    ExecutionState execState,
  ) {
    return Container(
      width: double.infinity,
      color: AppColors.codeBgDark,
      child: Column(
        children: [
          // Console Tab Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.codeHeader,
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _consoleTabController,
                    isScrollable: true,
                    indicatorColor: AppColors.accentPurpleLight,
                    labelColor: AppColors.accentPurpleLight,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.assessment_outlined, size: 14),
                            const SizedBox(width: 6),
                            const Text('Test Results'),
                            if (execState.testResults != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: execState.allPassed == true
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${execState.testResults!.where((r) => r.passed).length}/${execState.testResults!.length}',
                                  style: TextStyle(
                                    color: execState.allPassed == true
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Tab(
                        child: Row(
                          children: [
                            Icon(Icons.input, size: 14),
                            SizedBox(width: 6),
                            Text('Custom Input'),
                          ],
                        ),
                      ),
                      const Tab(
                        child: Row(
                          children: [
                            Icon(Icons.history, size: 14),
                            SizedBox(width: 6),
                            Text('Submissions'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: Colors.purpleAccent,
                            ),
                            const SizedBox(width: 6),
                            const Text('AI Mentor'),
                            if (execState.aiHint != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.purpleAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Collapse Console Toggle
                IconButton(
                  icon: Icon(
                    _isConsoleCollapsed
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  tooltip: _isConsoleCollapsed
                      ? 'Expand Console'
                      : 'Collapse Console',
                  onPressed: () => setState(
                    () => _isConsoleCollapsed = !_isConsoleCollapsed,
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _consoleTabController,
              children: [
                _buildTestResultsTab(context, problem, execState),
                _buildCustomInputTab(context, problem, execState),
                _buildSubmissionsHistoryTab(context, problem),
                _buildAiMentorTab(context, problem, execState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: TEST RESULTS ---
  Widget _buildTestResultsTab(
    BuildContext context,
    CodingProblemModel problem,
    ExecutionState execState,
  ) {
    if (execState.isExecuting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.accentPurple),
            const SizedBox(height: 16),
            Text(
              execState.isSubmitting
                  ? 'Testing solution against all problem test cases...'
                  : 'Running code against sample test cases...',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (execState.testResults == null || execState.testResults!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.terminal_outlined,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'No execution results yet',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Click "Run Code" to test against samples or "Submit" to evaluate all test cases.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final results = execState.testResults!;
    if (_selectedTestCaseIndex >= results.length) {
      _selectedTestCaseIndex = 0;
    }
    final activeResult = results[_selectedTestCaseIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Verdict Banner
          _buildVerdictBanner(execState),
          const SizedBox(height: 16),

          // Test Cases Pill Switcher (Testcase 1, Testcase 2, etc.)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(results.length, (idx) {
                final r = results[idx];
                final isSelected = idx == _selectedTestCaseIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    avatar: Icon(
                      r.passed ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: r.passed ? Colors.green : Colors.red,
                    ),
                    label: Text('Case ${r.testIndex}'),
                    selected: isSelected,
                    selectedColor: AppColors.bgCard,
                    backgroundColor: AppColors.codeBg,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? (r.passed ? Colors.green : Colors.red)
                          : AppColors.borderSubtle,
                      width: isSelected ? 1.5 : 1,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedTestCaseIndex = idx);
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Active Testcase Breakdown Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.codeBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activeResult.passed
                    ? Colors.green.withValues(alpha: 0.5)
                    : Colors.red.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TESTCASE #${activeResult.testIndex}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: activeResult.passed
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        activeResult.status ??
                            (activeResult.passed ? 'PASSED' : 'FAILED'),
                        style: TextStyle(
                          color: activeResult.passed
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Input
                if (activeResult.input != null &&
                    activeResult.input!.isNotEmpty) ...[
                  const Text(
                    'Input:',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.codeBgDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      activeResult.input!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Expected Output
                if (activeResult.expected != null) ...[
                  const Text(
                    'Expected Output:',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.codeBgDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      activeResult.expected!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Actual Output
                const Text(
                  'Your Output:',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.codeBgDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    activeResult.stdout.isEmpty
                        ? '(No standard output)'
                        : activeResult.stdout,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: activeResult.passed
                          ? Colors.white
                          : Colors.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
                ),

                // Stderr / Compiler Output if any
                if (activeResult.stderr.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Compiler / Error Output:',
                    style: TextStyle(color: Colors.redAccent, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: SelectableText(
                      activeResult.stderr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerdictBanner(ExecutionState execState) {
    final isPassed = execState.allPassed == true;
    final verdict =
        execState.overallVerdict ?? (isPassed ? 'Accepted' : 'Wrong Answer');
    final passedCount =
        execState.testResults?.where((r) => r.passed).length ?? 0;
    final totalCount = execState.testResults?.length ?? 0;

    Color color = Colors.green;
    IconData icon = Icons.check_circle;

    if (!isPassed) {
      if (verdict == 'Compilation Error') {
        color = Colors.red;
        icon = Icons.error;
      } else if (verdict == 'Time Limit Exceeded') {
        color = Colors.orange;
        icon = Icons.timer_off;
      } else if (verdict == 'Runtime Error') {
        color = Colors.redAccent;
        icon = Icons.warning;
      } else {
        color = Colors.red;
        icon = Icons.cancel;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verdict,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$passedCount of $totalCount test cases passed${execState.executionTimeMs != null ? ' • Runtime: ${execState.executionTimeMs}ms' : ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: CUSTOM INPUT ---
  Widget _buildCustomInputTab(
    BuildContext context,
    CodingProblemModel problem,
    ExecutionState execState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test with Custom Input (stdin)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Provide input data line-by-line to execute your code interactively.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Custom Input TextField
          TextField(
            controller: _customInputController,
            maxLines: 4,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.white,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.codeBg,
              hintText: 'Enter test input here (e.g. 5 or [1, 2, 3])...',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontFamily: 'monospace',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
            ),
          ),
          const SizedBox(height: 12),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: execState.isExecuting
                ? null
                : () => _handleRunCustomInput(problem),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Run with Custom Input'),
          ),

          if (execState.customOutput != null) ...[
            const SizedBox(height: 20),
            const Text(
              'Custom Input Execution Output:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.codeBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: SelectableText(
                execState.customOutput!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.codeType,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- TAB 3: SUBMISSION HISTORY ---
  Widget _buildSubmissionsHistoryTab(
    BuildContext context,
    CodingProblemModel problem,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final submissions = ref.watch(problemSubmissionsProvider(problem.id));

        if (submissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 40, color: AppColors.textMuted),
                const SizedBox(height: 8),
                const Text(
                  'No submissions yet for this problem.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your submission attempts and verdicts will appear here.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: submissions.length,
          separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
          itemBuilder: (ctx, idx) {
            final sub = submissions[idx];
            final isPassed = sub.passed;
            final verdict =
                sub.verdict ?? (isPassed ? 'Accepted' : 'Wrong Answer');

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.codeBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPassed
                      ? Colors.green.withValues(alpha: 0.3)
                      : AppColors.borderSubtle,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPassed ? Icons.check_circle : Icons.cancel,
                    color: isPassed ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              verdict,
                              style: TextStyle(
                                color: isPassed ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bgSurfaceAlt,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                sub.language.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${sub.testCasesPassed}/${sub.testCasesTotal} tests passed • ${_formatDate(sub.submittedAt)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accentPurpleLight,
                    ),
                    onPressed: () => _showSubmissionCodeDialog(sub),
                    icon: const Icon(Icons.code, size: 14),
                    label: const Text(
                      'View Code',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSubmissionCodeDialog(CodingSubmissionModel sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Row(
          children: [
            Icon(
              sub.passed ? Icons.check_circle : Icons.cancel,
              color: sub.passed ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              '${sub.verdict ?? (sub.passed ? "Accepted" : "Attempt")} (${sub.language.toUpperCase()})',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submitted on ${_formatDate(sub.submittedAt)} • ${sub.testCasesPassed}/${sub.testCasesTotal} passed',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.codeBgDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    sub.code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPurple,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedLanguage = sub.language;
                _codeController.language = sub.language == 'python'
                    ? python
                    : java;
                _codeController.text = sub.code;
                _languageDrafts[sub.language] = sub.code;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Loaded submitted code into editor!'),
                ),
              );
            },
            icon: const Icon(Icons.restore, size: 16, color: Colors.white),
            label: const Text(
              'Load into Editor',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 4: AI DEBUGGING MENTOR ---
  Widget _buildAiMentorTab(
    BuildContext context,
    CodingProblemModel problem,
    ExecutionState execState,
  ) {
    if (execState.isLoadingAiHint) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.purpleAccent),
            SizedBox(height: 16),
            Text(
              'AI Mentor is reviewing your code logic...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (execState.aiHint == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.purpleAccent,
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                'AI Debugging Mentor',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Get tailored hints and edge-case guidance without spoiling the full solution code.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: () {
                  ref
                      .read(executionProvider.notifier)
                      .fetchAiHint(
                        problem: problem,
                        language: _selectedLanguage,
                        code: _codeController.text,
                      );
                },
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Ask AI Mentor for Hint'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.codePurpleBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.codePurpleBorder, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.purpleAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'AI Mentor Feedback & Debugging Hint',
                    style: TextStyle(
                      color: Colors.purpleAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: Colors.purpleAccent,
                  ),
                  tooltip: 'Regenerate Hint',
                  onPressed: () {
                    ref
                        .read(executionProvider.notifier)
                        .fetchAiHint(
                          problem: problem,
                          language: _selectedLanguage,
                          code: _codeController.text,
                        );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              execState.aiHint!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BADGES & HELPER WIDGETS
  // ===========================================================================
  Widget _buildSolvedStatusBadge(String status) {
    if (status == 'solved') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: Colors.green),
            SizedBox(width: 4),
            Text(
              'SOLVED',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'attempted') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pending, size: 14, color: Colors.orange),
            SizedBox(width: 4),
            Text(
              'ATTEMPTED',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Text(
          'UNSOLVED',
          style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    }
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color = Colors.green;
    final dLower = difficulty.toLowerCase();
    if (dLower == 'medium') color = Colors.orange;
    if (dLower == 'hard') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  CodingProblemModel _fallbackProblem() {
    return CodingProblemModel(
      id: 'cp_001',
      title: 'Two Sum',
      difficulty: 'easy',
      category: 'arrays',
      description:
          'Given an array of integers nums and an integer target, return indices of the two numbers such that they add up to target.\n\nYou may assume that each input would have exactly one solution, and you may not use the same element twice.',
      constraints: ['2 <= nums.length <= 10^4', '-10^9 <= nums[i] <= 10^9'],
      sampleInput: '[2, 7, 11, 15]\n9',
      sampleOutput: '[0, 1]',
      testCases: [
        TestCase(input: '[2, 7, 11, 15]\n9', output: '[0, 1]'),
        TestCase(input: '[3, 2, 4]\n6', output: '[1, 2]'),
      ],
      starterCode: {
        'python':
            'def two_sum(nums, target):\n    # Write your solution here\n    pass',
        'java':
            'public class Solution {\n    public int[] twoSum(int[] nums, int target) {\n        return new int[]{};\n    }\n}',
      },
      timeLimit: 5,
      memoryLimit: 256,
    );
  }
}
