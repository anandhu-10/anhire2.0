import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../core/constants/app_colors.dart';

import 'app_logo_widget.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget child;

  const ResponsiveScaffold({Key? key, required this.child}) : super(key: key);

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/practice') ||
        location.startsWith('/coding') ||
        location.startsWith('/aptitude')) return 1;
    if (location.startsWith('/interviews')) return 2;
    if (location.startsWith('/profile') || location.startsWith('/resume-report') || location.startsWith('/roadmap')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/practice');
        break;
      case 2:
        context.go('/interviews');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= AppBreakpoints.mediumBreakpoint; // >= 1024px

    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined, color: Colors.grey),
        selectedIcon: Icon(Icons.dashboard, color: AppColors.accentPurple),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.code_outlined, color: Colors.grey),
        selectedIcon: Icon(Icons.code, color: AppColors.accentPurple),
        label: 'Practice',
      ),
      NavigationDestination(
        icon: Icon(Icons.video_call_outlined, color: Colors.grey),
        selectedIcon: Icon(Icons.video_call, color: AppColors.accentPurple),
        label: 'Interviews',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline, color: Colors.grey),
        selectedIcon: Icon(Icons.person, color: AppColors.accentPurple),
        label: 'Profile',
      ),
    ];

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: true,
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _onItemTapped(index, context),
              indicatorColor: AppColors.bgLavender,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: AppLogoWidget(size: 36, textSize: 18),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined, color: Colors.grey),
                  selectedIcon: Icon(Icons.dashboard, color: AppColors.accentPurple),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.code_outlined, color: Colors.grey),
                  selectedIcon: Icon(Icons.code, color: AppColors.accentPurple),
                  label: Text('Practice'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.video_call_outlined, color: Colors.grey),
                  selectedIcon: Icon(Icons.video_call, color: AppColors.accentPurple),
                  label: Text('Interviews'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline, color: Colors.grey),
                  selectedIcon: Icon(Icons.person, color: AppColors.accentPurple),
                  label: Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        height: AppBreakpoints.minTouchTarget + 16,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(index, context),
        indicatorColor: AppColors.bgLavender,
        destinations: destinations,
      ),
    );
  }
}
