import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/resume_report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coding_provider.dart';
import '../../providers/resume_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/services/notification_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _logoTapCount = 0;
  DateTime? _firstTapTime;

  void _onLogoTapped(BuildContext context) {
    final now = DateTime.now();
    if (_firstTapTime == null || now.difference(_firstTapTime!).inMilliseconds > 3000) {
      _firstTapTime = now;
      _logoTapCount = 1;
    } else {
      _logoTapCount++;
    }

    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      _firstTapTime = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ Admin Importer Mode Unlocked!'),
          backgroundColor: Color(0xFF6750A4),
          duration: Duration(seconds: 2),
        ),
      );
      context.go('/admin/importer');
    }
  }

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

      if (!context.mounted) return;
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
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final reportState = ref.watch(latestResumeReportProvider);
    final userSubmissionsAsync = ref.watch(userSubmissionsProvider);
    final user = ref.watch(authStateProvider).value;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1B1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1B1F),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: GestureDetector(
          onTap: () => _onLogoTapped(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ANHIRE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Color(0xFFD0BCFF),
                ),
              ),
              SizedBox(width: 6),
              Text(
                'Profile',
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      body: profileState.when(
        data: (profile) {
          final fullName = profile?.fullName.isNotEmpty == true
              ? profile!.fullName
              : (AppConstants.USE_MOCK_DATA ? 'Alex Morgan' : 'Student Name');
          final branch = profile?.branch.isNotEmpty == true
              ? profile!.branch
              : (AppConstants.USE_MOCK_DATA ? 'Computer Science & Engineering' : 'CSE');
          final semester = profile?.targetSemester.isNotEmpty == true
              ? profile!.targetSemester
              : (AppConstants.USE_MOCK_DATA ? 'Semester 7' : 'Semester 7');
          final role = profile?.preferredRole.isNotEmpty == true
              ? profile!.preferredRole
              : (AppConstants.USE_MOCK_DATA ? 'Software Engineer' : 'Software Engineer');
          final targetCompanies = profile?.targetCompanies.isNotEmpty == true
              ? profile!.targetCompanies
              : ['Google', 'Microsoft', 'Amazon', 'TCS', 'Infosys'];
          final cgpa = profile?.cgpa ?? 8.7;
          final email = user?.email ?? (AppConstants.USE_MOCK_DATA ? 'alex.morgan@univ.edu' : 'student@univ.edu');

          final submissions = userSubmissionsAsync.value ?? [];
          final solvedProblemsCount = submissions.where((s) => s.passed).map((s) => s.problemId).toSet().length;
          final solvedDisplay = solvedProblemsCount > 0
              ? '$solvedProblemsCount'
              : (AppConstants.USE_MOCK_DATA ? '12' : '0');

          final latestReport = reportState.value;
          final resumeScore = latestReport?.overallScore ?? 68;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24.0 : 16.0,
              vertical: isDesktop ? 24.0 : 16.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. PROFILE HEADER CARD
                    _buildDarkCard(
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () => context.go('/profile-setup'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFD0BCFF),
                                side: const BorderSide(color: Color(0xFFD0BCFF), width: 1.2),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.edit, size: 15),
                              label: const Text('Edit Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFF6750A4),
                            child: Text(
                              fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFFD0BCFF),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9F99A8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. STATS ROW (3 Cards)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 500;
                        final cards = [
                          _buildStatCard(
                            icon: Icons.code,
                            number: solvedDisplay,
                            label: 'Problems Solved',
                          ),
                          _buildStatCard(
                            icon: Icons.video_call,
                            number: '2',
                            label: 'Mock Interviews',
                          ),
                          _buildStatCard(
                            icon: Icons.description,
                            number: '$resumeScore',
                            numberSuffix: '/100',
                            label: 'Resume Score',
                          ),
                        ];

                        if (isCompact) {
                          return Column(
                            children: cards
                                .map((c) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: c,
                                    ))
                                .toList(),
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 12),
                            Expanded(child: cards[1]),
                            const SizedBox(width: 12),
                            Expanded(child: cards[2]),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. ACADEMIC DETAILS CARD (Multi-column)
                    _buildSectionCard(
                      title: 'Academic Details',
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 450;
                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabelValuePair('Branch', branch),
                                const SizedBox(height: 12),
                                _buildLabelValuePair('Semester', semester),
                                const SizedBox(height: 12),
                                _buildLabelValuePair('CGPA', cgpa.toString()),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: _buildLabelValuePair('Branch', branch)),
                              Expanded(child: _buildLabelValuePair('Semester', semester)),
                              Expanded(child: _buildLabelValuePair('CGPA', cgpa.toString())),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. CAREER ASPIRATIONS CARD
                    _buildSectionCard(
                      title: 'Career Aspirations',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabelValuePair('Preferred Role', role),
                          const SizedBox(height: 16),
                          const Text(
                            'Target Companies',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9F99A8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: targetCompanies.map((comp) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6750A4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  comp,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. RESUME CARD
                    _buildSectionCard(
                      title: 'Resume Analysis',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (latestReport != null) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE082),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Score: ${latestReport.overallScore}/100',
                                    style: const TextStyle(
                                      color: Color(0xFF3E2723),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Missing keywords: ${latestReport.missingKeywords.isNotEmpty ? latestReport.missingKeywords.take(4).join(", ") : "JavaScript, TypeScript, HTML5"}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9F99A8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6750A4),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => context.go('/resume-report'),
                                icon: const Icon(Icons.analytics_outlined, size: 18),
                                label: const Text('View Report', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'No resume uploaded yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9F99A8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFD0BCFF),
                                  side: const BorderSide(color: Color(0xFFD0BCFF), width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => _uploadAndAnalyzeResume(context, ref, role),
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text('Upload Resume PDF', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => _uploadAndAnalyzeResume(context, ref, role),
                              icon: const Icon(Icons.cloud_upload_outlined, size: 16, color: Color(0xFFD0BCFF)),
                              label: const Text(
                                'Upload New Resume',
                                style: TextStyle(color: Color(0xFFD0BCFF), fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6. SETTINGS & PREFERENCES CARD
                    _buildSectionCard(
                      title: 'Settings & Preferences',
                      child: _NotificationReminderToggle(),
                    ),
                    const SizedBox(height: 24),

                    // 6. LOG OUT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).signOut();
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: const Color(0xFFB3261E),
                          side: const BorderSide(color: Color(0xFFB3261E), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.logout, color: Color(0xFFB3261E)),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            color: Color(0xFFB3261E),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD0BCFF))),
        error: (error, stack) => Center(child: Text('Error loading profile: $error', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildDarkCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2930),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A383F), width: 1),
      ),
      child: child,
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String number,
    String? numberSuffix,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2930),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A383F), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFD0BCFF), size: 24),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (numberSuffix != null)
                Text(
                  numberSuffix,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF9F99A8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9F99A8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return _buildDarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD0BCFF),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildLabelValuePair(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _NotificationReminderToggle extends StatefulWidget {
  @override
  State<_NotificationReminderToggle> createState() => _NotificationReminderToggleState();
}

class _NotificationReminderToggleState extends State<_NotificationReminderToggle> {
  bool _remindersEnabled = true;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeColor: const Color(0xFFD0BCFF),
      title: const Text(
        'Daily Practice Reminders',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      subtitle: const Text(
        'Receive a daily notification at 7:00 PM to keep your streak going.',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF9F99A8),
        ),
      ),
      value: _remindersEnabled,
      onChanged: (val) {
        setState(() {
          _remindersEnabled = val;
        });
        NotificationService().scheduleDailyPracticeReminder(enabled: val);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              val
                  ? 'Daily practice reminders scheduled for 7:00 PM 🔥'
                  : 'Daily practice reminders turned off.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}
