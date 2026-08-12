import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/intro/profile_setup_screen.dart';
import '../screens/student/dashboard_screen.dart';
import '../screens/student/practice_hub_screen.dart';
import '../screens/student/mock_interview_screen.dart';
import '../screens/student/profile_screen.dart';
import '../widgets/responsive_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileState = ref.watch(profileProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthLoading = authState.isLoading;
      final isProfileLoading = profileState.isLoading;

      if (isAuthLoading || isProfileLoading) return null;

      final user = authState.value;
      final profile = profileState.value;

      final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/signup';

      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      if (profile == null) {
        // User logged in but no profile yet
        return state.uri.path == '/profile-setup' ? null : '/profile-setup';
      }

      // User is logged in and has a profile
      if (isLoggingIn || state.uri.path == '/profile-setup') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
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
            path: '/interviews',
            builder: (context, state) => const MockInterviewScreen(),
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
