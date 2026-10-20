import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../core/constants/app_colors.dart';
import 'app_logo_widget.dart';

class ResponsiveScaffold extends StatefulWidget {
  final Widget child;

  const ResponsiveScaffold({super.key, required this.child});

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  bool _isPracticeExpanded = false;
  String _lastRoute = '';

  String _getCurrentPath(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.path;
    } catch (_) {
      return '';
    }
  }

  bool _isDashboardActive(String path) =>
      path == '/dashboard' || path.startsWith('/dashboard/');
  bool _isCodingActive(String path) =>
      path.startsWith('/coding-problems') ||
      path.startsWith('/coding-playground');
  bool _isAptitudeActive(String path) => path.startsWith('/aptitude');
  bool _isPracticeActive(String path) =>
      path.startsWith('/practice') ||
      _isCodingActive(path) ||
      _isAptitudeActive(path);
  bool _isInterviewsActive(String path) =>
      path.startsWith('/interviews') ||
      path.startsWith('/mock-interview') ||
      path.startsWith('/interview-runner') ||
      path.startsWith('/interview-results');
  bool _isProfileActive(String path) =>
      path.startsWith('/profile') ||
      path.startsWith('/resume-report') ||
      path.startsWith('/roadmap') ||
      path.startsWith('/leaderboard');
  bool _isSettingsActive(String path) => path.startsWith('/settings');

  int _calculateMobileSelectedIndex(String path) {
    if (_isDashboardActive(path)) return 0;
    if (_isPracticeActive(path)) return 1;
    if (_isInterviewsActive(path)) return 2;
    if (_isProfileActive(path)) return 3;
    if (_isSettingsActive(path)) return 4;
    return 0;
  }

  void _onMobileItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        _showMobilePracticeSheet(context);
        break;
      case 2:
        context.go('/interviews');
        break;
      case 3:
        context.go('/profile');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  void _showMobilePracticeSheet(BuildContext context) {
    final currentPath = _getCurrentPath(context);
    final isCoding = _isCodingActive(currentPath);
    final isAptitude = _isAptitudeActive(currentPath);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Practice Hub',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select a module to prepare for campus recruitment',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCoding
                          ? AppColors.accentPurple
                          : AppColors.bgSurfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.terminal_rounded,
                      color: Colors.white,
                    ),
                  ),
                  title: const Text(
                    'Coding Problems',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Python & Java algorithmic challenges with testcases',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  trailing: isCoding
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.accentPurpleLight,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/coding-problems');
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isAptitude
                          ? AppColors.accentPurple
                          : AppColors.bgSurfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.psychology_outlined,
                      color: Colors.white,
                    ),
                  ),
                  title: const Text(
                    'Aptitude Assessments',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Quantitative, logical reasoning, and verbal tests',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  trailing: isAptitude
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.accentPurpleLight,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/aptitude');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = _getCurrentPath(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= AppBreakpoints.mediumBreakpoint; // >= 1024px

    // Auto-expand Practice when navigating into coding or aptitude routes
    if (path != _lastRoute) {
      _lastRoute = path;
      if (_isCodingActive(path) ||
          _isAptitudeActive(path) ||
          path.startsWith('/practice')) {
        _isPracticeExpanded = true;
      }
    }

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.bgRoot,
        body: Row(
          children: [
            // Custom ANHIRE Desktop Sidebar
            _buildDesktopSidebar(context, path),
            const VerticalDivider(
              thickness: 1,
              width: 1,
              color: AppColors.borderSubtle,
            ),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    // Mobile / Tablet Navigation
    final mobileIndex = _calculateMobileSelectedIndex(path);

    const mobileDestinations = [
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
      NavigationDestination(
        icon: Icon(Icons.settings_outlined, color: Colors.grey),
        selectedIcon: Icon(Icons.settings, color: AppColors.accentPurple),
        label: 'Settings',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgRoot,
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        height: AppBreakpoints.minTouchTarget + 16,
        selectedIndex: mobileIndex,
        onDestinationSelected: (index) => _onMobileItemTapped(index, context),
        indicatorColor: AppColors.bgLavender,
        destinations: mobileDestinations,
      ),
    );
  }

  // ===========================================================================
  // DESKTOP SIDEBAR
  // ===========================================================================
  Widget _buildDesktopSidebar(BuildContext context, String path) {
    final isDashboardActive = _isDashboardActive(path);
    final isCodingActive = _isCodingActive(path);
    final isAptitudeActive = _isAptitudeActive(path);
    final isPracticeActive = _isPracticeActive(path);
    final isInterviewsActive = _isInterviewsActive(path);
    final isProfileActive = _isProfileActive(path);
    final isSettingsActive = _isSettingsActive(path);

    return Container(
      width: 256,
      color: AppColors.bgDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: AppLogoWidget(size: 36, textSize: 18),
          ),

          // Scrollable Primary Navigation Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Dashboard
                  _SidebarNavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Dashboard',
                    isActive: isDashboardActive,
                    onTap: () => context.go('/dashboard'),
                  ),
                  const SizedBox(height: 4),

                  // 2. Practice (Expandable)
                  _SidebarNavItem(
                    icon: Icons.code_outlined,
                    activeIcon: Icons.code,
                    label: 'Practice',
                    isActive:
                        isPracticeActive &&
                        !isCodingActive &&
                        !isAptitudeActive,
                    trailing: AnimatedRotation(
                      turns: _isPracticeExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _isPracticeExpanded = !_isPracticeExpanded;
                      });
                    },
                  ),

                  // Submenu Items: Coding & Aptitude
                  AnimatedCrossFade(
                    firstChild: Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SidebarSubmenuItem(
                            icon: Icons.terminal_rounded,
                            label: 'Coding',
                            isActive: isCodingActive,
                            onTap: () => context.go('/coding-problems'),
                          ),
                          const SizedBox(height: 2),
                          _SidebarSubmenuItem(
                            icon: Icons.psychology_outlined,
                            label: 'Aptitude',
                            isActive: isAptitudeActive,
                            onTap: () => context.go('/aptitude'),
                          ),
                        ],
                      ),
                    ),
                    secondChild: const SizedBox.shrink(),
                    crossFadeState: _isPracticeExpanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 220),
                    sizeCurve: Curves.easeInOutCubic,
                  ),
                  const SizedBox(height: 4),

                  // 3. Interviews
                  _SidebarNavItem(
                    icon: Icons.video_call_outlined,
                    activeIcon: Icons.video_call,
                    label: 'Interviews',
                    isActive: isInterviewsActive,
                    onTap: () => context.go('/interviews'),
                  ),
                  const SizedBox(height: 4),

                  // 4. Profile
                  _SidebarNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    isActive: isProfileActive,
                    onTap: () => context.go('/profile'),
                  ),
                ],
              ),
            ),
          ),

          // Pinned Bottom Area with Subtle Divider & Settings
          const Divider(
            color: AppColors.borderSubtle,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: _SidebarNavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'Settings',
              isActive: isSettingsActive,
              onTap: () => context.go('/settings'),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// REUSABLE SIDEBAR NAV ITEM (WITH HOVER & ACTIVE STYLING)
// =============================================================================
class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SidebarNavItem({
    super.key,
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.trailing,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final iconToUse = widget.isActive && widget.activeIcon != null
        ? widget.activeIcon!
        : widget.icon;

    Color bg = Colors.transparent;
    Color textColor = AppColors.textSecondary;
    Color iconColor = Colors.grey;

    if (widget.isActive) {
      bg = AppColors.accentPurple.withOpacity(0.22);
      textColor = AppColors.accentPurpleLight;
      iconColor = AppColors.accentPurpleLight;
    } else if (_isHovered) {
      bg = AppColors.bgSurfaceAlt;
      textColor = AppColors.textPrimary;
      iconColor = AppColors.textPrimary;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.label,
        waitDuration: const Duration(milliseconds: 700),
        child: Semantics(
          label: widget.label,
          selected: widget.isActive,
          button: true,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            splashColor: AppColors.accentPurple.withOpacity(0.15),
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: widget.isActive
                    ? Border.all(
                        color: AppColors.accentPurple.withOpacity(0.4),
                        width: 1.0,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(iconToUse, color: iconColor, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: widget.isActive
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SUBMENU ITEM (FOR CODING & APTITUDE UNDER PRACTICE)
// =============================================================================
class _SidebarSubmenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarSubmenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SidebarSubmenuItem> createState() => _SidebarSubmenuItemState();
}

class _SidebarSubmenuItemState extends State<_SidebarSubmenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.transparent;
    Color textColor = AppColors.textMuted;
    Color iconColor = AppColors.textMuted;

    if (widget.isActive) {
      bg = AppColors.accentPurple.withOpacity(0.2);
      textColor = AppColors.accentPurpleLight;
      iconColor = AppColors.accentPurpleLight;
    } else if (_isHovered) {
      bg = AppColors.bgSurfaceAlt.withOpacity(0.6);
      textColor = AppColors.textPrimary;
      iconColor = AppColors.textPrimary;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Tooltip(
          message: widget.label,
          waitDuration: const Duration(milliseconds: 700),
          child: Semantics(
            label: widget.label,
            selected: widget.isActive,
            button: true,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(8),
              splashColor: AppColors.accentPurple.withOpacity(0.12),
              highlightColor: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: widget.isActive
                      ? Border.all(
                          color: AppColors.accentPurple.withOpacity(0.35),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, color: iconColor, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: widget.isActive
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
