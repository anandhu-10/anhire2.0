import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

/// Standardized Elevated / Surface Card with Theme Awareness & Hover
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final bool isInteractive;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18.0),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16.0,
    this.isInteractive = false,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? const Color(0xFF15151E)
        : const Color(0xFFFFFFFF);
    final defaultBorder = isDark
        ? const Color(0xFF292938)
        : const Color(0xFFE5E4EF);
    final activeBorder =
        _isHovered && (widget.onTap != null || widget.isInteractive)
        ? AppColors.primary.withValues(alpha: 0.6)
        : (widget.borderColor ?? defaultBorder);

    final cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: activeBorder, width: 1.0),
        boxShadow: _isHovered && (widget.onTap != null || widget.isInteractive)
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.15 : 0.08,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: widget.child,
    );

    if (widget.onTap != null || widget.isInteractive) {
      return MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Standardized KPI Metric Card
class AppMetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? trailingBadge;
  final VoidCallback? onTap;

  const AppMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.trailingBadge,
    this.onTap,
  });

  @override
  State<AppMetricCard> createState() => _AppMetricCardState();
}

class _AppMetricCardState extends State<AppMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF15151E) : const Color(0xFFFFFFFF);
    final borderColor = _isHovered && widget.onTap != null
        ? AppColors.primary.withValues(alpha: 0.6)
        : (isDark ? const Color(0xFF292938) : const Color(0xFFE5E4EF));

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: _isHovered && widget.onTap != null
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.16 : 0.08,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.15 : 0.03,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(
                        alpha: isDark ? 0.18 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 22),
                  ),
                  if (widget.trailingBadge != null) widget.trailingBadge!,
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.value,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  letterSpacing: -0.5,
                  color: isDark
                      ? const Color(0xFFF5F5FA)
                      : const Color(0xFF191927),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFFF5F5FA)
                      : const Color(0xFF191927),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: GoogleFonts.inter(
                  color: isDark
                      ? const Color(0xFFA1A1B5)
                      : const Color(0xFF626277),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standardized Semantic Status Badge
enum AppBadgeVariant { primary, secondary, success, warning, error, neutral }

class AppBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppBadgeVariant variant;
  final bool isOutline;

  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = AppBadgeVariant.primary,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color baseColor;
    switch (variant) {
      case AppBadgeVariant.primary:
        baseColor = AppColors.primary;
        break;
      case AppBadgeVariant.secondary:
        baseColor = AppColors.secondary;
        break;
      case AppBadgeVariant.success:
        baseColor = AppColors.success;
        break;
      case AppBadgeVariant.warning:
        baseColor = AppColors.warning;
        break;
      case AppBadgeVariant.error:
        baseColor = AppColors.error;
        break;
      case AppBadgeVariant.neutral:
        baseColor = isDark ? const Color(0xFFA1A1B5) : const Color(0xFF626277);
        break;
    }

    final bg = isOutline
        ? Colors.transparent
        : baseColor.withValues(alpha: isDark ? 0.18 : 0.12);
    final border = baseColor.withValues(alpha: isOutline ? 0.6 : 0.3);
    final text = isOutline && !isDark && variant == AppBadgeVariant.neutral
        ? const Color(0xFF191927)
        : (isDark && variant == AppBadgeVariant.primary
              ? AppColors.accent
              : baseColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

/// Standardized Section Header
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark
                      ? const Color(0xFFF5F5FA)
                      : const Color(0xFF191927),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFFA1A1B5)
                        : const Color(0xFF626277),
                  ),
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

/// Standardized Empty State
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.description,
    this.actionLabel,
    this.onAction,
  }) : assert(
         message != null || description != null,
         'Either message or description must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: (isDark
                    ? const Color(0xFF1B1B27)
                    : const Color(0xFFF0EFF8)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isDark
                    ? const Color(0xFF77778D)
                    : const Color(0xFF85859A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFF5F5FA)
                    : const Color(0xFF191927),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                (message ?? description)!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFFA1A1B5)
                      : const Color(0xFF626277),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
