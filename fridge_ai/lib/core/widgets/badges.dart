import 'package:flutter/material.dart';

import '../../models/ingredient.dart';
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

/// Small pill shown on ingredient cards/chips when [Ingredient.expirationDate]
/// is soon or already past — reuses the app's existing danger color (mapped
/// per-theme, matching the pattern already used by [ErrorBanner] and the
/// favorite-heart icon) so no new colors enter the palette.
class FreshnessBadge extends StatelessWidget {
  const FreshnessBadge({super.key, required this.ingredient, this.dense = false});

  final Ingredient ingredient;

  /// Slightly tighter padding/text for the compact [IngredientChip] layout.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final urgency = ingredient.freshnessUrgency;
    if (urgency == FreshnessUrgency.none) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = urgency == FreshnessUrgency.expired
        ? (isDark ? AppColors.darkDanger : AppColors.lightDanger)
        : AppColors.mediumOrange;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 7 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: dense ? 11 : 13, color: color),
          const SizedBox(width: 3),
          Text(
            ingredient.freshnessLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: dense ? 10 : null,
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
