import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/notification_service.dart';

class SettingsState {
  final ThemeMode themeMode;
  final double editorFontSize;
  final bool editorWordWrap;
  final bool dailyReminderEnabled;
  final int dailyReminderHour;
  final int dailyReminderMinute;
  final bool achievementAlertsEnabled;
  final bool interviewPrepRemindersEnabled;
  final String preferredLanguage; // 'python' or 'java'
  final String preferredDifficulty; // 'Easy', 'Medium', 'Hard'
  final bool isLoaded;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.editorFontSize = 14.0,
    this.editorWordWrap = false,
    this.dailyReminderEnabled = true,
    this.dailyReminderHour = 19,
    this.dailyReminderMinute = 0,
    this.achievementAlertsEnabled = true,
    this.interviewPrepRemindersEnabled = false,
    this.preferredLanguage = 'python',
    this.preferredDifficulty = 'Medium',
    this.isLoaded = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    double? editorFontSize,
    bool? editorWordWrap,
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? achievementAlertsEnabled,
    bool? interviewPrepRemindersEnabled,
    String? preferredLanguage,
    String? preferredDifficulty,
    bool? isLoaded,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      editorFontSize: editorFontSize ?? this.editorFontSize,
      editorWordWrap: editorWordWrap ?? this.editorWordWrap,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      achievementAlertsEnabled:
          achievementAlertsEnabled ?? this.achievementAlertsEnabled,
      interviewPrepRemindersEnabled:
          interviewPrepRemindersEnabled ?? this.interviewPrepRemindersEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _keyThemeMode = 'anhire_settings_theme_mode';
  static const _keyEditorFontSize = 'anhire_settings_editor_font_size';
  static const _keyEditorWordWrap = 'anhire_settings_editor_word_wrap';
  static const _keyDailyReminder = 'anhire_settings_daily_reminder';
  static const _keyReminderHour = 'anhire_settings_reminder_hour';
  static const _keyReminderMinute = 'anhire_settings_reminder_minute';
  static const _keyAchievementAlerts = 'anhire_settings_achievement_alerts';
  static const _keyInterviewReminders = 'anhire_settings_interview_reminders';
  static const _keyPreferredLanguage = 'anhire_settings_preferred_language';
  static const _keyPreferredDifficulty = 'anhire_settings_preferred_difficulty';

  @override
  SettingsState build() {
    _loadPreferences();
    return const SettingsState();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final themeModeStr = prefs.getString(_keyThemeMode) ?? 'dark';
      ThemeMode themeMode;
      switch (themeModeStr) {
        case 'light':
          themeMode = ThemeMode.light;
          break;
        case 'system':
          themeMode = ThemeMode.system;
          break;
        case 'dark':
        default:
          themeMode = ThemeMode.dark;
          break;
      }

      final editorFontSize = prefs.getDouble(_keyEditorFontSize) ?? 14.0;
      final editorWordWrap = prefs.getBool(_keyEditorWordWrap) ?? false;
      final dailyReminder = prefs.getBool(_keyDailyReminder) ?? true;
      final reminderHour = prefs.getInt(_keyReminderHour) ?? 19;
      final reminderMinute = prefs.getInt(_keyReminderMinute) ?? 0;
      final achievementAlerts = prefs.getBool(_keyAchievementAlerts) ?? true;
      final interviewReminders = prefs.getBool(_keyInterviewReminders) ?? false;
      final preferredLanguage =
          prefs.getString(_keyPreferredLanguage) ?? 'python';
      final preferredDifficulty =
          prefs.getString(_keyPreferredDifficulty) ?? 'Medium';

      state = SettingsState(
        themeMode: themeMode,
        editorFontSize: editorFontSize.clamp(12.0, 24.0),
        editorWordWrap: editorWordWrap,
        dailyReminderEnabled: dailyReminder,
        dailyReminderHour: reminderHour,
        dailyReminderMinute: reminderMinute,
        achievementAlertsEnabled: achievementAlerts,
        interviewPrepRemindersEnabled: interviewReminders,
        preferredLanguage: preferredLanguage,
        preferredDifficulty: preferredDifficulty,
        isLoaded: true,
      );
    } catch (e) {
      debugPrint('Failed to load local preferences: $e');
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      String modeStr = 'dark';
      if (mode == ThemeMode.light) modeStr = 'light';
      if (mode == ThemeMode.system) modeStr = 'system';
      await prefs.setString(_keyThemeMode, modeStr);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  Future<void> setEditorFontSize(double size) async {
    final clamped = size.clamp(12.0, 24.0);
    state = state.copyWith(editorFontSize: clamped);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyEditorFontSize, clamped);
    } catch (e) {
      debugPrint('Error saving font size: $e');
    }
  }

  Future<void> setEditorWordWrap(bool wrap) async {
    state = state.copyWith(editorWordWrap: wrap);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEditorWordWrap, wrap);
    } catch (e) {
      debugPrint('Error saving word wrap: $e');
    }
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    state = state.copyWith(dailyReminderEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDailyReminder, enabled);
      await NotificationService().scheduleDailyPracticeReminder(
        enabled: enabled,
        hour: state.dailyReminderHour,
        minute: state.dailyReminderMinute,
      );
    } catch (e) {
      debugPrint('Error saving daily reminder toggle: $e');
    }
  }

  Future<void> setDailyReminderTime(int hour, int minute) async {
    state = state.copyWith(
      dailyReminderHour: hour,
      dailyReminderMinute: minute,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyReminderHour, hour);
      await prefs.setInt(_keyReminderMinute, minute);
      if (state.dailyReminderEnabled) {
        await NotificationService().scheduleDailyPracticeReminder(
          enabled: true,
          hour: hour,
          minute: minute,
        );
      }
    } catch (e) {
      debugPrint('Error saving reminder time: $e');
    }
  }

  Future<void> setAchievementAlertsEnabled(bool enabled) async {
    state = state.copyWith(achievementAlertsEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAchievementAlerts, enabled);
    } catch (e) {
      debugPrint('Error saving achievement alerts: $e');
    }
  }

  Future<void> setInterviewPrepRemindersEnabled(bool enabled) async {
    state = state.copyWith(interviewPrepRemindersEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyInterviewReminders, enabled);
    } catch (e) {
      debugPrint('Error saving interview reminders: $e');
    }
  }

  Future<void> setPreferredLanguage(String language) async {
    if (language != 'python' && language != 'java') return;
    state = state.copyWith(preferredLanguage: language);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPreferredLanguage, language);
    } catch (e) {
      debugPrint('Error saving preferred language: $e');
    }
  }

  Future<void> setPreferredDifficulty(String difficulty) async {
    state = state.copyWith(preferredDifficulty: difficulty);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPreferredDifficulty, difficulty);
    } catch (e) {
      debugPrint('Error saving preferred difficulty: $e');
    }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
