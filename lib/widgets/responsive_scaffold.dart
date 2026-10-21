import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';
import '../core/constants/app_colors.dart';
import '../models/coding_problem_model.dart';
import '../models/profile_model.dart';
import '../providers/auth_provider.dart';
import '../providers/coding_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../repositories/auth_repository.dart';
import 'app_logo_widget.dart';

/// Represents the three states of the left navigation sidebar.
enum SidebarState { expanded, collapsed, hidden }

class ResponsiveScaffold extends StatefulWidget {
  final Widget child;

  const ResponsiveScaffold({super.key, required this.child});

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  SidebarState _sidebarState = SidebarState.expanded;
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

  bool _isRoadmapActive(String path) => path.startsWith('/roadmap');

  String _getPageTitle(String path) {
    if (_isDashboardActive(path)) return 'Dashboard';
    if (_isCodingActive(path)) return 'Coding Problems';
    if (_isAptitudeActive(path)) return 'Aptitude Practice';
    if (path.startsWith('/practice')) return 'Practice Hub';
    if (_isInterviewsActive(path)) return 'Interviews';
    if (_isRoadmapActive(path)) return 'Learning Roadmap';
    if (path.startsWith('/profile')) return 'Profile';
    if (path.startsWith('/leaderboard')) return 'Leaderboard';
    if (path.startsWith('/settings')) return 'Settings';
    if (path.startsWith('/resume-report')) return 'Resume Analysis';
    return 'ANHIRE';
  }

  int _calculateMobileSelectedIndex(String path) {
    if (_isDashboardActive(path)) return 0;
    if (_isPracticeActive(path)) return 1;
    if (_isInterviewsActive(path)) return 2;
    if (_isRoadmapActive(path)) return 3;
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
        context.go('/roadmap');
        break;
    }
  }

  void _showMobilePracticeSheet(BuildContext context) {
    final currentPath = _getCurrentPath(context);
    final isCoding = _isCodingActive(currentPath);
    final isAptitude = _isAptitudeActive(currentPath);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? const Color(0xFF15151E)
          : const Color(0xFFFFFFFF),
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
                      color: isDark
                          ? const Color(0xFF292938)
                          : const Color(0xFFE5E4EF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Practice Hub',
                  style: GoogleFonts.inter(
                    color: isDark
                        ? const Color(0xFFF5F5FA)
                        : const Color(0xFF191927),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a practice module to sharpen your placement skills',
                  style: GoogleFonts.inter(
                    color: isDark
                        ? const Color(0xFFA1A1B5)
                        : const Color(0xFF626277),
                    fontSize: 13,
                  ),
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
                          ? AppColors.primary
                          : (isDark
                                ? const Color(0xFF1B1B27)
                                : const Color(0xFFF0EFF8)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.terminal_rounded,
                      color: isCoding
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFFA1A1B5)
                                : const Color(0xFF626277)),
                    ),
                  ),
                  title: Text(
                    'Coding Problems',
                    style: GoogleFonts.inter(
                      color: isDark
                          ? const Color(0xFFF5F5FA)
                          : const Color(0xFF191927),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Algorithmic challenges with testcases & runner',
                    style: GoogleFonts.inter(
                      color: isDark
                          ? const Color(0xFFA1A1B5)
                          : const Color(0xFF626277),
                      fontSize: 12,
                    ),
                  ),
                  trailing: isCoding
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
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
                          ? AppColors.primary
                          : (isDark
                                ? const Color(0xFF1B1B27)
                                : const Color(0xFFF0EFF8)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.psychology_outlined,
                      color: isAptitude
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFFA1A1B5)
                                : const Color(0xFF626277)),
                    ),
                  ),
                  title: Text(
                    'Aptitude Assessments',
                    style: GoogleFonts.inter(
                      color: isDark
                          ? const Color(0xFFF5F5FA)
                          : const Color(0xFF191927),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Quantitative, logical reasoning, and verbal tests',
                    style: GoogleFonts.inter(
                      color: isDark
                          ? const Color(0xFFA1A1B5)
                          : const Color(0xFF626277),
                      fontSize: 12,
                    ),
                  ),
                  trailing: isAptitude
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
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

  void _showLogoutConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? const Color(0xFF15151E)
            : const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF292938) : const Color(0xFFE5E4EF),
            width: 1,
          ),
        ),
        title: Text(
          'Confirm Sign Out',
          style: GoogleFonts.inter(
            color: isDark ? const Color(0xFFF5F5FA) : const Color(0xFF191927),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of ANHIRE 2.0? Any unsaved coding drafts in your current editor will be saved locally.',
          style: GoogleFonts.inter(
            color: isDark ? const Color(0xFFA1A1B5) : const Color(0xFF626277),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: isDark
                    ? const Color(0xFF77778D)
                    : const Color(0xFF85859A),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleSignOut(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      try {
        await container.read(authRepositoryProvider).signOut();
      } catch (_) {}
      container.invalidate(authStateProvider);
      container.invalidate(profileProvider);
      if (context.mounted) {
        context.go('/login');
      }
    } catch (_) {
      try {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          context.go('/login');
        }
      } catch (_) {}
    }
  }

  double _getSidebarWidth() {
    switch (_sidebarState) {
      case SidebarState.expanded:
        return 256.0;
      case SidebarState.collapsed:
        return 72.0;
      case SidebarState.hidden:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = _getCurrentPath(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 768.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rootBg = isDark ? const Color(0xFF0B0B10) : const Color(0xFFF7F7FC);
    final sidebarBg = isDark
        ? const Color(0xFF101016)
        : const Color(0xFFFFFFFF);
    final borderSubtle = isDark
        ? const Color(0xFF292938)
        : const Color(0xFFE5E4EF);

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
      final sidebarWidth = _getSidebarWidth();

      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: rootBg,
        body: Row(
          children: [
            // Smoothly animated left sidebar
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOutCubic,
              width: sidebarWidth,
              child: sidebarWidth == 0
                  ? const SizedBox.shrink()
                  : ClipRect(
                      child: OverflowBox(
                        minWidth: _sidebarState == SidebarState.collapsed
                            ? 72
                            : 256,
                        maxWidth: _sidebarState == SidebarState.collapsed
                            ? 72
                            : 256,
                        alignment: Alignment.topLeft,
                        child: _sidebarState == SidebarState.collapsed
                            ? _buildCollapsedSidebar(
                                context,
                                path,
                                isDark,
                                borderSubtle,
                              )
                            : _buildExpandedSidebar(
                                context,
                                path,
                                isDark,
                                borderSubtle,
                              ),
                      ),
                    ),
            ),
            if (sidebarWidth > 0)
              VerticalDivider(thickness: 1, width: 1, color: borderSubtle),
            // Main content column with unified Top Bar
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(
                    context,
                    path: path,
                    isDesktop: true,
                    isDark: isDark,
                    borderSubtle: borderSubtle,
                  ),
                  Divider(height: 1, thickness: 1, color: borderSubtle),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile Navigation (< 768px)
    final mobileIndex = _calculateMobileSelectedIndex(path);

    final mobileDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.code_outlined),
        selectedIcon: Icon(Icons.code, color: AppColors.primary),
        label: 'Practice',
      ),
      const NavigationDestination(
        icon: Icon(Icons.video_call_outlined),
        selectedIcon: Icon(Icons.video_call, color: AppColors.primary),
        label: 'Interviews',
      ),
      const NavigationDestination(
        icon: Icon(Icons.map_outlined),
        selectedIcon: Icon(Icons.map, color: AppColors.primary),
        label: 'Roadmap',
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: rootBg,
      drawer: Drawer(
        backgroundColor: sidebarBg,
        child: SafeArea(
          child: _buildExpandedSidebar(
            context,
            path,
            isDark,
            borderSubtle,
            isDrawer: true,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTopBar(
            context,
            path: path,
            isDesktop: false,
            isDark: isDark,
            borderSubtle: borderSubtle,
          ),
          Divider(height: 1, thickness: 1, color: borderSubtle),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: AppBreakpoints.minTouchTarget + 16,
        selectedIndex: mobileIndex,
        onDestinationSelected: (index) => _onMobileItemTapped(index, context),
        destinations: mobileDestinations,
      ),
    );
  }

  // ===========================================================================
  // TOP BAR (WITH MENU TOGGLE, BREADCRUMB, & PROFILE AVATAR DROPDOWN)
  // ===========================================================================
  Widget _buildTopBar(
    BuildContext context, {
    required String path,
    required bool isDesktop,
    required bool isDark,
    required Color borderSubtle,
  }) {
    final topBarBg = isDark ? const Color(0xFF101016) : const Color(0xFFFFFFFF);

    return Container(
      height: 56,
      color: topBarBg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Menu button (Restores / expands / collapses sidebar or opens drawer)
          IconButton(
            key: const ValueKey('sidebar_menu_toggle_button'),
            icon: Icon(
              isDesktop
                  ? (_sidebarState == SidebarState.hidden
                        ? Icons.menu_rounded
                        : (_sidebarState == SidebarState.collapsed
                              ? Icons.menu_open_rounded
                              : Icons.menu_rounded))
                  : Icons.menu_rounded,
              size: 22,
              color: isDark ? const Color(0xFFF5F5FA) : const Color(0xFF191927),
            ),
            tooltip: isDesktop
                ? (_sidebarState == SidebarState.hidden
                      ? 'Restore sidebar'
                      : (_sidebarState == SidebarState.collapsed
                            ? 'Expand sidebar'
                            : 'Collapse sidebar'))
                : 'Open menu',
            onPressed: () {
              if (isDesktop) {
                setState(() {
                  if (_sidebarState == SidebarState.hidden) {
                    _sidebarState = SidebarState.expanded;
                  } else if (_sidebarState == SidebarState.collapsed) {
                    _sidebarState = SidebarState.expanded;
                  } else {
                    _sidebarState = SidebarState.collapsed;
                  }
                });
              } else {
                _scaffoldKey.currentState?.openDrawer();
              }
            },
          ),
          const SizedBox(width: 8),

          // Route title / branding context
          Expanded(
            child: Row(
              children: [
                if (!isDesktop) ...[
                  const AppLogoWidget(size: 24, showText: false),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    _getPageTitle(path),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFF5F5FA)
                          : const Color(0xFF191927),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 1. Search bar or search icon
          _HeaderSearchWidget(
            isDesktop: isDesktop,
            isDark: isDark,
            borderSubtle: borderSubtle,
          ),
          const SizedBox(width: 6),

          // 2. Notification bell icon
          _HeaderNotificationBell(isDark: isDark, borderSubtle: borderSubtle),
          const SizedBox(width: 6),

          // 3. Dark/Light theme toggle
          _HeaderThemeToggle(isDark: isDark, borderSubtle: borderSubtle),
          const SizedBox(width: 8),

          // 4. Existing Profile Avatar Dropdown
          _ProfileAvatarDropdown(
            isDark: isDark,
            borderSubtle: borderSubtle,
            showLogoutInDropdown:
                _sidebarState == SidebarState.hidden || !isDesktop,
            onLogoutPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // EXPANDED DESKTOP / DRAWER SIDEBAR
  // ===========================================================================
  Widget _buildExpandedSidebar(
    BuildContext context,
    String path,
    bool isDark,
    Color borderSubtle, {
    bool isDrawer = false,
  }) {
    final sidebarBg = isDark
        ? const Color(0xFF101016)
        : const Color(0xFFFFFFFF);

    final isDashboardActive = _isDashboardActive(path);
    final isCodingActive = _isCodingActive(path);
    final isAptitudeActive = _isAptitudeActive(path);
    final isPracticeActive = _isPracticeActive(path);
    final isInterviewsActive = _isInterviewsActive(path);
    final isRoadmapActive = _isRoadmapActive(path);

    void navigate(String route) {
      if (isDrawer) {
        Navigator.pop(context);
      }
      context.go(route);
    }

    return Container(
      width: 256,
      color: sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: AppLogoWidget(size: 32, textSize: 17),
          ),

          // Primary Navigation Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel(context, 'PRIMARY NAVIGATION'),
                  const SizedBox(height: 6),

                  // 1. Dashboard
                  _SidebarNavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Dashboard',
                    isActive: isDashboardActive,
                    onTap: () => navigate('/dashboard'),
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
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: isDark
                            ? const Color(0xFF77778D)
                            : const Color(0xFF85859A),
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
                            onTap: () => navigate('/coding-problems'),
                          ),
                          const SizedBox(height: 2),
                          _SidebarSubmenuItem(
                            icon: Icons.psychology_outlined,
                            label: 'Aptitude',
                            isActive: isAptitudeActive,
                            onTap: () => navigate('/aptitude'),
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
                    onTap: () => navigate('/interviews'),
                  ),
                  const SizedBox(height: 4),

                  // 4. Learning Roadmap
                  _SidebarNavItem(
                    icon: Icons.map_outlined,
                    activeIcon: Icons.map,
                    label: 'Learning Roadmap',
                    isActive: isRoadmapActive,
                    onTap: () => navigate('/roadmap'),
                  ),
                ],
              ),
            ),
          ),

          // Pinned Bottom Area with Subtle Divider & Logout
          Divider(color: borderSubtle, height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: _SidebarLogoutItem(
              isCollapsed: false,
              onTap: () {
                if (isDrawer) Navigator.pop(context);
                _showLogoutConfirmation(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // COLLAPSED ICON-ONLY SIDEBAR
  // ===========================================================================
  Widget _buildCollapsedSidebar(
    BuildContext context,
    String path,
    bool isDark,
    Color borderSubtle,
  ) {
    final sidebarBg = isDark
        ? const Color(0xFF101016)
        : const Color(0xFFFFFFFF);

    final isDashboardActive = _isDashboardActive(path);
    final isPracticeActive = _isPracticeActive(path);
    final isInterviewsActive = _isInterviewsActive(path);
    final isRoadmapActive = _isRoadmapActive(path);

    return Container(
      width: 72,
      color: sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mini Logo (tapping expands sidebar)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Tooltip(
              message: 'Expand sidebar',
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () =>
                    setState(() => _sidebarState = SidebarState.expanded),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          Divider(color: borderSubtle, height: 1, indent: 12, endIndent: 12),
          const SizedBox(height: 8),

          // Icon-only navigation buttons with tooltips
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _CollapsedNavIconButton(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Dashboard',
                    isActive: isDashboardActive,
                    onTap: () => context.go('/dashboard'),
                  ),
                  _CollapsedPracticeButton(
                    icon: Icons.code_outlined,
                    activeIcon: Icons.code,
                    label: 'Practice',
                    isActive: isPracticeActive,
                    onCodingTap: () => context.go('/coding-problems'),
                    onAptitudeTap: () => context.go('/aptitude'),
                    onExpandSidebar: () {
                      setState(() {
                        _sidebarState = SidebarState.expanded;
                        _isPracticeExpanded = true;
                      });
                    },
                  ),
                  _CollapsedNavIconButton(
                    icon: Icons.video_call_outlined,
                    activeIcon: Icons.video_call,
                    label: 'Interviews',
                    isActive: isInterviewsActive,
                    onTap: () => context.go('/interviews'),
                  ),
                  _CollapsedNavIconButton(
                    icon: Icons.map_outlined,
                    activeIcon: Icons.map,
                    label: 'Learning Roadmap',
                    isActive: isRoadmapActive,
                    onTap: () => context.go('/roadmap'),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Divider & Collapsed Logout Icon Button
          Divider(color: borderSubtle, height: 1, indent: 12, endIndent: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _SidebarLogoutItem(
              isCollapsed: true,
              onTap: () => _showLogoutConfirmation(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF77778D) : const Color(0xFF85859A),
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// =============================================================================
// 1. HEADER SEARCH BAR / ICON & DIALOG
// =============================================================================
class _HeaderSearchWidget extends StatelessWidget {
  final bool isDesktop;
  final bool isDark;
  final Color borderSubtle;

  const _HeaderSearchWidget({
    required this.isDesktop,
    required this.isDark,
    required this.borderSubtle,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark
        ? const Color(0xFF77778D)
        : const Color(0xFF85859A);
    final bg = isDark ? const Color(0xFF181824) : const Color(0xFFF3F3F9);

    if (!isDesktop) {
      return Tooltip(
        message: 'Search problems & topics',
        child: InkWell(
          key: const ValueKey('header_search_button'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openSearchDialog(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderSubtle),
            ),
            child: Icon(Icons.search_rounded, size: 19, color: textMuted),
          ),
        ),
      );
    }

    return Tooltip(
      message: 'Search coding problems & topics',
      child: InkWell(
        key: const ValueKey('header_search_button'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openSearchDialog(context),
        child: Container(
          width: 170,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderSubtle),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 17, color: textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search problems...',
                  style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _SearchDialog(isDark: isDark, borderSubtle: borderSubtle),
    );
  }
}

class _SearchDialog extends StatefulWidget {
  final bool isDark;
  final Color borderSubtle;

  const _SearchDialog({required this.isDark, required this.borderSubtle});

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<CodingProblemModel> allProblems = [];
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      allProblems = container.read(codingProblemsProvider).value ?? [];
    } catch (_) {}

    final q = _query.trim().toLowerCase();
    final results = q.isEmpty
        ? allProblems.take(5).toList()
        : allProblems
              .where((p) {
                final matchTitle = p.title.toLowerCase().contains(q);
                final matchCategory = p.category.toLowerCase().contains(q);
                final matchDiff = p.difficulty.toLowerCase().contains(q);
                return matchTitle || matchCategory || matchDiff;
              })
              .take(8)
              .toList();

    final bg = widget.isDark ? const Color(0xFF15151E) : Colors.white;
    final textPrimary = widget.isDark
        ? const Color(0xFFF5F5FA)
        : const Color(0xFF191927);
    final textMuted = widget.isDark
        ? const Color(0xFF77778D)
        : const Color(0xFF85859A);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: widget.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Input
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (val) => setState(() => _query = val),
                style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search coding problems, algorithms, topics...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: textMuted),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: textMuted,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: textMuted,
                          ),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: widget.isDark
                      ? const Color(0xFF101016)
                      : const Color(0xFFF7F7FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Results Header
              Row(
                children: [
                  Text(
                    q.isEmpty
                        ? 'SUGGESTED PROBLEMS'
                        : 'RESULTS (${results.length})',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Results list
              Flexible(
                child: results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No problems found matching "$_query"',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (ctx, index) {
                          final prob = results[index];
                          Color diffColor = AppColors.success;
                          if (prob.difficulty.toLowerCase() == 'medium') {
                            diffColor = AppColors.warning;
                          }
                          if (prob.difficulty.toLowerCase() == 'hard') {
                            diffColor = AppColors.error;
                          }

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.code_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              prob.title,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              prob.category,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: textMuted,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: diffColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                prob.difficulty,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: diffColor,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.go('/coding-playground/${prob.id}');
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 2. HEADER NOTIFICATION BELL ICON & DIALOG
// =============================================================================
class _HeaderNotificationBell extends StatelessWidget {
  final bool isDark;
  final Color borderSubtle;

  const _HeaderNotificationBell({
    required this.isDark,
    required this.borderSubtle,
  });

  @override
  Widget build(BuildContext context) {
    bool hasReminder = true;
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      hasReminder = container.read(settingsProvider).dailyReminderEnabled;
    } catch (_) {}

    final textMuted = isDark
        ? const Color(0xFF77778D)
        : const Color(0xFF85859A);
    final bg = isDark ? const Color(0xFF181824) : const Color(0xFFF3F3F9);

    return Tooltip(
      message: 'Notifications & Reminders',
      child: InkWell(
        key: const ValueKey('header_notification_button'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openNotificationDialog(context),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderSubtle),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 19,
                color: textMuted,
              ),
              if (hasReminder)
                Positioned(
                  top: 7,
                  right: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _NotificationDialog(isDark: isDark, borderSubtle: borderSubtle),
    );
  }
}

class _NotificationDialog extends StatelessWidget {
  final bool isDark;
  final Color borderSubtle;

  const _NotificationDialog({required this.isDark, required this.borderSubtle});

  @override
  Widget build(BuildContext context) {
    SettingsState settings = const SettingsState();
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      settings = container.read(settingsProvider);
    } catch (_) {}

    final bg = isDark ? const Color(0xFF15151E) : Colors.white;
    final textPrimary =
        isDark ? const Color(0xFFF5F5FA) : const Color(0xFF191927);
    final textMuted =
        isDark ? const Color(0xFF77778D) : const Color(0xFF85859A);

    final hourStr = settings.dailyReminderHour.toString().padLeft(2, '0');
    final minuteStr = settings.dailyReminderMinute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minuteStr';

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderSubtle),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice Notifications',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Automated streak & daily study alerts',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: borderSubtle, height: 1),
              const SizedBox(height: 12),

              // Item 1: Daily Practice Reminder
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  settings.dailyReminderEnabled
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: settings.dailyReminderEnabled
                      ? AppColors.accent
                      : textMuted,
                  size: 20,
                ),
                title: Text(
                  'Daily Practice Reminder',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                subtitle: Text(
                  settings.dailyReminderEnabled
                      ? 'Active at $timeStr daily'
                      : 'Reminder is currently paused',
                  style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                ),
              ),

              // Item 2: Achievement Alerts
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  settings.achievementAlertsEnabled
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: settings.achievementAlertsEnabled
                      ? AppColors.accent
                      : textMuted,
                  size: 20,
                ),
                title: Text(
                  'Achievement & Streak Alerts',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                subtitle: Text(
                  settings.achievementAlertsEnabled
                      ? 'Enabled for milestone celebrations'
                      : 'Alerts paused',
                  style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                ),
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: GoogleFonts.inter(color: textMuted),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/settings');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Configure Settings'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 3. HEADER THEME TOGGLE
// =============================================================================
class _HeaderThemeToggle extends StatelessWidget {
  final bool isDark;
  final Color borderSubtle;

  const _HeaderThemeToggle({required this.isDark, required this.borderSubtle});

  @override
  Widget build(BuildContext context) {
    bool hasProviderScope = false;
    try {
      ProviderScope.containerOf(context, listen: false);
      hasProviderScope = true;
    } catch (_) {}

    if (hasProviderScope) {
      return Consumer(
        builder: (ctx, ref, _) {
          final settings = ref.watch(settingsProvider);
          final isCurrentlyDark =
              settings.themeMode == ThemeMode.dark ||
              (settings.themeMode == ThemeMode.system &&
                  Theme.of(ctx).brightness == Brightness.dark);
          return _buildToggle(ctx, isCurrentlyDark, () {
            ref
                .read(settingsProvider.notifier)
                .setThemeMode(
                  isCurrentlyDark ? ThemeMode.light : ThemeMode.dark,
                );
          });
        },
      );
    }

    return _buildToggle(context, isDark, () {});
  }

  Widget _buildToggle(
    BuildContext context,
    bool isCurrentlyDark,
    VoidCallback onTap,
  ) {
    final bg = isDark ? const Color(0xFF181824) : const Color(0xFFF3F3F9);
    final textPrimary = isDark
        ? const Color(0xFFF5F5FA)
        : const Color(0xFF191927);

    return Tooltip(
      message: isCurrentlyDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      child: InkWell(
        key: const ValueKey('header_theme_toggle_button'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderSubtle),
          ),
          child: Icon(
            isCurrentlyDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            size: 19,
            color: textPrimary,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PROFILE AVATAR DROPDOWN
// =============================================================================
class _ProfileAvatarDropdown extends StatelessWidget {
  final bool isDark;
  final Color borderSubtle;
  final bool showLogoutInDropdown;
  final VoidCallback onLogoutPressed;

  const _ProfileAvatarDropdown({
    required this.isDark,
    required this.borderSubtle,
    required this.showLogoutInDropdown,
    required this.onLogoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    ProfileModel? profile;
    User? user;

    // Safely check for Riverpod container without failing in lightweight test harnesses
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      user = container.read(authStateProvider).value;
      profile = container.read(profileProvider).value;
    } catch (_) {}

    final displayName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : (user?.displayName?.isNotEmpty == true
              ? user!.displayName!
              : 'Student Candidate');

    final displayEmail =
        user?.email ??
        (profile?.uid.isNotEmpty == true
            ? '${profile!.uid}@anhire.edu'
            : 'student@anhire.edu');

    final displayTag = profile?.preferredRole.isNotEmpty == true
        ? profile!.preferredRole
        : (profile?.branch.isNotEmpty == true
              ? profile!.branch
              : 'Software Engineering');

    final initials = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
        .join();

    final safeInitials = initials.isNotEmpty ? initials : 'SC';

    final dropdownBg = isDark
        ? const Color(0xFF15151E)
        : const Color(0xFFFFFFFF);
    final textPrimary = isDark
        ? const Color(0xFFF5F5FA)
        : const Color(0xFF191927);
    final textSecondary = isDark
        ? const Color(0xFFA1A1B5)
        : const Color(0xFF626277);
    final textMuted = isDark
        ? const Color(0xFF77778D)
        : const Color(0xFF85859A);

    return PopupMenuButton<String>(
      key: const ValueKey('profile_avatar_dropdown_button'),
      tooltip: 'Account & Settings',
      offset: const Offset(0, 48),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderSubtle, width: 1),
      ),
      color: dropdownBg,
      onSelected: (value) {
        switch (value) {
          case 'profile':
            context.go('/profile');
            break;
          case 'leaderboard':
            context.go('/leaderboard');
            break;
          case 'submissions':
            context.go('/profile');
            break;
          case 'bookmarks':
            context.go('/profile');
            break;
          case 'settings':
            context.go('/settings');
            break;
          case 'logout':
            onLogoutPressed();
            break;
        }
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            safeInitials,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
      itemBuilder: (ctx) => [
        // 1. User Information Header
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Text(
                  safeInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayEmail,
                      style: GoogleFonts.inter(fontSize: 11, color: textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (displayTag.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          displayTag,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),

        // 2. Profile
        PopupMenuItem<String>(
          value: 'profile',
          height: 42,
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 18, color: textMuted),
              const SizedBox(width: 12),
              Text(
                'Profile',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),

        // 3. Leaderboard
        PopupMenuItem<String>(
          value: 'leaderboard',
          height: 42,
          child: Row(
            children: [
              Icon(Icons.leaderboard_outlined, size: 18, color: textMuted),
              const SizedBox(width: 12),
              Text(
                'Leaderboard',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),

        // 4. Submissions
        PopupMenuItem<String>(
          value: 'submissions',
          height: 42,
          child: Row(
            children: [
              Icon(
                Icons.assignment_turned_in_outlined,
                size: 18,
                color: textMuted,
              ),
              const SizedBox(width: 12),
              Text(
                'Submissions',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),

        // 5. Bookmarks
        PopupMenuItem<String>(
          value: 'bookmarks',
          height: 42,
          child: Row(
            children: [
              Icon(Icons.bookmark_outline_rounded, size: 18, color: textMuted),
              const SizedBox(width: 12),
              Text(
                'Bookmarks',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),

        // 6. Settings
        PopupMenuItem<String>(
          value: 'settings',
          height: 42,
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 18, color: textMuted),
              const SizedBox(width: 12),
              Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),

        // 7. Log Out (Only shown in dropdown when sidebar is fully hidden or on mobile)
        if (showLogoutInDropdown) ...[
          const PopupMenuDivider(height: 1),
          PopupMenuItem<String>(
            value: 'logout',
            height: 42,
            child: Row(
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                const SizedBox(width: 12),
                Text(
                  'Log Out',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// REUSABLE EXPANDED SIDEBAR NAV ITEM
// =============================================================================
class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SidebarNavItem({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconToUse = widget.isActive && widget.activeIcon != null
        ? widget.activeIcon!
        : widget.icon;

    Color bg = Colors.transparent;
    Color textColor = isDark
        ? const Color(0xFFA1A1B5)
        : const Color(0xFF626277);
    Color iconColor = isDark
        ? const Color(0xFF77778D)
        : const Color(0xFF85859A);

    if (widget.isActive) {
      bg = AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1);
      textColor = isDark ? AppColors.accent : AppColors.primary;
      iconColor = isDark ? AppColors.accent : AppColors.primary;
    } else if (_isHovered) {
      bg = isDark
          ? const Color(0xFF1B1B27)
          : const Color(0xFFF0EFF8).withValues(alpha: 0.8);
      textColor = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF191927);
      iconColor = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF191927);
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
            splashColor: AppColors.primary.withValues(alpha: 0.15),
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: widget.isActive
                    ? Border.all(
                        color: AppColors.primary.withValues(
                          alpha: isDark ? 0.4 : 0.3,
                        ),
                        width: 1.0,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(iconToUse, color: iconColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        color: textColor,
                        fontWeight: widget.isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg = Colors.transparent;
    Color textColor = isDark
        ? const Color(0xFF77778D)
        : const Color(0xFF85859A);
    Color iconColor = isDark
        ? const Color(0xFF77778D)
        : const Color(0xFF85859A);

    if (widget.isActive) {
      bg = AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1);
      textColor = isDark ? AppColors.accent : AppColors.primary;
      iconColor = isDark ? AppColors.accent : AppColors.primary;
    } else if (_isHovered) {
      bg = isDark
          ? const Color(0xFF1B1B27).withValues(alpha: 0.8)
          : const Color(0xFFF0EFF8).withValues(alpha: 0.8);
      textColor = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF191927);
      iconColor = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF191927);
    }

    return Padding(
      padding: const EdgeInsets.only(left: 18),
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
              splashColor: AppColors.primary.withValues(alpha: 0.12),
              highlightColor: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: widget.isActive
                      ? Border.all(
                          color: AppColors.primary.withValues(
                            alpha: isDark ? 0.35 : 0.25,
                          ),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, color: iconColor, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontWeight: widget.isActive
                              ? FontWeight.w700
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

// =============================================================================
// COLLAPSED NAV ICON BUTTON (TOOLTIP ON HOVER)
// =============================================================================
class _CollapsedNavIconButton extends StatefulWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CollapsedNavIconButton({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_CollapsedNavIconButton> createState() =>
      _CollapsedNavIconButtonState();
}

class _CollapsedNavIconButtonState extends State<_CollapsedNavIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconToUse = widget.isActive && widget.activeIcon != null
        ? widget.activeIcon!
        : widget.icon;

    Color bg = Colors.transparent;
    Color iconColor = isDark
        ? const Color(0xFF77778D)
        : const Color(0xFF85859A);

    if (widget.isActive) {
      bg = AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1);
      iconColor = isDark ? AppColors.accent : AppColors.primary;
    } else if (_isHovered) {
      bg = isDark
          ? const Color(0xFF1B1B27)
          : const Color(0xFFF0EFF8).withValues(alpha: 0.8);
      iconColor = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF191927);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Tooltip(
            message: widget.label,
            waitDuration: const Duration(milliseconds: 300),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: widget.isActive
                      ? Border.all(
                          color: AppColors.primary.withValues(
                            alpha: isDark ? 0.4 : 0.3,
                          ),
                          width: 1,
                        )
                      : null,
                ),
                child: Icon(iconToUse, color: iconColor, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// COLLAPSED PRACTICE BUTTON (POPUP WITH CODING & APTITUDE)
// =============================================================================
class _CollapsedPracticeButton extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onCodingTap;
  final VoidCallback onAptitudeTap;
  final VoidCallback onExpandSidebar;

  const _CollapsedPracticeButton({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onCodingTap,
    required this.onAptitudeTap,
    required this.onExpandSidebar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconToUse = isActive && activeIcon != null ? activeIcon! : icon;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Tooltip(
          message: 'Practice (Coding & Aptitude)',
          waitDuration: const Duration(milliseconds: 300),
          child: Theme(
            data: Theme.of(context).copyWith(
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            child: PopupMenuButton<String>(
              tooltip: '',
              offset: const Offset(56, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF292938)
                      : const Color(0xFFE5E4EF),
                  width: 1,
                ),
              ),
              color: isDark ? const Color(0xFF15151E) : Colors.white,
              elevation: 8,
              onSelected: (value) {
                if (value == 'coding') onCodingTap();
                if (value == 'aptitude') onAptitudeTap();
                if (value == 'expand') onExpandSidebar();
              },
              itemBuilder: (ctx) => [
                PopupMenuItem<String>(
                  enabled: false,
                  height: 32,
                  child: Text(
                    'PRACTICE MODULES',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF77778D)
                          : const Color(0xFF85859A),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'coding',
                  height: 40,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.terminal_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Coding Problems',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'aptitude',
                  height: 40,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.psychology_outlined,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Aptitude Practice',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                PopupMenuItem<String>(
                  value: 'expand',
                  height: 36,
                  child: Row(
                    children: [
                      Icon(
                        Icons.menu_open_rounded,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF77778D)
                            : const Color(0xFF85859A),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Expand Sidebar',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFFA1A1B5)
                              : const Color(0xFF626277),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isActive
                      ? Border.all(
                          color: AppColors.primary.withValues(
                            alpha: isDark ? 0.4 : 0.3,
                          ),
                          width: 1,
                        )
                      : null,
                ),
                child: Icon(
                  iconToUse,
                  color: isActive
                      ? (isDark ? AppColors.accent : AppColors.primary)
                      : (isDark
                            ? const Color(0xFF77778D)
                            : const Color(0xFF85859A)),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SIDEBAR LOGOUT ITEM (AT THE BOTTOM OF SIDEBAR)
// =============================================================================
class _SidebarLogoutItem extends StatefulWidget {
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarLogoutItem({required this.isCollapsed, required this.onTap});

  @override
  State<_SidebarLogoutItem> createState() => _SidebarLogoutItemState();
}

class _SidebarLogoutItemState extends State<_SidebarLogoutItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hoverBg = AppColors.error.withValues(alpha: isDark ? 0.15 : 0.08);
    final normalColor = isDark
        ? const Color(0xFF85859A)
        : const Color(0xFF77778D);
    const activeColor = AppColors.error;

    if (widget.isCollapsed) {
      return Center(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Tooltip(
            message: 'Logout',
            waitDuration: const Duration(milliseconds: 300),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isHovered ? hoverBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: _isHovered
                      ? Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: _isHovered ? activeColor : normalColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: 'Logout from ANHIRE',
        waitDuration: const Duration(milliseconds: 700),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _isHovered ? hoverBg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: _isHovered
                  ? Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: _isHovered ? activeColor : normalColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Logout',
                    style: GoogleFonts.inter(
                      color: _isHovered ? activeColor : normalColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
