import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/constants.dart';
import '../../models/resume_report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/resume_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/responsive_grid.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _uploadAndAnalyzeResume(
    BuildContext context,
    WidgetRef ref,
    String targetRole,
  ) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read PDF file bytes. Please try another file.')),
          );
        }
        return;
      }

      // Show Progress Dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => const AlertDialog(
          content: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(
                  child: Text('Uploading PDF & Analyzing ATS score with Gemini AI...'),
                ),
              ],
            ),
          ),
        ),
      );

      // 1. Extract plain text from PDF
      final pdfService = ref.read(pdfServiceProvider);
      final text = pdfService.extractTextFromPdfBytes(bytes);
      final resumeText = text.isNotEmpty ? text : "Candidate Resume applying for position of $targetRole.";

      // 2. Upload to Cloudinary
      final cloudinaryService = ref.read(cloudinaryServiceProvider);
      String? secureUrl;
      try {
        secureUrl = await cloudinaryService.uploadPdf(bytes: bytes, fileName: file.name);
      } catch (e) {
        debugPrint("Cloudinary upload warning: $e");
      }

      // 3. Analyze with Gemini 2.0 Flash
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

      // 4. Save report to Firestore
      await ref.read(resumeRepositoryProvider).saveResumeReport(report);

      // Dismiss Progress Dialog & Navigate to Report
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        context.go('/resume-report');
      }
    } catch (e, st) {
      debugPrint("Error in _uploadAndAnalyzeResume: $e\n$st");
      if (context.mounted) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final reportState = ref.watch(latestResumeReportProvider);
    final user = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => context.go('/profile-setup'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Log Out',
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: profileState.when(
        data: (profile) {
          final fullName = profile?.fullName.isNotEmpty == true
              ? profile!.fullName
              : (AppConstants.USE_MOCK_DATA ? 'Alex Morgan' : 'Student Name');
          final branch = profile?.branch.isNotEmpty == true
              ? profile!.branch
              : (AppConstants.USE_MOCK_DATA ? 'Computer Science & Engineering' : 'Not Specified');
          final semester = profile?.targetSemester.isNotEmpty == true
              ? profile!.targetSemester
              : (AppConstants.USE_MOCK_DATA ? 'Semester 7' : 'Not Specified');
          final role = profile?.preferredRole.isNotEmpty == true
              ? profile!.preferredRole
              : (AppConstants.USE_MOCK_DATA ? 'Software Engineer' : 'Software Engineer');
          final targetCompanies = profile?.targetCompanies.isNotEmpty == true
              ? profile!.targetCompanies
              : (AppConstants.USE_MOCK_DATA ? ['Google', 'Microsoft', 'Amazon', 'TCS'] : <String>[]);
          final cgpa = profile?.cgpa ?? (AppConstants.USE_MOCK_DATA ? 8.7 : null);
          final email = user?.email ?? (AppConstants.USE_MOCK_DATA ? 'alex.morgan@univ.edu' : '');

          final latestReport = reportState.value;
          final currentScore = latestReport?.overallScore ?? profile?.cgpa?.toInt() ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: theme.textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    role,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  if (email.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => context.go('/profile-setup'),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Summary Grid
                    ResponsiveGrid(
                      minItemWidth: 150.0,
                      spacing: 12.0,
                      children: [
                        _buildStatBox(context, '0', 'Problems Solved', Icons.code),
                        _buildStatBox(context, '0', 'Mock Interviews', Icons.video_call),
                        _buildStatBox(context, '$currentScore/100', 'Resume ATS Score', Icons.description),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Academic Details Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Academic Details', style: theme.textTheme.titleMedium),
                            const Divider(),
                            _buildInfoRow(Icons.school, 'Branch', branch),
                            _buildInfoRow(Icons.timeline, 'Semester', semester),
                            if (cgpa != null)
                              _buildInfoRow(Icons.grade, 'CGPA', cgpa.toString()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Career Aspirations Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Career Aspirations', style: theme.textTheme.titleMedium),
                            const Divider(),
                            _buildInfoRow(Icons.work, 'Preferred Role', role),
                            const SizedBox(height: 12),
                            Text('Target Companies', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: targetCompanies.map((c) {
                                return Chip(
                                  label: Text(c),
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  labelStyle: TextStyle(color: theme.colorScheme.primary),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Live Resume Card with Upload Trigger
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.description, color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text('Resume ATS Analysis', style: theme.textTheme.titleMedium),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: latestReport != null
                                        ? (latestReport.overallScore >= 75
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.orange.withOpacity(0.1))
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    latestReport != null
                                        ? 'Score: ${latestReport.overallScore}/100'
                                        : 'Not Scanned',
                                    style: TextStyle(
                                      color: latestReport != null
                                          ? (latestReport.overallScore >= 75 ? Colors.green : Colors.orange)
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              latestReport != null
                                  ? 'Latest ATS evaluation complete. Missing keywords: ${latestReport.missingKeywords.take(3).join(", ")}'
                                  : 'Upload your resume PDF to generate a real-time AI ATS compatibility report and keyword recommendations.',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                if (latestReport != null) ...[
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => context.go('/resume-report'),
                                      icon: const Icon(Icons.analytics_outlined, size: 18),
                                      label: const Text('View Report'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _uploadAndAnalyzeResume(context, ref, role),
                                    icon: const Icon(Icons.upload_file, size: 18),
                                    label: const Text('Upload Resume PDF'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Log Out Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).signOut();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Log Out'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading profile: $error')),
      ),
    );
  }

  Widget _buildStatBox(BuildContext context, String number, String label, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
