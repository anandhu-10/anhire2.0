import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/user_provider.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../widgets/app_logo_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Learning preferences controllers
  late TextEditingController _targetRoleController;
  late TextEditingController _newCompanyController;
  List<String> _targetCompanies = [];
  bool _isSavingLearningPrefs = false;
  bool _hasInitializedProfileData = false;

  @override
  void initState() {
    super.initState();
    _targetRoleController = TextEditingController();
    _newCompanyController = TextEditingController();
  }

  @override
  void dispose() {
    _targetRoleController.dispose();
    _newCompanyController.dispose();
    super.dispose();
  }

  void _syncWithProfile(ProfileModel profile) {
    if (!_hasInitializedProfileData) {
      _targetRoleController.text = profile.preferredRole;
      _targetCompanies = List<String>.from(profile.targetCompanies);
      _hasInitializedProfileData = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final profileAsync = ref.watch(profileProvider);
    final user = FirebaseAuth.instance.currentUser;

    profileAsync.whenData((profile) {
      if (profile != null) {
        _syncWithProfile(profile);
      }
    });

    return Scaffold(
      backgroundColor: context.appRootBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.settings_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Settings & Preferences',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: context.appTextPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Customize your coding workspace, notifications, and profile goals',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: context.appTextMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Settings Cards
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Section A: Appearance
                      _buildAppearanceSection(context, settings),
                      const SizedBox(height: 20),

                      // Section B: Notifications
                      _buildNotificationsSection(context, settings),
                      const SizedBox(height: 20),

                      // Section C: Learning Preferences
                      _buildLearningPreferencesSection(
                        context,
                        settings,
                        profileAsync.value,
                      ),
                      const SizedBox(height: 20),

                      // Section D: Privacy and Security
                      _buildPrivacyAndSecuritySection(context, user),
                      const SizedBox(height: 20),

                      // Section E: About ANHIRE
                      _buildAboutSection(context),
                      const SizedBox(height: 48),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION A: APPEARANCE
  // ===========================================================================
  Widget _buildAppearanceSection(BuildContext context, SettingsState settings) {
    return _buildCard(
      title: 'Appearance & Workspace',
      subtitle: 'Code editor display and typography preferences',
      icon: Icons.palette_outlined,
      children: [
        // Code Editor Font Size
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Code Editor Font Size',
                  style: TextStyle(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Adjust the text size for coding playground and test runners',
                  style: TextStyle(color: context.appTextMuted, fontSize: 13),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.isDark
                    ? AppColors.darkSurfaceSecondary
                    : AppColors.lightSurfaceSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.appBorder),
              ),
              child: Text(
                '${settings.editorFontSize.toInt()} px',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: context.isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            valueIndicatorColor: AppColors.primary,
          ),
          child: Slider(
            value: settings.editorFontSize,
            min: 12.0,
            max: 22.0,
            divisions: 5,
            label: '${settings.editorFontSize.toInt()} px',
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setEditorFontSize(val);
            },
          ),
        ),
        Divider(color: context.appBorder, height: 32),

        // Code Editor Word Wrap
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Editor Word Wrap',
            style: TextStyle(
              color: context.appTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            'Soft-wrap long code statements horizontally instead of horizontal scrolling',
            style: TextStyle(color: context.appTextMuted, fontSize: 13),
          ),
          value: settings.editorWordWrap,
          activeThumbColor: AppColors.primary,
          onChanged: (val) {
            ref.read(settingsProvider.notifier).setEditorWordWrap(val);
          },
        ),
        const SizedBox(height: 12),

        // Mini Code Live Preview Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.isDark
                ? const Color(0xFF13131D)
                : const Color(0xFFF1F1F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.appBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Preview — solution.py',
                    style: TextStyle(
                      color: context.appTextMuted,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'def solve_placement_challenge():\n    prep_status = "Ready to crack interviews!"\n    return prep_status',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: settings.editorFontSize,
                  color: context.isDark
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF1E293B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION B: NOTIFICATIONS
  // ===========================================================================
  Widget _buildNotificationsSection(
    BuildContext context,
    SettingsState settings,
  ) {
    final reminderTime = TimeOfDay(
      hour: settings.dailyReminderHour,
      minute: settings.dailyReminderMinute,
    );

    return _buildCard(
      title: 'Notifications & Reminders',
      subtitle: 'Schedule placement prep alerts and streak reminders',
      icon: Icons.notifications_outlined,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Daily Practice Reminders',
            style: TextStyle(
              color: context.appTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            kIsWeb
                ? 'Scheduled for mobile devices. (Web notifications operate when platform workers are active).'
                : 'Receive a daily prompt on this device to maintain your streak.',
            style: TextStyle(color: context.appTextMuted, fontSize: 13),
          ),
          value: settings.dailyReminderEnabled,
          activeThumbColor: AppColors.primary,
          onChanged: (val) {
            ref.read(settingsProvider.notifier).setDailyReminderEnabled(val);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  val
                      ? 'Daily practice reminder enabled'
                      : 'Daily practice reminder disabled',
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: context.isDark
                    ? AppColors.darkSurfaceSecondary
                    : AppColors.lightSurfaceSecondary,
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // Reminder Time Picker Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.isDark
                ? AppColors.darkSurfaceSecondary
                : AppColors.lightSurfaceSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.appBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheduled Reminder Time',
                        style: TextStyle(
                          color: context.appTextPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        reminderTime.format(context),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: settings.dailyReminderEnabled
                    ? () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: reminderTime,
                          builder: (ctx, child) {
                            return Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  surface: context.appSurface,
                                  onSurface: context.appTextPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          await ref
                              .read(settingsProvider.notifier)
                              .setDailyReminderTime(picked.hour, picked.minute);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Reminder time set to ${picked.format(context)}',
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: context.isDark
                                    ? AppColors.darkSurfaceSecondary
                                    : AppColors.lightSurfaceSecondary,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                label: const Text('Change'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(color: context.appBorder, height: 32),

        // Achievement Notifications
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Achievement & Badge Alerts',
            style: TextStyle(
              color: context.appTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            'Instant celebration toasts when unlocking new badges and first-solve milestones',
            style: TextStyle(color: context.appTextMuted, fontSize: 13),
          ),
          value: settings.achievementAlertsEnabled,
          activeThumbColor: AppColors.primary,
          onChanged: (val) {
            ref
                .read(settingsProvider.notifier)
                .setAchievementAlertsEnabled(val);
          },
        ),
        Divider(color: context.appBorder, height: 32),

        // Interview Preparation Reminders
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Mock Interview Reminders',
            style: TextStyle(
              color: context.appTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            'Notifications 15 minutes before scheduled peer and AI mock interview sessions',
            style: TextStyle(color: context.appTextMuted, fontSize: 13),
          ),
          value: settings.interviewPrepRemindersEnabled,
          activeThumbColor: AppColors.primary,
          onChanged: (val) {
            ref
                .read(settingsProvider.notifier)
                .setInterviewPrepRemindersEnabled(val);
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION C: LEARNING PREFERENCES
  // ===========================================================================
  Widget _buildLearningPreferencesSection(
    BuildContext context,
    SettingsState settings,
    ProfileModel? profile,
  ) {
    return _buildCard(
      title: 'Learning & Placement Goals',
      subtitle:
          'Target roles, preferred programming language, and coding difficulty',
      icon: Icons.school_outlined,
      children: [
        // Preferred Programming Language
        Text(
          'Preferred Programming Language',
          style: TextStyle(
            color: context.appTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your default language when opening problem workspaces. Python and Java are fully supported with sandbox execution.',
          style: TextStyle(color: context.appTextMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            _buildLanguageChoiceChip(
              langKey: 'python',
              label: 'Python 3',
              icon: Icons.code_rounded,
              isSelected: settings.preferredLanguage == 'python',
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setPreferredLanguage('python');
              },
            ),
            _buildLanguageChoiceChip(
              langKey: 'java',
              label: 'Java 17',
              icon: Icons.coffee_rounded,
              isSelected: settings.preferredLanguage == 'java',
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setPreferredLanguage('java');
              },
            ),
          ],
        ),
        Divider(color: context.appBorder, height: 32),

        // Coding Difficulty
        Text(
          'Preferred Practice Difficulty',
          style: TextStyle(
            color: context.appTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Filter default recommendations on the Practice and Coding Hub',
          style: TextStyle(color: context.appTextMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: ['Easy', 'Medium', 'Hard'].map((diff) {
            final isSelected = settings.preferredDifficulty == diff;
            Color diffColor = AppColors.success;
            if (diff == 'Medium') diffColor = AppColors.warning;
            if (diff == 'Hard') diffColor = AppColors.error;

            return ChoiceChip(
              label: Text(diff),
              selected: isSelected,
              selectedColor: diffColor.withValues(alpha: 0.25),
              backgroundColor: context.isDark
                  ? AppColors.darkSurfaceSecondary
                  : AppColors.lightSurfaceSecondary,
              labelStyle: TextStyle(
                color: isSelected ? diffColor : context.appTextSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? diffColor : context.appBorder,
              ),
              onSelected: (_) {
                ref
                    .read(settingsProvider.notifier)
                    .setPreferredDifficulty(diff);
              },
            );
          }).toList(),
        ),
        Divider(color: context.appBorder, height: 32),

        // Target Job Role
        const Text(
          'Target Job Role',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Used to customize AI interview questions and resume analysis scoring',
          style: TextStyle(color: context.appTextMuted, fontSize: 13),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _targetRoleController,
          style: TextStyle(color: context.appTextPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Software Engineer, Full Stack, SDE 1',
            hintStyle: TextStyle(color: context.appTextMuted),
            filled: true,
            fillColor: context.isDark
                ? AppColors.darkSurfaceSecondary
                : AppColors.lightSurfaceSecondary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.appBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.appBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Target Companies
        Text(
          'Target Companies',
          style: TextStyle(
            color: context.appTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add dream companies you are targeting for placements and internships',
          style: TextStyle(color: context.appTextMuted, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _targetCompanies.map((comp) {
            return Chip(
              label: Text(
                comp,
                style: TextStyle(color: context.appTextPrimary, fontSize: 12),
              ),
              backgroundColor: context.isDark
                  ? AppColors.darkSurfaceSecondary
                  : AppColors.lightSurfaceSecondary,
              deleteIcon: Icon(
                Icons.close_rounded,
                size: 16,
                color: context.appTextMuted,
              ),
              side: BorderSide(color: context.appBorder),
              onDeleted: () {
                setState(() {
                  _targetCompanies.remove(comp);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newCompanyController,
                style: TextStyle(color: context.appTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Add company (e.g. Google, Amazon, TCS)',
                  hintStyle: TextStyle(color: context.appTextMuted),
                  filled: true,
                  fillColor: context.isDark
                      ? AppColors.darkSurfaceSecondary
                      : AppColors.lightSurfaceSecondary,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.appBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.appBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                onSubmitted: (val) => _handleAddCompany(),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _handleAddCompany,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Save Learning Preferences Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSavingLearningPrefs
                ? null
                : () => _saveLearningPreferences(profile, settings),
            icon: _isSavingLearningPrefs
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(
              _isSavingLearningPrefs
                  ? 'Saving Changes...'
                  : 'Save Learning Preferences',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleAddCompany() {
    final text = _newCompanyController.text.trim();
    if (text.isNotEmpty && !_targetCompanies.contains(text)) {
      setState(() {
        _targetCompanies.add(text);
        _newCompanyController.clear();
      });
    }
  }

  Future<void> _saveLearningPreferences(
    ProfileModel? currentProfile,
    SettingsState settings,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please log in to save learning preferences to your profile.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSavingLearningPrefs = true);

    try {
      final updatedRole = _targetRoleController.text.trim().isEmpty
          ? (currentProfile?.preferredRole ?? 'Software Engineer')
          : _targetRoleController.text.trim();

      final updatedProfile =
          (currentProfile ??
                  ProfileModel(
                    uid: user.uid,
                    fullName:
                        user.displayName ??
                        (user.email?.split('@').first ?? 'Student'),
                    branch: 'CSE',
                    targetSemester: 'Semester 7',
                    preferredRole: updatedRole,
                    targetCompanies: _targetCompanies.isEmpty
                        ? ['Google']
                        : _targetCompanies,
                    createdAt: DateTime.now(),
                  ))
              .copyWith(
                preferredRole: updatedRole,
                targetCompanies: _targetCompanies,
                preferredLanguage: settings.preferredLanguage,
                preferredDifficulty: settings.preferredDifficulty,
              );

      await ref.read(userRepositoryProvider).createProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✓ Learning preferences saved successfully to your ANHIRE profile!',
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingLearningPrefs = false);
      }
    }
  }

  Widget _buildLanguageChoiceChip({
    required String langKey,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(
                  alpha: context.isDark ? 0.25 : 0.12,
                )
              : (context.isDark
                    ? AppColors.darkSurfaceSecondary
                    : AppColors.lightSurfaceSecondary),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.appBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : context.appTextSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : context.appTextSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION D: PRIVACY AND SECURITY
  // ===========================================================================
  Widget _buildPrivacyAndSecuritySection(BuildContext context, User? user) {
    final email = user?.email ?? 'No email associated';
    final isVerified = user?.emailVerified ?? false;

    return _buildCard(
      title: 'Privacy & Security',
      subtitle: 'Manage authentication, password, and account security',
      icon: Icons.security_outlined,
      children: [
        // Account Email display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Email',
                  style: TextStyle(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isVerified
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isVerified ? AppColors.success : AppColors.warning,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVerified
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    size: 14,
                    color: isVerified ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isVerified ? 'Verified' : 'Unverified',
                    style: TextStyle(
                      color: isVerified ? AppColors.success : AppColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Divider(color: context.appBorder, height: 32),

        // Change Password & Sign Out Buttons
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showChangePasswordDialog(context, email),
              icon: const Icon(Icons.lock_reset_rounded, size: 18),
              label: const Text('Change Password'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.appTextPrimary,
                side: BorderSide(color: context.appBorder),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.warning,
              ),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.warning),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.warning.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        Divider(color: context.appBorder, height: 32),

        // Danger Zone: Delete Account
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(
              alpha: context.isDark ? 0.08 : 0.04,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Danger Zone — Account Deletion',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Permanently delete your ANHIRE account, mock interview logs, coding submissions, and profile data. This action cannot be reversed.',
                style: TextStyle(color: context.appTextMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _confirmDeleteAccount(context, user),
                icon: const Icon(Icons.delete_forever_rounded, size: 18),
                label: const Text('Delete Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.appBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              'Reset Password',
              style: TextStyle(
                color: context.appTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'We will send a secure password reset link to your registered email address:\n\n$email\n\nPlease follow the link in your inbox to set a new password.',
          style: TextStyle(
            color: context.appTextSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.appTextMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(authRepositoryProvider).resetPassword(email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Password reset link sent to $email'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send reset email: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.appBorder),
        ),
        title: Text(
          'Confirm Sign Out',
          style: TextStyle(
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of ANHIRE 2.0? Any unsaved coding drafts in your current editor will be saved locally.',
          style: TextStyle(color: context.appTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.appTextMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              performSignOut(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, User? user) {
    if (user == null) return;
    final confirmTextController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: context.appSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.appBorder),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_rounded, color: AppColors.error),
                SizedBox(width: 8),
                Text(
                  'Delete Account?',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action is irreversible. To confirm deletion, please type "DELETE" below:',
                  style: TextStyle(
                    color: context.appTextSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmTextController,
                  style: TextStyle(color: context.appTextPrimary),
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Type DELETE',
                    hintStyle: TextStyle(color: context.appTextMuted),
                    filled: true,
                    fillColor: context.isDark
                        ? AppColors.darkSurfaceSecondary
                        : AppColors.lightSurfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.appBorder),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: context.appTextMuted),
                ),
              ),
              ElevatedButton(
                onPressed: confirmTextController.text.trim() == 'DELETE'
                    ? () async {
                        Navigator.pop(ctx);
                        try {
                          await user.delete();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account deleted successfully.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            performSignOut(context, ref);
                          }
                        } on FirebaseAuthException catch (fe) {
                          if (context.mounted) {
                            final msg = fe.code == 'requires-recent-login'
                                ? 'Security requirement: Please sign out, log back in, and try deleting again.'
                                : 'Failed to delete account: ${fe.message}';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Permanently Delete'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // SECTION E: ABOUT ANHIRE
  // ===========================================================================
  Widget _buildAboutSection(BuildContext context) {
    return _buildCard(
      title: 'About ANHIRE 2.0',
      subtitle: 'Platform version and technical specifications',
      icon: Icons.info_outline_rounded,
      children: [
        Row(
          children: [
            const AppLogoWidget(size: 40, textSize: 18),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANHIRE 2.0 Placement Platform',
                  style: TextStyle(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Version 0.1.0+1 • Production Release',
                  style: TextStyle(color: context.appTextMuted, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'ANHIRE 2.0 is an intelligent placement preparation ecosystem providing interactive coding sandboxes, test evaluation, aptitude assessments, and AI mock interviews tailored for campus recruitment.',
          style: TextStyle(
            color: context.appTextSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        Divider(color: context.appBorder, height: 28),

        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: () => _showPolicyDialog(
                context,
                'Privacy Policy',
                'ANHIRE takes student privacy seriously. All coding submissions, test attempts, and resume documents are securely isolated per user authentication credentials. No student code or personal data is sold or shared with unapproved third parties.',
              ),
              icon: const Icon(
                Icons.privacy_tip_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              label: const Text(
                'Privacy Policy',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showPolicyDialog(
                context,
                'Terms of Service',
                'ANHIRE placement preparation services are provided for academic study and recruitment practice. Users agree not to abuse public code execution APIs or attempt unauthorized access to platform evaluation containers.',
              ),
              icon: const Icon(
                Icons.description_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              label: const Text(
                'Terms of Service',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showPolicyDialog(
                context,
                'Help & Feedback',
                'For placement team queries, campus bug reports, or feature requests, contact your campus placement representative or file an issue via the student administrative council.',
              ),
              icon: const Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              label: const Text(
                'Help & Feedback',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPolicyDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.appBorder),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          body,
          style: TextStyle(color: context.appTextSecondary, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REUSABLE CARD CONTAINER
  // ===========================================================================
  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.appTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.appTextMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
