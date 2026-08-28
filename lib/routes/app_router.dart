import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/intro/profile_setup_screen.dart';
import '../screens/student/dashboard_screen.dart';
import '../screens/student/practice_hub_screen.dart';
import '../screens/student/coding_problems_screen.dart';
import '../screens/student/coding_playground_screen.dart';
import '../screens/student/aptitude_screen.dart';
import '../screens/student/mock_interview_screen.dart';
import '../screens/student/resume_report_screen.dart';
import '../screens/student/roadmap_screen.dart';
import '../screens/student/profile_screen.dart';
import '../widgets/responsive_scaffold.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(
      authStateProvider,
      (previous, next) => notifyListeners(),
    );
    _ref.listen(
      profileProvider,
      (previous, next) => notifyListeners(),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);
      final profileState = ref.read(profileProvider);

      final isAuthLoading = authState.isLoading;
      final isProfileLoading = profileState.isLoading;

      if (isAuthLoading || isProfileLoading) {
        return state.uri.path == '/splash' ? null : '/splash';
      }

      final user = authState.value;
      final profile = profileState.value;

      final isLoggingIn = state.uri.path == '/login' ||
          state.uri.path == '/signup' ||
          state.uri.path == '/forgot-password';
      final isSplash = state.uri.path == '/splash';

      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      if (profile == null) {
        return state.uri.path == '/profile-setup' ? null : '/profile-setup';
      }

      if (isLoggingIn || isSplash) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          final initialEmail = state.uri.queryParameters['email'];
          return ForgotPasswordScreen(initialEmail: initialEmail);
        },
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ResponsiveScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/practice',
            builder: (context, state) => const PracticeHubScreen(),
          ),
          GoRoute(
            path: '/coding-problems',
            builder: (context, state) => const CodingProblemsScreen(),
          ),
          GoRoute(
            path: '/coding-playground/:problemId',
            builder: (context, state) => CodingPlaygroundScreen(
              problemId: state.pathParameters['problemId'] ?? 'two-sum',
            ),
          ),
          GoRoute(
            path: '/aptitude',
            builder: (context, state) => const AptitudeScreen(),
          ),
          GoRoute(
            path: '/interviews',
            builder: (context, state) => const MockInterviewScreen(),
          ),
          GoRoute(
            path: '/resume-report',
            builder: (context, state) => const ResumeReportScreen(),
          ),
          GoRoute(
            path: '/roadmap',
            builder: (context, state) => const RoadmapScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
