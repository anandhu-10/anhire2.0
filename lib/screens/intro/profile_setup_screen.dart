import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/profile_model.dart';
import '../../models/resume_report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/resume_provider.dart';
import '../../providers/user_provider.dart';
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

  String? _uploadedResumeUrl;
  int? _uploadedResumeScore;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).value;
      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        if (_nameController.text.isEmpty) {
          _nameController.text = user.displayName!;
        }
      }
      final existingProfile = ref.read(profileProvider).value;
      if (existingProfile != null) {
        if (existingProfile.fullName.isNotEmpty) {
          _nameController.text = existingProfile.fullName;
        }
        if (existingProfile.preferredRole.isNotEmpty) {
          _roleController.text = existingProfile.preferredRole;
        }
        if (existingProfile.branch.isNotEmpty &&
            _branches.contains(existingProfile.branch)) {
          setState(() => _selectedBranch = existingProfile.branch);
        }
        if (existingProfile.targetSemester.isNotEmpty &&
            _semesters.contains(existingProfile.targetSemester)) {
          setState(() => _selectedSemester = existingProfile.targetSemester);
        }
        if (existingProfile.targetCompanies.isNotEmpty) {
          setState(() {
            _targetCompanies.clear();
            _targetCompanies.addAll(existingProfile.targetCompanies);
          });
        }
        if (existingProfile.cgpa != null) {
          _cgpaController.text = existingProfile.cgpa.toString();
        }
        if (existingProfile.resumeCloudinaryUrl != null) {
          setState(() {
            _uploadedResumeUrl = existingProfile.resumeCloudinaryUrl;
            _uploadedResumeScore = existingProfile.resumeScore;
          });
        }
      }
    });
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
            const SnackBar(
              content: Text(
                'Could not read PDF file bytes. Please try another file.',
              ),
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => const AlertDialog(
          backgroundColor: AppColors.bgCard,
          content: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircularProgressIndicator(color: AppColors.accentPurpleLight),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Uploading PDF & Analyzing ATS score with AI...',
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
      final resumeText = text.isNotEmpty
          ? text
          : "Candidate Resume applying for position of $targetRole.";

      final cloudinaryService = ref.read(cloudinaryServiceProvider);
      String? secureUrl;
      try {
        secureUrl = await cloudinaryService.uploadPdf(
          bytes: bytes,
          fileName: file.name,
        );
      } catch (e) {
        debugPrint("Cloudinary upload warning: $e");
      }

      final geminiService = ref.read(geminiServiceProvider);
      final analysisJson = await geminiService.analyzeResume(
        resumeText,
        targetRole,
      );

      final overallScore =
          (analysisJson['overallScore'] as num?)?.toInt() ?? 75;
      final sectionsRaw = analysisJson['sections'] as List<dynamic>? ?? [];
      final sections = sectionsRaw
          .map(
            (s) => ResumeSectionFeedback.fromMap(
              Map<String, dynamic>.from(s as Map),
            ),
          )
          .toList();
      final missingKeywordsRaw =
          analysisJson['missingKeywords'] as List<dynamic>? ?? [];
      final suggestionsRaw =
          analysisJson['suggestions'] as List<dynamic>? ?? [];

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

      setState(() {
        _uploadedResumeUrl = secureUrl;
        _uploadedResumeScore = overallScore;
      });

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Resume uploaded & analyzed! ATS score: $overallScore/100',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e, st) {
      debugPrint("Error in _uploadAndAnalyzeResume: $e\n$st");
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing resume: ${e.toString()}'),
            backgroundColor: AppColors.errorBorder,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_targetCompanies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one target company'),
            backgroundColor: AppColors.errorBorder,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final user = ref.read(authStateProvider).value;
        if (user == null)
          throw Exception("User authentication failed. Please sign in again.");

        final existingProfile = ref.read(profileProvider).value;

        final profile = ProfileModel(
          uid: user.uid,
          fullName: _nameController.text.trim(),
          branch: _selectedBranch,
          targetSemester: _selectedSemester,
          preferredRole: _roleController.text.trim(),
          targetCompanies: _targetCompanies,
          cgpa: double.tryParse(_cgpaController.text.trim()),
          resumeCloudinaryUrl:
              _uploadedResumeUrl ?? existingProfile?.resumeCloudinaryUrl,
          resumeScore: _uploadedResumeScore ?? existingProfile?.resumeScore,
          createdAt: existingProfile?.createdAt ?? DateTime.now(),
        );

        await ref.read(userRepositoryProvider).createProfile(profile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Profile setup completed successfully! Welcome to ANHIRE.',
              ),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
          context.go('/dashboard');
        }
      } catch (e) {
        debugPrint("Error saving profile: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving profile: $e'),
              backgroundColor: AppColors.errorBorder,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appRootBg,
      appBar: AppBar(
        backgroundColor: context.appRootBg,
        title: const Text(
          'Profile Onboarding',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => performSignOut(context, ref),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxCardWidthSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.8,
                    backgroundColor: context.isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    color: AppColors.primary,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step 1 of 1',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const Text(
                      '80% Completed',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.appBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: context.isDark ? 0.2 : 0.04,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
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
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    child: const Icon(
                                      Icons.person_outline_rounded,
                                      size: 48,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColors.primary,
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Let's set up your profile",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: context.appTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Personalize your AI placement recommendations',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.appTextMuted,
                                ),
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
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter your full name'
                              : null,
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
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                                items: _branches
                                    .map(
                                      (b) => DropdownMenuItem(
                                        value: b,
                                        child: Text(b),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedBranch = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedSemester,
                                decoration: const InputDecoration(
                                  labelText: 'Semester',
                                  prefixIcon: Icon(Icons.timeline_rounded),
                                ),
                                items: _semesters
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedSemester = val);
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
                            prefixIcon: Icon(Icons.work_outline_rounded),
                            hintText: 'e.g. Software Engineer',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter preferred role'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _suggestedRoles.map((role) {
                            final isSel = _roleController.text == role;
                            return ChoiceChip(
                              label: Text(
                                role,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSel
                                      ? Colors.white
                                      : context.appTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selected: isSel,
                              selectedColor: AppColors.primary,
                              backgroundColor: context.isDark
                                  ? AppColors.darkSurfaceSecondary
                                  : AppColors.lightSurfaceSecondary,
                              side: BorderSide(
                                color: isSel
                                    ? AppColors.primary
                                    : context.appBorder,
                                width: 1,
                              ),
                              onSelected: (sel) {
                                if (sel)
                                  setState(() => _roleController.text = role);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Target Companies Chip Input
                        Text(
                          'Target Companies',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: context.appTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _companyInputController,
                                decoration: const InputDecoration(
                                  hintText: 'Add company (e.g. Google)',
                                  prefixIcon: Icon(Icons.business_rounded),
                                ),
                                onSubmitted: _addCompany,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  _addCompany(_companyInputController.text),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Added company pills
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _targetCompanies.map((c) {
                            return Chip(
                              label: Text(
                                c,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: AppColors.primary,
                              deleteIcon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              onDeleted: () => _removeCompany(c),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        // Suggestions
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _suggestedCompanies.map((c) {
                            return ActionChip(
                              label: Text(
                                '+ $c',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.appTextSecondary,
                                ),
                              ),
                              backgroundColor: context.isDark
                                  ? AppColors.darkSurfaceSecondary
                                  : AppColors.lightSurfaceSecondary,
                              side: BorderSide(
                                color: context.appBorder,
                                width: 1,
                              ),
                              onPressed: () => _addCompany(c),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // CGPA Input
                        TextFormField(
                          controller: _cgpaController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'CGPA (Optional)',
                            prefixIcon: Icon(Icons.grade_outlined),
                            hintText: 'e.g. 8.5',
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Resume Upload Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: context.isDark ? 0.1 : 0.05,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _uploadedResumeUrl != null
                                  ? AppColors.success
                                  : AppColors.primary.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _uploadedResumeUrl != null
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.cloud_upload_outlined,
                                size: 40,
                                color: _uploadedResumeUrl != null
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _uploadedResumeUrl != null
                                    ? 'Resume Uploaded (Optional)'
                                    : 'Upload Resume PDF (Optional)',
                                style: TextStyle(
                                  color: _uploadedResumeUrl != null
                                      ? AppColors.success
                                      : AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _uploadedResumeUrl != null
                                    ? 'Your resume is uploaded (ATS Score: ${_uploadedResumeScore ?? "N/A"}/100). You can re-upload anytime.'
                                    : 'Select a PDF file to analyze with AI ATS. You can upload your resume later from your profile.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.appTextMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _uploadAndAnalyzeResume,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _uploadedResumeUrl != null
                                        ? context.appSurface
                                        : AppColors.primary,
                                    foregroundColor: _uploadedResumeUrl != null
                                        ? AppColors.primary
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: _uploadedResumeUrl != null
                                            ? AppColors.primary
                                            : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.upload_file_outlined),
                                  label: Text(
                                    _uploadedResumeUrl != null
                                        ? 'Re-upload Resume PDF'
                                        : 'Upload Resume PDF',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Complete Setup',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
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
}
