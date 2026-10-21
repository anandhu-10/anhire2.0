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
      'Renders primary navigation, avatar dropdown, and bottom sidebar logout',
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
                GoRoute(
                  path: '/interviews',
                  builder: (context, state) => const Text('Interviews Content'),
                ),
                GoRoute(
                  path: '/roadmap',
                  builder: (context, state) => const Text('Roadmap Content'),
                ),
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const Text('Profile Content'),
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // 1. Primary navigation in sidebar
        expect(find.text('Dashboard'), findsWidgets);
        expect(find.text('Practice'), findsOneWidget);
        expect(find.text('Interviews'), findsOneWidget);
        expect(find.text('Learning Roadmap'), findsOneWidget);
        expect(find.text('Logout'), findsOneWidget);

        // Profile and Settings are NOT in the primary sidebar
        // (they will only appear when avatar dropdown is opened)
        expect(find.text('Settings Content'), findsNothing);

        // 2. Expand Practice module
        await tester.tap(find.text('Practice'));
        await tester.pumpAndSettle();

        expect(find.text('Coding'), findsOneWidget);
        expect(find.text('Aptitude'), findsOneWidget);

        // 3. Right-side Header Controls: Search -> Notifications -> Theme Toggle -> Profile Avatar
        final searchBtn = find.byKey(const ValueKey('header_search_button'));
        final notificationBtn = find.byKey(
          const ValueKey('header_notification_button'),
        );
        final themeToggleBtn = find.byKey(
          const ValueKey('header_theme_toggle_button'),
        );
        final avatarBtn = find.byKey(
          const ValueKey('profile_avatar_dropdown_button'),
        );

        expect(searchBtn, findsOneWidget);
        expect(notificationBtn, findsOneWidget);
        expect(themeToggleBtn, findsOneWidget);
        expect(avatarBtn, findsOneWidget);

        // Verify exact left-to-right order: [ Search ] [ Notifications ] [ Theme Toggle ] [ Profile Avatar ]
        final searchX = tester.getTopLeft(searchBtn).dx;
        final notifX = tester.getTopLeft(notificationBtn).dx;
        final themeX = tester.getTopLeft(themeToggleBtn).dx;
        final avatarX = tester.getTopLeft(avatarBtn).dx;

        expect(
          searchX < notifX,
          isTrue,
          reason: 'Search must be immediately to the left of Notifications',
        );
        expect(
          notifX < themeX,
          isTrue,
          reason:
              'Notifications must be immediately to the left of Theme Toggle',
        );
        expect(
          themeX < avatarX,
          isTrue,
          reason:
              'Theme Toggle must be immediately to the left of Profile Avatar',
        );

        // Test Search Dialog opens
        await tester.tap(searchBtn);
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
        // Dismiss search dialog
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        // Test Notification Dialog opens
        await tester.tap(notificationBtn);
        await tester.pumpAndSettle();
        expect(find.text('Practice Notifications'), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        // Test Theme Toggle tap
        await tester.tap(themeToggleBtn);
        await tester.pumpAndSettle();

        // Test Profile Avatar dropdown opens
        await tester.tap(avatarBtn);
        await tester.pumpAndSettle();

        // Check avatar dropdown contents
        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('Leaderboard'), findsOneWidget);
        expect(find.text('Submissions'), findsOneWidget);
        expect(find.text('Bookmarks'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);

        // 4. Tap Settings in avatar dropdown -> navigates to /settings
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        expect(find.text('Settings Content'), findsOneWidget);

        // 5. Test Logout Confirmation Dialog from sidebar
        final logoutFinder = find.text('Logout');
        expect(logoutFinder, findsOneWidget);
        await tester.tap(logoutFinder);
        await tester.pumpAndSettle();

        expect(find.text('Confirm Sign Out'), findsOneWidget);
        expect(find.text('Sign Out'), findsOneWidget);

        // Dismiss dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm Sign Out'), findsNothing);

        // 6. Test Sidebar Toggle button (collapses sidebar to icon-only mode)
        final toggleBtn = find.byKey(
          const ValueKey('sidebar_menu_toggle_button'),
        );
        expect(toggleBtn, findsOneWidget);
        await tester.tap(toggleBtn);
        await tester.pumpAndSettle();

        // In collapsed mode, expanded labels are no longer visible in sidebar
        // Tooltip widgets are present for collapsed icons
        expect(find.byTooltip('Dashboard'), findsOneWidget);
        expect(find.byTooltip('Practice (Coding & Aptitude)'), findsOneWidget);
        expect(find.byTooltip('Interviews'), findsOneWidget);
        expect(find.byTooltip('Learning Roadmap'), findsOneWidget);
        expect(find.byTooltip('Logout'), findsOneWidget);

        // Tap Practice in collapsed mode to open its popup menu
        final collapsedPracticeFinder = find.byTooltip(
          'Practice (Coding & Aptitude)',
        );
        await tester.tap(collapsedPracticeFinder);
        await tester.pumpAndSettle();

        expect(find.text('Coding Problems'), findsOneWidget);
        expect(find.text('Aptitude Practice'), findsOneWidget);

        // Tap Coding Problems in the collapsed menu -> navigates to /coding-problems
        await tester.tap(find.text('Coding Problems'));
        await tester.pumpAndSettle();
        expect(find.text('Coding Content'), findsOneWidget);
      },
    );

    testWidgets(
      'ResponsiveScaffold adapts to mobile screen with drawer and bottom navigation',
      (tester) async {
        // Set mobile viewport
        tester.view.physicalSize = const Size(390, 844);
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
                  path: '/interviews',
                  builder: (context, state) => const Text('Interviews Content'),
                ),
                GoRoute(
                  path: '/roadmap',
                  builder: (context, state) => const Text('Roadmap Content'),
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // 1. Mobile bottom navigation bar contains Dashboard, Practice, Interviews, Roadmap
        expect(find.text('Dashboard'), findsWidgets);
        expect(find.text('Practice'), findsOneWidget);
        expect(find.text('Interviews'), findsOneWidget);
        expect(find.text('Roadmap'), findsOneWidget);

        // 2. Profile Avatar in mobile top bar has Log Out included in dropdown
        final avatarBtn = find.byKey(
          const ValueKey('profile_avatar_dropdown_button'),
        );
        expect(avatarBtn, findsOneWidget);

        await tester.tap(avatarBtn);
        await tester.pumpAndSettle();

        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('Leaderboard'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Log Out'), findsOneWidget);

        // Close dropdown
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // 3. Open Mobile Navigation Drawer via hamburger button
        final menuBtn = find.byKey(
          const ValueKey('sidebar_menu_toggle_button'),
        );
        await tester.tap(menuBtn);
        await tester.pumpAndSettle();

        // Drawer is now open with full primary navigation and Logout
        expect(find.text('Learning Roadmap'), findsOneWidget);
        expect(find.text('Logout'), findsOneWidget);
      },
    );
  });
}
