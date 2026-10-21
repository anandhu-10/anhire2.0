import 'package:flutter/material.dart';

/// Centralized Design System Palette & Tokens for ANHIRE.
/// Supports both dark and light modes cleanly with high accessibility and contrast.
class AppColors {
  // Brand Palette
  static const primary = Color(0xFF7C3AED);
  static const primaryHover = Color(0xFF6D28D9);
  static const secondary = Color(0xFF6366F1);
  static const accent = Color(0xFFA78BFA);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // Dark Theme Tokens (Defaults for static references)
  static const bgRoot = Color(0xFF0B0B10); // Main app background
  static const bgDark = Color(0xFF101016); // Secondary / Sidebar background
  static const bgSurface = Color(
    0xFF15151E,
  ); // Primary card / surface background
  static const bgSurfaceAlt = Color(0xFF1B1B27); // Elevated cards & containers
  static const bgCard = Color(0xFF15151E); // Card background
  static const bgInput = Color(0xFF1B1B27); // Input fields fill
  static const bgPurple = Color(0xFF7C3AED); // Accent container
  static const bgLavender = Color(0xFFEADDFF); // Light lavender container

  // Text Tiers (Dark Theme defaults)
  static const textPrimary = Color(0xFFF5F5FA); // Main text
  static const textSecondary = Color(0xFFA1A1B5); // Labels & subtitles
  static const textMuted = Color(0xFF77778D); // Hints & muted labels
  static const textOnPurple = Color(0xFFFFFFFF); // Text on purple
  static const textOnLavender = Color(
    0xFF191927,
  ); // Dark text on light lavender
  static const textAccent = Color(0xFFA78BFA); // Purple accent text
  static const textDarkOnMedal = Color(0xFF191927); // Dark text for medals

  // Accents & Borders
  static const accentPurple = Color(0xFF7C3AED);
  static const accentPurpleLight = Color(0xFFA78BFA);
  static const borderSubtle = Color(0xFF292938);
  static const chipBorder = Color(0xFF292938);
  static const darkBorder = Color(0xFF292938);
  static const lightBorder = Color(0xFFE5E4EF);
  static const darkSurfaceSecondary = Color(0xFF1B1B27);
  static const lightSurfaceSecondary = Color(0xFFF0EFF8);

  // Chips
  static const chipInactiveBg = Color(0xFF1B1B27);
  static const chipInactiveText = Color(0xFFA1A1B5);
  static const chipActiveBg = Color(0xFF7C3AED);
  static const chipActiveText = Color(0xFFFFFFFF);

  // Medal Tiers (Dark & Light tuned)
  static const bronze = Color(0xFFCD7F32);
  static const silver = Color(0xFFC0C0C0);
  static const gold = Color(0xFFFFD700);
  static const platinum = Color(0xFF4DB6AC);
  static const diamond = Color(0xFFB39DDB);

  // Additional Semantic & Code Colors
  static const info = Color(0xFF6366F1);
  static const orange = Color(0xFFF59E0B);
  static const green = Color(0xFF22C55E);
  static const successGreen = Color(0xFF22C55E);
  static const warningOrange = Color(0xFFF59E0B);
  static const errorRed = Color(0xFFEF4444);
  static const errorBorder = Color(0xFFEF4444);
  static const codeBg = Color(0xFF101016);
  static const codeBgDark = Color(0xFF0B0B10);
  static const codeHeader = Color(0xFF15151E);
  static const codeString = Color(0xFFCE9178);
  static const codeType = Color(0xFF4EC9B0);
  static const codeText = Color(0xFFD4D4D4);
  static const codePurpleBg = Color(0xFF231A3D);
  static const codePurpleBorder = Color(0xFF7C3AED);

  // ===========================================================================
  // DYNAMIC THEME-AWARE HELPERS
  // ===========================================================================
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color rootBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF0B0B10) : const Color(0xFFF7F7FC);

  static Color sidebarBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF101016) : const Color(0xFFFFFFFF);

  static Color surface(BuildContext context) =>
      isDark(context) ? const Color(0xFF15151E) : const Color(0xFFFFFFFF);

  static Color surfaceAlt(BuildContext context) =>
      isDark(context) ? const Color(0xFF1B1B27) : const Color(0xFFF0EFF8);

  static Color card(BuildContext context) =>
      isDark(context) ? const Color(0xFF15151E) : const Color(0xFFFFFFFF);

  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF292938) : const Color(0xFFE5E4EF);

  static Color primaryText(BuildContext context) =>
      isDark(context) ? const Color(0xFFF5F5FA) : const Color(0xFF191927);

  static Color secondaryText(BuildContext context) =>
      isDark(context) ? const Color(0xFFA1A1B5) : const Color(0xFF626277);

  static Color mutedText(BuildContext context) =>
      isDark(context) ? const Color(0xFF77778D) : const Color(0xFF85859A);

  static Color inputBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF1B1B27) : const Color(0xFFFFFFFF);
}

/// Ergonomic BuildContext extensions for theme colors
extension AppThemeContextExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get appRootBg => AppColors.rootBg(this);
  Color get appSidebarBg => AppColors.sidebarBg(this);
  Color get appSurface => AppColors.surface(this);
  Color get appSurfaceAlt => AppColors.surfaceAlt(this);
  Color get appCard => AppColors.card(this);
  Color get appBorder => AppColors.border(this);
  Color get appTextPrimary => AppColors.primaryText(this);
  Color get appTextSecondary => AppColors.secondaryText(this);
  Color get appTextMuted => AppColors.mutedText(this);
  Color get appInputBg => AppColors.inputBg(this);
}
