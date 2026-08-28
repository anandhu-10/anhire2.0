/// Application global constants.
class AppConstants {
  /// Toggle for dev mock data fallback. Set to false for production builds.
  static const bool USE_MOCK_DATA = false;
}

/// Responsive Breakpoints and Content Constraints
class AppBreakpoints {
  // Screen Width Breakpoints
  static const double compactMax = 599.9;
  static const double mediumMax = 1023.9;
  static const double expandedMax = 1439.9;

  static const double compactBreakpoint = 600.0;
  static const double mediumBreakpoint = 1024.0;
  static const double expandedBreakpoint = 1440.0;

  // Content Max Width Constraints
  static const double maxFormWidth = 480.0;
  static const double maxCardWidthSmall = 600.0;
  static const double maxCardWidthMedium = 800.0;
  static const double maxContentWidth = 1200.0;

  // Touch Target Minimum Dimensions
  static const double minTouchTarget = 48.0;
  static const double minListTileHeight = 56.0;
}
