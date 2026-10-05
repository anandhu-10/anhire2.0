import 'package:flutter/material.dart';
import 'app_colors.dart';

class PointsRules {
  static const int easyProblem = 10;
  static const int mediumProblem = 25;
  static const int hardProblem = 50;
  static const int aptitudePerfectTest = 30; // 100% accuracy
  static const int aptitudeGoodTest = 15;    // >= 70% accuracy
  static const int interviewCompleted = 20;  // per session
  static const int interviewStrong = 40;     // score >= 70
  static const int resumeUploaded = 10;     // one-time
}

enum MedalTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond;

  static MedalTier fromPoints(int points) {
    if (points >= 1000) return MedalTier.diamond;
    if (points >= 500) return MedalTier.platinum;
    if (points >= 250) return MedalTier.gold;
    if (points >= 100) return MedalTier.silver;
    return MedalTier.bronze;
  }

  String get label {
    switch (this) {
      case MedalTier.bronze:
        return 'Bronze';
      case MedalTier.silver:
        return 'Silver';
      case MedalTier.gold:
        return 'Gold';
      case MedalTier.platinum:
        return 'Platinum';
      case MedalTier.diamond:
        return 'Diamond';
    }
  }

  Color get color {
    switch (this) {
      case MedalTier.bronze:
        return AppColors.bronze;
      case MedalTier.silver:
        return AppColors.silver;
      case MedalTier.gold:
        return AppColors.gold;
      case MedalTier.platinum:
        return AppColors.platinum;
      case MedalTier.diamond:
        return AppColors.diamond;
    }
  }

  /// Dark text (#1C1B1F) for Bronze, Silver, Gold, Platinum; White text for Diamond.
  Color get textColor {
    switch (this) {
      case MedalTier.diamond:
        return Colors.white;
      case MedalTier.bronze:
      case MedalTier.silver:
      case MedalTier.gold:
      case MedalTier.platinum:
        return AppColors.textDarkOnMedal;
    }
  }

  IconData get icon {
    switch (this) {
      case MedalTier.bronze:
        return Icons.military_tech_outlined;
      case MedalTier.silver:
        return Icons.military_tech;
      case MedalTier.gold:
        return Icons.emoji_events;
      case MedalTier.platinum:
        return Icons.workspace_premium;
      case MedalTier.diamond:
        return Icons.diamond;
    }
  }

  int get minPoints {
    switch (this) {
      case MedalTier.bronze:
        return 0;
      case MedalTier.silver:
        return 100;
      case MedalTier.gold:
        return 250;
      case MedalTier.platinum:
        return 500;
      case MedalTier.diamond:
        return 1000;
    }
  }

  int? get nextTierMinPoints {
    switch (this) {
      case MedalTier.bronze:
        return 100;
      case MedalTier.silver:
        return 250;
      case MedalTier.gold:
        return 500;
      case MedalTier.platinum:
        return 1000;
      case MedalTier.diamond:
        return null;
    }
  }

  String? get nextTierLabel {
    switch (this) {
      case MedalTier.bronze:
        return 'Silver';
      case MedalTier.silver:
        return 'Gold';
      case MedalTier.gold:
        return 'Platinum';
      case MedalTier.platinum:
        return 'Diamond';
      case MedalTier.diamond:
        return null;
    }
  }
}

class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  static const List<BadgeDefinition> allBadges = [
    BadgeDefinition(
      id: 'first_solve',
      name: 'First Solve',
      description: 'Solved your 1st coding problem',
      icon: Icons.code,
    ),
    BadgeDefinition(
      id: 'warming_up',
      name: 'Warming Up',
      description: 'Solved 5 coding problems',
      icon: Icons.local_fire_department,
    ),
    BadgeDefinition(
      id: 'code_warrior',
      name: 'Code Warrior',
      description: 'Solved 15 coding problems',
      icon: Icons.shield,
    ),
    BadgeDefinition(
      id: 'code_master',
      name: 'Code Master',
      description: 'Solved all 30 coding problems',
      icon: Icons.military_tech,
    ),
    BadgeDefinition(
      id: 'sharp_mind',
      name: 'Sharp Mind',
      description: 'Completed 10 aptitude tests',
      icon: Icons.psychology,
    ),
    BadgeDefinition(
      id: 'perfect_score',
      name: 'Perfect Score',
      description: 'Achieved 100% accuracy in an aptitude test',
      icon: Icons.stars,
    ),
    BadgeDefinition(
      id: 'interview_ready',
      name: 'Interview Ready',
      description: 'Completed your 1st mock interview session',
      icon: Icons.video_call,
    ),
    BadgeDefinition(
      id: 'interview_star',
      name: 'Interview Star',
      description: 'Achieved mock interview score >= 75',
      icon: Icons.grade,
    ),
    BadgeDefinition(
      id: 'resume_ready',
      name: 'Resume Ready',
      description: 'Achieved resume ATS score >= 70',
      icon: Icons.description,
    ),
    BadgeDefinition(
      id: 'all_rounder',
      name: 'All Rounder',
      description: 'Solved >=10 problems, >=5 tests & >=2 interviews',
      icon: Icons.auto_awesome,
    ),
  ];
}
