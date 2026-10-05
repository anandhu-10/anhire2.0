import 'package:flutter/material.dart';
import '../core/constants/gamification.dart';

class MedalBadgeWidget extends StatelessWidget {
  final MedalTier tier;
  final bool isChip;
  final double size;

  const MedalBadgeWidget({
    super.key,
    required this.tier,
    this.isChip = true,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (!isChip) {
      return Container(
        width: size * 2.2,
        height: size * 2.2,
        decoration: BoxDecoration(
          color: tier.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: tier.color.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          tier.icon,
          size: size * 1.3,
          color: tier.textColor,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tier.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tier.color.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tier.icon,
            size: size,
            color: tier.textColor,
          ),
          const SizedBox(width: 4),
          Text(
            tier.label,
            style: TextStyle(
              fontSize: size * 0.85,
              fontWeight: FontWeight.bold,
              color: tier.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
