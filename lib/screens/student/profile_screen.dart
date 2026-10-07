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
import '../../core/constants/gamification.dart';
import '../../providers/gamification_provider.dart';
import '../../widgets/medal_badge_widget.dart';

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
          backgroundColor: AppColors.accentPurple,
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
          backgroundColor: AppColors.bgCard,
          content: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircularProgressIndicator(color: AppColors.accentPurpleLight),
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
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
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
                  color: AppColors.accentPurpleLight,
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

          final userId = user?.uid ?? '';
          final userPointsObj = ref.watch(userPointsProvider(userId)).value;
          final totalPoints = userPointsObj?.totalPoints ?? 0;
          final currentTier = MedalTier.fromPoints(totalPoints);
          final userBadgesObj = ref.watch(userBadgesProvider(userId)).value;
          final unlockedBadgesMap = {for (var b in (userBadgesObj?.badges ?? [])) b.id: b};

          final nextPts = currentTier.nextTierMinPoints;
          final nextLabel = currentTier.nextTierLabel;
          final ptsNeeded = (nextPts != null) ? (nextPts - totalPoints).clamp(0, 9999) : 0;

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
                                foregroundColor: AppColors.accentPurpleLight,
                                side: const BorderSide(color: AppColors.accentPurpleLight, width: 1.2),
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
                            backgroundColor: AppColors.accentPurple,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(width: 8),
                              MedalBadgeWidget(tier: currentTier, isChip: true),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.accentPurpleLight,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. STATS ROW (4 Cards)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 600;
                        final cards = [
                          _buildStatCard(
                            icon: Icons.emoji_events,
                            number: '$totalPoints',
                            label: 'Total Points',
                            iconColor: currentTier.color,
                          ),
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
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.3,
                            children: cards,
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 10),
                            Expanded(child: cards[1]),
                            const SizedBox(width: 10),
                            Expanded(child: cards[2]),
                            const SizedBox(width: 10),
                            Expanded(child: cards[3]),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. ACHIEVEMENTS & BADGES CARD
                    _buildSectionCard(
                      title: 'Achievements & Milestones 🏅',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$totalPoints pts (${currentTier.label} Tier)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              if (nextPts != null && nextLabel != null)
                                Text(
                                  '$ptsNeeded pts to $nextLabel',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                            ],
                          ),
                          if (nextPts != null) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (totalPoints / nextPts).clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: AppColors.bgInput,
                                valueColor: AlwaysStoppedAnimation<Color>(currentTier.color),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            'Unlocked Badges (${10 - unlockedBadgesMap.length} locked)',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: BadgeDefinition.allBadges.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final badgeDef = BadgeDefinition.allBadges[index];
                                final isUnlocked = unlockedBadgesMap.containsKey(badgeDef.id);
                                final unlockedBadge = unlockedBadgesMap[badgeDef.id];

                                return InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: AppColors.bgSurface,
                                        title: Row(
                                          children: [
                                            Icon(
                                              badgeDef.icon,
                                              color: isUnlocked ? AppColors.accentPurpleLight : AppColors.textMuted,
                                              size: 28,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                badgeDef.name,
                                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(badgeDef.description, style: const TextStyle(color: AppColors.textSecondary)),
                                            const SizedBox(height: 12),
                                            Text(
                                              isUnlocked
                                                  ? 'Status: Unlocked ✅ (${unlockedBadge?.unlockedAt.toString().split(' ')[0] ?? ""})'
                                                  : 'Status: Locked 🔒 Keep practicing to earn this badge!',
                                              style: TextStyle(
                                                color: isUnlocked ? AppColors.success : AppColors.warning,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 80,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isUnlocked ? AppColors.accentPurple.withValues(alpha: 0.25) : AppColors.bgInput,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isUnlocked ? AppColors.accentPurpleLight : AppColors.chipBorder,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Icon(
                                              badgeDef.icon,
                                              size: 32,
                                              color: isUnlocked ? AppColors.accentPurpleLight : AppColors.textMuted.withValues(alpha: 0.4),
                                            ),
                                            if (!isUnlocked)
                                              const Icon(
                                                Icons.lock,
                                                size: 18,
                                                color: AppColors.textMuted,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          badgeDef.name,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
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
                              color: AppColors.textMuted,
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
                                  color: AppColors.accentPurple,
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
                                    color: AppColors.warning,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Score: ${latestReport.overallScore}/100',
                                    style: const TextStyle(
                                      color: AppColors.textOnLavender,
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
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentPurple,
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
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.accentPurpleLight,
                                  side: const BorderSide(color: AppColors.accentPurpleLight, width: 1.5),
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
                              icon: const Icon(Icons.cloud_upload_outlined, size: 16, color: AppColors.accentPurpleLight),
                              label: const Text(
                                'Upload New Resume',
                                style: TextStyle(color: AppColors.accentPurpleLight, fontSize: 13, fontWeight: FontWeight.w600),
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
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              backgroundColor: AppColors.bgCard,
                              title: const Text('Log Out', style: TextStyle(color: Colors.white)),
                              content: const Text(
                                'Are you sure you want to log out of ANHIRE?',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dialogCtx).pop(),
                                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.errorBorder,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    Navigator.of(dialogCtx).pop();
                                    await performSignOut(context, ref);
                                  },
                                  child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppColors.errorBorder,
                          side: const BorderSide(color: AppColors.errorBorder, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.logout, color: AppColors.errorBorder),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            color: AppColors.errorBorder,
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
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentPurpleLight)),
        error: (error, stack) => Center(child: Text('Error loading profile: $error', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildDarkCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.chipBorder, width: 1),
      ),
      child: child,
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String number,
    String? numberSuffix,
    required String label,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.chipBorder, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor ?? AppColors.accentPurpleLight, size: 24),
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
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
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
              color: AppColors.accentPurpleLight,
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
      activeColor: AppColors.accentPurpleLight,
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
          color: AppColors.textMuted,
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
