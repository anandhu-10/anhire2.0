import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/profile_model.dart';
import '../../models/resume_report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/resume_provider.dart';
import '../../repositories/user_repository.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _companyInputController = TextEditingController();
  final _cgpaController = TextEditingController();

  String _selectedBranch = 'CSE';
  String _selectedSemester = 'Semester 7';
  final List<String> _targetCompanies = ['Google', 'Microsoft', 'Amazon'];
  bool _isLoading = false;

  final List<String> _branches = [
    'CSE',
    'ECE',
    'EEE',
    'ME',
    'CE',
    'IT',
    'AI & DS',
  ];

  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  final List<String> _suggestedRoles = [
    'Software Engineer',
    'Data Analyst',
    'Full Stack Developer',
    'DevOps Engineer',
    'Frontend Developer',
  ];

  final List<String> _suggestedCompanies = [
    'Google',
    'Microsoft',
    'Amazon',
    'TCS',
    'Infosys',
    'Wipro',
    'Meta',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      _nameController.text = user.displayName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _companyInputController.dispose();
    _cgpaController.dispose();
    super.dispose();
  }

  void _addCompany(String company) {
    final trimmed = company.trim();
    if (trimmed.isNotEmpty && !_targetCompanies.contains(trimmed)) {
      setState(() {
        _targetCompanies.add(trimmed);
        _companyInputController.clear();
      });
    }
  }

  void _removeCompany(String company) {
    setState(() {
      _targetCompanies.remove(company);
    });
  }

  Future<void> _uploadAndAnalyzeResume() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final targetRole = _roleController.text.trim().isNotEmpty
        ? _roleController.text.trim()
        : 'Software Engineer';

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read PDF file bytes. Please try another file.')),
          );
        }
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => const AlertDialog(
          backgroundColor: Color(0xFF2B2930),
          content: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircularProgressIndicator(color: Color(0xFFD0BCFF)),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Uploading PDF & Analyzing ATS score with Gemini AI...',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final pdfService = ref.read(pdfServiceProvider);
      final text = pdfService.extractTextFromPdfBytes(bytes);
      final resumeText = text.isNotEmpty ? text : "Candidate Resume applying for position of $targetRole.";

      final cloudinaryService = ref.read(cloudinaryServiceProvider);
      String? secureUrl;
      try {
        secureUrl = await cloudinaryService.uploadPdf(bytes: bytes, fileName: file.name);
      } catch (e) {
        debugPrint("Cloudinary upload warning: $e");
      }

      final geminiService = ref.read(geminiServiceProvider);
      final analysisJson = await geminiService.analyzeResume(resumeText, targetRole);

      final overallScore = (analysisJson['overallScore'] as num?)?.toInt() ?? 75;
      final sectionsRaw = analysisJson['sections'] as List<dynamic>? ?? [];
      final sections = sectionsRaw
          .map((s) => ResumeSectionFeedback.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList();
      final missingKeywordsRaw = analysisJson['missingKeywords'] as List<dynamic>? ?? [];
      final suggestionsRaw = analysisJson['suggestions'] as List<dynamic>? ?? [];

      final report = ResumeReportModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        uid: user.uid,
        overallScore: overallScore,
        sections: sections,
        missingKeywords: missingKeywordsRaw.map((e) => e.toString()).toList(),
        suggestions: suggestionsRaw.map((e) => e.toString()).toList(),
        cloudinaryUrl: secureUrl,
        createdAt: DateTime.now(),
      );

      await ref.read(resumeRepositoryProvider).saveResumeReport(report);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resume analyzed! Score: $overallScore/100'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/resume-report');
      }
    } catch (e, st) {
      debugPrint("Error in _uploadAndAnalyzeResume: $e\n$st");
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing resume: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_targetCompanies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one target company')),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final user = ref.read(authStateProvider).value;
        if (user == null) throw Exception("Not authenticated");

        final profile = ProfileModel(
          uid: user.uid,
          fullName: _nameController.text.trim(),
          branch: _selectedBranch,
          targetSemester: _selectedSemester,
          preferredRole: _roleController.text.trim(),
          targetCompanies: _targetCompanies,
          cgpa: double.tryParse(_cgpaController.text.trim()),
          createdAt: DateTime.now(),
        );

        await ref.read(userRepositoryProvider).createProfile(profile);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Onboarding'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxCardWidthSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Bar
                LinearProgressIndicator(
                  value: 0.8,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step 1 of 1',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '80% Completed',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header + Avatar
                          Center(
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 44,
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: Icon(
                                        Icons.person_outline,
                                        size: 48,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: theme.colorScheme.primary,
                                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Let's set up your profile",
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Personalize your AI placement recommendations',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Full Name
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
                          ),
                          const SizedBox(height: 16),

                          // Row: Branch & Target Semester Dropdowns
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedBranch,
                                  decoration: const InputDecoration(
                                    labelText: 'Branch',
                                    prefixIcon: Icon(Icons.school),
                                  ),
                                  items: _branches
                                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedBranch = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedSemester,
                                  decoration: const InputDecoration(
                                    labelText: 'Semester',
                                    prefixIcon: Icon(Icons.timeline),
                                  ),
                                  items: _semesters
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedSemester = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Preferred Role with suggestion chips
                          TextFormField(
                            controller: _roleController,
                            decoration: const InputDecoration(
                              labelText: 'Preferred Role',
                              prefixIcon: Icon(Icons.work_outline),
                              hintText: 'e.g. Software Engineer',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter preferred role' : null,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _suggestedRoles.map((role) {
                              final isSel = _roleController.text == role;
                              return ChoiceChip(
                                label: Text(
                                  role,
                                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                                ),
                                selected: isSel,
                                selectedColor: const Color(0xFF6750A4),
                                backgroundColor: const Color(0xFF2B2930),
                                side: BorderSide(
                                  color: isSel ? const Color(0xFF6750A4) : const Color(0xFF3A383F),
                                  width: 1,
                                ),
                                onSelected: (sel) {
                                  if (sel) setState(() => _roleController.text = role);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Target Companies Chip Input
                          Text(
                            'Target Companies',
                            style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _companyInputController,
                                  decoration: const InputDecoration(
                                    hintText: 'Add company (e.g. Google)',
                                    prefixIcon: Icon(Icons.business),
                                  ),
                                  onSubmitted: _addCompany,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _addCompany(_companyInputController.text),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Added company pills
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _targetCompanies.map((c) {
                              return Chip(
                                label: Text(c, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                backgroundColor: const Color(0xFF6750A4),
                                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                                onDeleted: () => _removeCompany(c),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          // Suggestions
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _suggestedCompanies.map((c) {
                              return ActionChip(
                                label: Text('+ $c', style: const TextStyle(fontSize: 11, color: Colors.white)),
                                backgroundColor: const Color(0xFF2B2930),
                                side: const BorderSide(color: Color(0xFF3A383F), width: 1),
                                onPressed: () => _addCompany(c),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // CGPA Input
                          TextFormField(
                            controller: _cgpaController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'CGPA (Optional)',
                              prefixIcon: Icon(Icons.grade),
                              hintText: 'e.g. 8.5',
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Resume Upload Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(0.5),
                                style: BorderStyle.solid,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 40,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload Resume PDF',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Select a PDF file to analyze with Gemini AI ATS',
                                  style: theme.textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _uploadAndAnalyzeResume,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6750A4),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text(
                                      'Upload Resume PDF',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      'Complete Setup',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
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
