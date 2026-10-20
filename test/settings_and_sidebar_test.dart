import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:placementprep/models/profile_model.dart';
import 'package:placementprep/providers/settings_provider.dart';
import 'package:placementprep/widgets/responsive_scaffold.dart';

void main() {
  group('SettingsState Tests', () {
    test(
      'Default SettingsState values are correctly configured for ANHIRE',
      () {
        const state = SettingsState();
        expect(state.themeMode, equals(ThemeMode.dark));
        expect(state.editorFontSize, equals(14.0));
        expect(state.editorWordWrap, isFalse);
        expect(state.dailyReminderEnabled, isTrue);
        expect(state.dailyReminderHour, equals(19));
        expect(state.dailyReminderMinute, equals(0));
        expect(state.achievementAlertsEnabled, isTrue);
        expect(state.interviewPrepRemindersEnabled, isFalse);
        expect(state.preferredLanguage, equals('python'));
        expect(state.preferredDifficulty, equals('Medium'));
        expect(state.isLoaded, isFalse);
      },
    );

    test('copyWith updates state fields immutably', () {
      const state = SettingsState();
      final updated = state.copyWith(
        themeMode: ThemeMode.light,
        editorFontSize: 18.0,
        editorWordWrap: true,
        dailyReminderHour: 20,
        dailyReminderMinute: 30,
        preferredLanguage: 'java',
        preferredDifficulty: 'Hard',
        isLoaded: true,
      );

      expect(updated.themeMode, equals(ThemeMode.light));
      expect(updated.editorFontSize, equals(18.0));
      expect(updated.editorWordWrap, isTrue);
      expect(updated.dailyReminderHour, equals(20));
      expect(updated.dailyReminderMinute, equals(30));
      expect(updated.preferredLanguage, equals('java'));
      expect(updated.preferredDifficulty, equals('Hard'));
      expect(updated.isLoaded, isTrue);
      // Ensure original is untouched
      expect(state.themeMode, equals(ThemeMode.dark));
    });
  });

  group('ProfileModel Learning Preferences Tests', () {
    test('ProfileModel defaults and copyWith for learning preferences', () {
      final now = DateTime.now();
      final profile = ProfileModel(
        uid: 'user_123',
        fullName: 'Alex Kumar',
        branch: 'CSE',
        targetSemester: 'Semester 7',
        preferredRole: 'Full Stack Engineer',
        targetCompanies: ['Google', 'Microsoft'],
        createdAt: now,
      );

      expect(profile.preferredLanguage, equals('python'));
      expect(profile.preferredDifficulty, equals('Medium'));

      final modified = profile.copyWith(
        preferredLanguage: 'java',
        preferredDifficulty: 'Hard',
        preferredRole: 'Backend Engineer',
      );

      expect(modified.preferredLanguage, equals('java'));
      expect(modified.preferredDifficulty, equals('Hard'));
      expect(modified.preferredRole, equals('Backend Engineer'));
      expect(modified.targetCompanies, equals(['Google', 'Microsoft']));
    });

    test(
      'ProfileModel toMap and fromMap serialization preserves learning preferences',
      () {
        final now = DateTime.now();
        final profile = ProfileModel(
          uid: 'user_456',
          fullName: 'Priya Sharma',
          branch: 'IT',
          targetSemester: 'Semester 8',
          preferredRole: 'Software Engineer',
          targetCompanies: ['Amazon', 'Adobe'],
          createdAt: now,
          preferredLanguage: 'java',
          preferredDifficulty: 'Hard',
        );

        final map = profile.toMap();
        expect(map['preferredLanguage'], equals('java'));
        expect(map['preferredDifficulty'], equals('Hard'));
        expect(map['preferredRole'], equals('Software Engineer'));

        final deserialized = ProfileModel.fromMap(map);
        expect(deserialized.uid, equals('user_456'));
        expect(deserialized.preferredLanguage, equals('java'));
        expect(deserialized.preferredDifficulty, equals('Hard'));
        expect(deserialized.targetCompanies, equals(['Amazon', 'Adobe']));
      },
    );
  });

  group('ResponsiveScaffold Sidebar Navigation Widget Tests', () {
    testWidgets(
      'Renders all primary navigation items and Settings on desktop',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final router = GoRouter(
          initialLocation: '/dashboard',
          routes: [
            ShellRoute(
              builder: (context, state, child) =>
                  ResponsiveScaffold(child: child),
              routes: [
                GoRoute(
                  path: '/dashboard',
                  builder: (context, state) => const Text('Dashboard Content'),
                ),
                GoRoute(
                  path: '/settings',
                  builder: (context, state) => const Text('Settings Content'),
                ),
                GoRoute(
                  path: '/coding-problems',
                  builder: (context, state) => const Text('Coding Content'),
                ),
                GoRoute(
                  path: '/aptitude',
                  builder: (context, state) => const Text('Aptitude Content'),
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Practice'), findsOneWidget);
        expect(find.text('Interviews'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);

        // Tap Practice to expand
        await tester.tap(find.text('Practice'));
        await tester.pumpAndSettle();

        expect(find.text('Coding'), findsOneWidget);
        expect(find.text('Aptitude'), findsOneWidget);

        // Tap Settings
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        expect(find.text('Settings Content'), findsOneWidget);
      },
    );
  });
}
