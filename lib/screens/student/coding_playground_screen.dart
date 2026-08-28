import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

class CodingPlaygroundScreen extends StatefulWidget {
  final String problemId;

  const CodingPlaygroundScreen({Key? key, required this.problemId}) : super(key: key);

  @override
  State<CodingPlaygroundScreen> createState() => _CodingPlaygroundScreenState();
}

class _CodingPlaygroundScreenState extends State<CodingPlaygroundScreen> {
  String _selectedLanguage = 'Python';
  double _fontSize = 14.0;
  bool _isRunning = false;
  bool _hasRun = false;
  String _consoleOutput = '';

  final _codeController = TextEditingController(text: '''def twoSum(nums, target):
    lookup = {}
    for i, num in enumerate(nums):
        diff = target - num
        if diff in lookup:
            return [lookup[diff], i]
        lookup[num] = i
    return []

# Test execution
print(twoSum([2, 7, 11, 15], 9))
''');

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _runCode() {
    setState(() {
      _isRunning = true;
      _consoleOutput = 'Compiling and executing code against test cases...\n';
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _hasRun = true;
        _consoleOutput = '''[INFO] Execution successful!
Output: [0, 1]
Test Case 1: PASSED (Input: nums = [2,7,11,15], target = 9)
Test Case 2: PASSED (Input: nums = [3,2,4], target = 6)
Time Taken: 24 ms | Memory: 14.2 MB

Gemini AI Feedback: Optimal O(N) time complexity solution using HashMap!''';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < AppBreakpoints.compactBreakpoint; // < 600px
    final isMedium = width >= AppBreakpoints.compactBreakpoint && width < AppBreakpoints.mediumBreakpoint; // 600-1023px

    if (isCompact) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Playground: ${widget.problemId}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset Code',
              onPressed: () {},
            ),
          ],
        ),
        body: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.description, size: 18), text: 'Problem'),
                  Tab(icon: Icon(Icons.code, size: 18), text: 'Editor'),
                  Tab(icon: Icon(Icons.terminal, size: 18), text: 'Console'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildProblemPane(context),
                    _buildEditorOnly(context),
                    _buildConsolePane(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Split Pane Ratios: 40/60 for Medium, 35/65 for Expanded
    final flexProblem = isMedium ? 40 : 35;
    final flexEditor = isMedium ? 60 : 65;

    return Scaffold(
      appBar: AppBar(
        title: Text('Playground: ${widget.problemId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Code',
            onPressed: () {},
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(flex: flexProblem, child: _buildProblemPane(context)),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            flex: flexEditor,
            child: Column(
              children: [
                Expanded(flex: 3, child: _buildEditorOnly(context)),
                const Divider(height: 1, thickness: 1),
                Expanded(flex: 2, child: _buildConsolePane(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemPane(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Two Sum', style: theme.textTheme.headlineMedium),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Easy', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Given an array of integers nums and an integer target, return indices of the two numbers such that they add up to target.\n\nYou may assume that each input would have exactly one solution, and you may not use the same element twice.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('Constraints', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text('• 2 <= nums.length <= 10^4\n• -10^9 <= nums[i] <= 10^9\n• Only one valid answer exists.'),
          const SizedBox(height: 16),
          Text('Sample Input / Output', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1B1F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Input: nums = [2,7,11,15], target = 9\nOutput: [0,1]\nExplanation: Because nums[0] + nums[1] == 9, we return [0, 1].',
              style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),

          // Test Case Results (After Running)
          if (_hasRun) ...[
            Text('Test Case Results', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              color: const Color(0xFFE8F5E9),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 10),
                    Text(
                      'All 2 Test Cases Passed!',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditorOnly(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Editor Controls Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: _selectedLanguage,
                underline: const SizedBox(),
                items: ['Python', 'Java', 'C++', 'JavaScript'].map((lang) {
                  return DropdownMenuItem(value: lang, child: Text(lang));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
                },
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () {
                      if (_fontSize > 10) setState(() => _fontSize -= 1);
                    },
                  ),
                  Text('${_fontSize.toInt()}pt', style: const TextStyle(fontSize: 12)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () {
                      if (_fontSize < 24) setState(() => _fontSize += 1);
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6750A4),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, AppBreakpoints.minTouchTarget),
                    ),
                    onPressed: _isRunning ? null : _runCode,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Run Code'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      minimumSize: const Size(70, AppBreakpoints.minTouchTarget),
                    ),
                    onPressed: _isRunning ? null : _runCode,
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Code Editor Textarea
        Expanded(
          child: Container(
            color: const Color(0xFF1C1B1F),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _codeController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: _fontSize,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsolePane(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF121212),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.terminal, color: Colors.grey, size: 16),
              SizedBox(width: 6),
              Text('Console Output', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                _isRunning
                    ? 'Executing program...'
                    : (_consoleOutput.isEmpty ? 'Click "Run Code" to view terminal output.' : _consoleOutput),
                style: GoogleFonts.jetBrainsMono(
                  color: _consoleOutput.contains('PASSED') ? Colors.greenAccent : Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
