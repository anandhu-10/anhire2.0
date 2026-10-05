import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/gamification.dart';

class CelebrationDialog extends StatelessWidget {
  final BadgeDefinition badge;

  const CelebrationDialog({
    super.key,
    required this.badge,
  });

  static Future<void> show(BuildContext context, BadgeDefinition badge) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CelebrationDialog(badge: badge),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🎉 ', style: TextStyle(fontSize: 18)),
              Expanded(
                child: Text('Unlocked badge: ${badge.name}!'),
              ),
            ],
          ),
          backgroundColor: AppColors.accentPurple,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.accentPurpleLight, width: 1.5),
      ),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentPurpleLight, width: 2),
              ),
              child: Icon(
                badge.icon,
                size: 42,
                color: AppColors.accentPurpleLight,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '🎉 Achievement Unlocked!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textAccent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Nice! 🔥',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
