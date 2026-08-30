import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

import '../../core/constants.dart';
import '../../models/aptitude_problem_model.dart';
import '../../providers/admin_provider.dart';

class AdminQuestionImporterScreen extends ConsumerStatefulWidget {
  const AdminQuestionImporterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminQuestionImporterScreen> createState() => _AdminQuestionImporterScreenState();
}

class _AdminQuestionImporterScreenState extends ConsumerState<AdminQuestionImporterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1: Manual Form Controllers
  final _manualFormKey = GlobalKey<FormState>();
  String _manualCategory = 'quantitative';
  int _manualYear = 2024;
  final _manualCompanyController = TextEditingController(text: 'TCS');
  String _manualDifficulty = 'easy';
  final _manualQuestionController = TextEditingController();
  final _manualOptionAController = TextEditingController();
  final _manualOptionBController = TextEditingController();
  final _manualOptionCController = TextEditingController();
  final _manualOptionDController = TextEditingController();
  int _manualCorrectIndex = 0;
  final _manualExplanationController = TextEditingController();

  // Tab 2: AI Paste Controllers
  final _aiRawTextController = TextEditingController();
  List<AptitudeProblemModel> _aiPreviewQuestions = [];

  // Tab 3: CSV Controllers
  String? _csvFileName;
  List<AptitudeProblemModel> _csvPreviewQuestions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualCompanyController.dispose();
    _manualQuestionController.dispose();
    _manualOptionAController.dispose();
    _manualOptionBController.dispose();
    _manualOptionCController.dispose();
    _manualOptionDController.dispose();
    _manualExplanationController.dispose();
    _aiRawTextController.dispose();
    super.dispose();
  }

  Future<void> _pickAndParseCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read CSV file bytes.')),
        );
      }
      return;
    }

    final content = utf8.decode(bytes);
    final notifier = ref.read(adminImporterProvider.notifier);
    final parsed = notifier.parseCsvString(content);

    setState(() {
      _csvFileName = file.name;
      _csvPreviewQuestions = parsed;
    });
  }

  void _confirmDeleteAll() {
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete All Aptitude Questions'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This is a destructive action that will delete ALL aptitude questions from Firestore. Type "DELETE" to confirm:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (confirmController.text.trim() == 'DELETE') {
                Navigator.pop(ctx);
                ref.read(adminImporterProvider.notifier).deleteAllQuestions();
              }
            },
            child: const Text('Confirm Purge'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(adminImporterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Question Importer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: 'Delete All Questions',
            onPressed: _confirmDeleteAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'Manual Entry'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI Answer Gen'),
            Tab(icon: Icon(Icons.upload_file), text: 'CSV Upload'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Stats Counter
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aptitude Questions in Firestore',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: ${state.totalQuestionCount} questions available',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => ref.read(adminImporterProvider.notifier).refreshStats(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (state.statusMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: state.statusMessage!.contains('Error')
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: state.statusMessage!.contains('Error') ? Colors.red : Colors.green,
                      ),
                    ),
                    child: Text(
                      state.statusMessage!,
                      style: TextStyle(
                        color: state.statusMessage!.contains('Error') ? Colors.red : Colors.green[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildManualEntryTab(theme, state),
                      _buildAiAnswerGenTab(theme, state),
                      _buildCsvUploadTab(theme, state),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 1: MANUAL ENTRY ---
  Widget _buildManualEntryTab(ThemeData theme, AdminImporterState state) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _manualFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Single Question Entry', style: theme.textTheme.titleMedium),
                const Divider(),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _manualCategory,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: const [
                          DropdownMenuItem(value: 'quantitative', child: Text('Quantitative')),
                          DropdownMenuItem(value: 'logical', child: Text('Logical')),
                          DropdownMenuItem(value: 'verbal', child: Text('Verbal')),
                        ],
                        onChanged: (v) => setState(() => _manualCategory = v ?? 'quantitative'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _manualYear,
                        decoration: const InputDecoration(labelText: 'Year'),
                        items: [2021, 2022, 2023, 2024, 2025]
                            .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                            .toList(),
                        onChanged: (v) => setState(() => _manualYear = v ?? 2024),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _manualCompanyController,
                        decoration: const InputDecoration(labelText: 'Company (e.g. TCS, Infosys)'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _manualDifficulty,
                        decoration: const InputDecoration(labelText: 'Difficulty'),
                        items: const [
                          DropdownMenuItem(value: 'easy', child: Text('Easy')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'hard', child: Text('Hard')),
                        ],
                        onChanged: (v) => setState(() => _manualDifficulty = v ?? 'easy'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _manualQuestionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Question Text'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _manualOptionAController,
                        decoration: const InputDecoration(labelText: 'Option A'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _manualOptionBController,
                        decoration: const InputDecoration(labelText: 'Option B'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _manualOptionCController,
                        decoration: const InputDecoration(labelText: 'Option C'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _manualOptionDController,
                        decoration: const InputDecoration(labelText: 'Option D'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  value: _manualCorrectIndex,
                  decoration: const InputDecoration(labelText: 'Correct Option'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Option A')),
                    DropdownMenuItem(value: 1, child: Text('Option B')),
                    DropdownMenuItem(value: 2, child: Text('Option C')),
                    DropdownMenuItem(value: 3, child: Text('Option D')),
                  ],
                  onChanged: (v) => setState(() => _manualCorrectIndex = v ?? 0),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _manualExplanationController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Explanation (Optional)'),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            if (_manualFormKey.currentState?.validate() == true) {
                              final model = AptitudeProblemModel(
                                id: 'ap_man_${DateTime.now().millisecondsSinceEpoch}',
                                category: _manualCategory,
                                year: _manualYear,
                                company: _manualCompanyController.text.trim(),
                                questionText: _manualQuestionController.text.trim(),
                                options: [
                                  _manualOptionAController.text.trim(),
                                  _manualOptionBController.text.trim(),
                                  _manualOptionCController.text.trim(),
                                  _manualOptionDController.text.trim(),
                                ],
                                correctOptionIndex: _manualCorrectIndex,
                                explanation: _manualExplanationController.text.trim(),
                                difficulty: _manualDifficulty,
                              );

                              final ok = await ref
                                  .read(adminImporterProvider.notifier)
                                  .saveManualQuestion(model);
                              if (ok) {
                                _manualQuestionController.clear();
                                _manualExplanationController.clear();
                              }
                            }
                          },
                    icon: const Icon(Icons.save),
                    label: const Text('Save to Firestore'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 2: AI ANSWER GENERATION ---
  Widget _buildAiAnswerGenTab(ThemeData theme, AdminImporterState state) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bulk AI Answer & Explanation Generator', style: theme.textTheme.titleMedium),
              const Text(
                'Paste raw questions without answers below. Gemini AI will identify the correct option and generate step-by-step explanations.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _aiRawTextController,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Q: What is speed of train 100m long in 10s?\nA) 36 km/h\nB) 40 km/h\nC) 25 km/h\nD) 30 km/h\nCategory: quantitative\nYear: 2024\nCompany: TCS',
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                onPressed: state.isLoading
                    ? null
                    : () async {
                        final raw = _aiRawTextController.text.trim();
                        if (raw.isNotEmpty) {
                          final res = await ref
                              .read(adminImporterProvider.notifier)
                              .generateAiAnswersForRawText(rawText: raw);
                          setState(() => _aiPreviewQuestions = res);
                        }
                      },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Answers with AI'),
              ),
              const SizedBox(height: 16),

              if (_aiPreviewQuestions.isNotEmpty) ...[
                Text(
                  'AI Generated Preview (${_aiPreviewQuestions.length} questions)',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.purple),
                ),
                const SizedBox(height: 8),
                Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _aiPreviewQuestions.length,
                    itemBuilder: (context, idx) {
                      final q = _aiPreviewQuestions[idx];
                      return ListTile(
                        title: Text('${idx + 1}. ${q.questionText}'),
                        subtitle: Text(
                          'Answer: Option ${String.fromCharCode(65 + q.correctOptionIndex)} — ${q.explanation}',
                          style: const TextStyle(fontSize: 12, color: Colors.purple),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            final ok = await ref
                                .read(adminImporterProvider.notifier)
                                .saveQuestionsBatch(_aiPreviewQuestions);
                            if (ok) {
                              setState(() {
                                _aiPreviewQuestions = [];
                                _aiRawTextController.clear();
                              });
                            }
                          },
                    icon: const Icon(Icons.cloud_upload),
                    label: Text('Save ${_aiPreviewQuestions.length} Questions to Firestore'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 3: CSV UPLOAD ---
  Widget _buildCsvUploadTab(ThemeData theme, AdminImporterState state) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bulk CSV Upload', style: theme.textTheme.titleMedium),
              const Text(
                'Upload a .csv file containing aptitude questions. Template schema:\ncategory,year,company,questionText,optionA,optionB,optionC,optionD,correctOption,explanation,difficulty',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: state.isLoading ? null : _pickAndParseCsv,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload CSV File'),
                  ),
                  const SizedBox(width: 12),
                  if (_csvFileName != null)
                    Expanded(
                      child: Text(
                        'File: $_csvFileName (${_csvPreviewQuestions.length} questions parsed)',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (_csvPreviewQuestions.isNotEmpty) ...[
                Text('CSV Parsed Preview', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _csvPreviewQuestions.length,
                    itemBuilder: (context, idx) {
                      final q = _csvPreviewQuestions[idx];
                      return ListTile(
                        dense: true,
                        title: Text('${idx + 1}. [${q.company}] ${q.questionText}'),
                        subtitle: Text(
                          'Cat: ${q.category} | Ans: Option ${String.fromCharCode(65 + q.correctOptionIndex)}',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            final ok = await ref
                                .read(adminImporterProvider.notifier)
                                .saveQuestionsBatch(_csvPreviewQuestions);
                            if (ok) {
                              setState(() {
                                _csvPreviewQuestions = [];
                                _csvFileName = null;
                              });
                            }
                          },
                    icon: const Icon(Icons.cloud_upload),
                    label: Text('Import All ${_csvPreviewQuestions.length} to Firestore'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
