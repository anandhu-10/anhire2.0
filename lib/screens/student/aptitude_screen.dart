import 'package:flutter/material.dart';
import '../../core/constants.dart';

class AptitudeQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String category;
  final String explanation;

  AptitudeQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.category,
    required this.explanation,
  });
}

class AptitudeScreen extends StatefulWidget {
  const AptitudeScreen({Key? key}) : super(key: key);

  @override
  State<AptitudeScreen> createState() => _AptitudeScreenState();
}

class _AptitudeScreenState extends State<AptitudeScreen> {
  String _selectedCategory = 'All';
  bool _enableTimer = true;
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _hasAnswered = false;
  int _score = 0;

  final List<AptitudeQuestion> _questions = [
    AptitudeQuestion(
      id: '1',
      question: 'A train 240 m long passes a pole in 24 seconds. What is the speed of the train in km/hr?',
      options: ['30 km/hr', '36 km/hr', '40 km/hr', '48 km/hr'],
      correctIndex: 1,
      category: 'Quantitative',
      explanation: 'Speed = Distance / Time = 240 / 24 = 10 m/s. Converting to km/hr = 10 * (18/5) = 36 km/hr.',
    ),
    AptitudeQuestion(
      id: '2',
      question: 'Find the next number in the series: 3, 5, 9, 17, 33, ?',
      options: ['48', '55', '65', '67'],
      correctIndex: 2,
      category: 'Logical',
      explanation: 'The pattern is: +2, +4, +8, +16, +32. So 33 + 32 = 65.',
    ),
    AptitudeQuestion(
      id: '3',
      question: 'Select the synonym for "EPHEMERAL":',
      options: ['Eternal', 'Transient', 'Permanent', 'Substantial'],
      correctIndex: 1,
      category: 'Verbal',
      explanation: 'Ephemeral means lasting for a very short time, which is synonymous with transient.',
    ),
  ];

  void _selectOption(int index) {
    if (_hasAnswered) return;
    setState(() {
      _selectedIndex = index;
      _hasAnswered = true;
      if (index == _questions[_currentIndex].correctIndex) {
        _score++;
      }
    });

    // Show Explanation Dialog
    final currentQ = _questions[_currentIndex];
    final isCorrect = index == currentQ.correctIndex;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isCorrect ? 'Correct!' : 'Incorrect'),
          ],
        ),
        content: Text(currentQ.explanation),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _nextQuestion();
            },
            child: const Text('Next Question'),
          ),
        ],
      ),
    );
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _hasAnswered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentQ = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aptitude Assessment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxCardWidthSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Aptitude Test', style: theme.textTheme.headlineMedium),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 18),
                        const SizedBox(width: 4),
                        Switch(
                          value: _enableTimer,
                          onChanged: (val) => setState(() => _enableTimer = val),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Quantitative', 'Logical', 'Verbal'].map((cat) {
                      final isSel = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          onSelected: (sel) {
                            if (sel) setState(() => _selectedCategory = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Progress Bar
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentIndex + 1} of ${_questions.length}',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Score: $_score',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Question Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            currentQ.category,
                            style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentQ.question,
                          style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 24),

                        // Options Cards
                        ...List.generate(currentQ.options.length, (idx) {
                          final optionText = currentQ.options[idx];
                          final isSelected = _selectedIndex == idx;
                          final isCorrect = idx == currentQ.correctIndex;

                          Color cardColor = theme.colorScheme.surface;
                          Color borderColor = theme.colorScheme.surfaceContainerHighest;

                          if (_hasAnswered) {
                            if (isCorrect) {
                              cardColor = Colors.green.withOpacity(0.1);
                              borderColor = Colors.green;
                            } else if (isSelected) {
                              cardColor = Colors.red.withOpacity(0.1);
                              borderColor = Colors.red;
                            }
                          } else if (isSelected) {
                            cardColor = theme.colorScheme.primaryContainer;
                            borderColor = theme.colorScheme.primary;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              onTap: () => _selectOption(idx),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: isSelected ? theme.colorScheme.primary : Colors.grey[200],
                                      child: Text(
                                        String.fromCharCode(65 + idx),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        optionText,
                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                                      ),
                                    ),
                                    if (_hasAnswered && isCorrect)
                                      const Icon(Icons.check_circle, color: Colors.green),
                                    if (_hasAnswered && isSelected && !isCorrect)
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
