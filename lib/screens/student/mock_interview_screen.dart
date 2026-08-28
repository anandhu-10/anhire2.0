import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:go_router/go_router.dart';

class MockInterviewScreen extends StatefulWidget {
  const MockInterviewScreen({Key? key}) : super(key: key);

  @override
  State<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

enum InterviewStep { setup, question, evaluation, results }

class _MockInterviewScreenState extends State<MockInterviewScreen> {
  InterviewStep _step = InterviewStep.setup;

  String _selectedRole = 'Software Engineer';
  String _selectedCompany = 'Google';
  int _currentQuestionIndex = 0;
  final _answerController = TextEditingController();

  final List<Map<String, String>> _questions = [
    {
      'question': 'Can you explain the difference between Process and Thread in Operating Systems?',
      'type': 'Technical',
    },
    {
      'question': 'Describe a situation where you had a conflict with a team member and how you resolved it.',
      'type': 'Behavioral',
    },
    {
      'question': 'Why do you want to join our engineering team at Google?',
      'type': 'HR',
    },
  ];

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _startInterview() {
    setState(() {
      _step = InterviewStep.question;
      _currentQuestionIndex = 0;
      _answerController.clear();
    });
  }

  void _submitAnswer() {
    if (_answerController.text.trim().isEmpty) return;
    setState(() {
      _step = InterviewStep.evaluation;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answerController.clear();
        _step = InterviewStep.question;
      });
    } else {
      setState(() {
        _step = InterviewStep.results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Mock Interview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxCardWidthSmall),
            child: _buildStepContent(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_step) {
      case InterviewStep.setup:
        return _buildSetupCard(theme);
      case InterviewStep.question:
      case InterviewStep.evaluation:
        return _buildInterviewFlow(theme);
      case InterviewStep.results:
        return _buildResultsScreen(theme);
    }
  }

  Widget _buildSetupCard(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mock Interview Setup', style: theme.textTheme.headlineLarge),
        const SizedBox(height: 6),
        Text('Practice real-world AI-conducted interview questions with live feedback.', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Target Role',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  items: ['Software Engineer', 'Data Analyst', 'Full Stack Developer']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCompany,
                  decoration: const InputDecoration(
                    labelText: 'Target Company',
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: ['Google', 'Microsoft', 'Amazon', 'TCS']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCompany = val);
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _startInterview,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start AI Interview', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterviewFlow(ThemeData theme) {
    final q = _questions[_currentQuestionIndex];
    final isEval = _step == InterviewStep.evaluation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Q${_currentQuestionIndex + 1} of ${_questions.length}', style: theme.textTheme.titleMedium),
            Chip(
              label: Text(q['type']!),
              backgroundColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Question Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  q['question']!,
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _answerController,
                  enabled: !isEval,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Type your detailed response here...',
                    counterText: '${_answerController.text.length} characters',
                  ),
                  onChanged: (v) => setState(() {}),
                ),
                const SizedBox(height: 16),
                if (!isEval)
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _answerController.text.trim().isEmpty ? null : _submitAnswer,
                      child: const Text('Submit Answer'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Evaluation Card
        if (isEval) ...[
          Card(
            color: const Color(0xFFFAF8FF),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Gemini AI Evaluation', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildScoreMeter(context, 'Clarity', 0.85, '85%'),
                  const SizedBox(height: 8),
                  _buildScoreMeter(context, 'Technical Correctness', 0.90, '90%'),
                  const SizedBox(height: 8),
                  _buildScoreMeter(context, 'Confidence & Structure', 0.80, '80%'),
                  const SizedBox(height: 16),
                  Text(
                    'Feedback: Excellent distinction between address spaces! Add a brief mention of thread synchronization overhead for extra points.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _nextQuestion,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next Question'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultsScreen(ThemeData theme) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text('Interview Completed!', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: 0.88,
                        strokeWidth: 10,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('88', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        Text('Overall Score', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                _buildQuestionResultTile('Q1: Process vs Thread', 90),
                _buildQuestionResultTile('Q2: Conflict Resolution', 85),
                _buildQuestionResultTile('Q3: Why Google?', 89),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step = InterviewStep.setup),
                        child: const Text('Retake Interview'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/dashboard'),
                        child: const Text('Back to Dashboard'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreMeter(BuildContext context, String label, double val, String pctStr) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(pctStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: val,
          backgroundColor: theme.colorScheme.primaryContainer,
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildQuestionResultTile(String title, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('$score / 100', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }
}
