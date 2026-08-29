import 'package:flutter/material.dart';

import '../../models/recipe.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.difficulty});

  final Difficulty difficulty;

  Color get _color {
    switch (difficulty) {
      case Difficulty.easy:
        return AppColors.easyGreen;
      case Difficulty.medium:
        return AppColors.mediumOrange;
      case Difficulty.hard:
        return AppColors.hardRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        difficulty.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _color),
      ),
    );
  }
}

class MatchBadge extends StatelessWidget {
  const MatchBadge({super.key, required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondaryGreen.withValues(alpha: isDark ? 0.22 : 0.18),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.secondaryGreen),
          const SizedBox(width: 4),
          Text(
            '$percentage% available',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.secondaryGreen,
                ),
          ),
        ],
      ),
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelMedium),
      ],
    );
  }
}
