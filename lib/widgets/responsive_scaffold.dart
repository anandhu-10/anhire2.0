import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';

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
    final theme = Theme.of(context);

    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined, color: Colors.grey),
        selectedIcon: Icon(Icons.dashboard, color: Color(0xFF6750A4)),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.code_outlined, color: Colors.grey),
        selectedIcon: Icon(Icons.code, color: Color(0xFF6750A4)),
        label: 'Practice',
      ),
      NavigationDestination(
        icon: Icon(Icons.video_call_outlined, color: Colors.grey),
        selectedIcon: Icon(Icons.video_call, color: Color(0xFF6750A4)),
        label: 'Interviews',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline, color: Colors.grey),
        selectedIcon: Icon(Icons.person, color: Color(0xFF6750A4)),
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
              indicatorColor: const Color(0xFFEADDFF),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ANHIRE',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined, color: Colors.grey),
                  selectedIcon: Icon(Icons.dashboard, color: Color(0xFF6750A4)),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.code_outlined, color: Colors.grey),
                  selectedIcon: Icon(Icons.code, color: Color(0xFF6750A4)),
                  label: Text('Practice'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.video_call_outlined, color: Colors.grey),
                  selectedIcon: Icon(Icons.video_call, color: Color(0xFF6750A4)),
                  label: Text('Interviews'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline, color: Colors.grey),
                  selectedIcon: Icon(Icons.person, color: Color(0xFF6750A4)),
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
        indicatorColor: const Color(0xFFEADDFF),
        destinations: destinations,
      ),
    );
  }
}
