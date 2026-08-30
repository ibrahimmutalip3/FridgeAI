import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/ingredient_image.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../models/ingredient.dart';

/// Full-width ingredient card used on Ingredient Results / My Kitchen —
/// shows image, name, quantity, and edit/delete actions.
class IngredientCard extends StatelessWidget {
  const IngredientCard({
    super.key,
    required this.ingredient,
    this.onEdit,
    this.onDelete,
  });

  final Ingredient ingredient;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasFreshnessHint = ingredient.freshnessUrgency != FreshnessUrgency.none;

    return SoftCard(
      onTap: onEdit,
      child: Row(
        children: [
          SizedBox(
            height: 56,
            width: 56,
            child: IngredientImage(
              ingredient: ingredient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ingredient.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(ingredient.quantity, style: theme.textTheme.bodySmall),
                if (hasFreshnessHint) ...[
                  const SizedBox(height: 6),
                  FreshnessBadge(ingredient: ingredient),
                ],
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: isDark ? AppColors.darkDanger : AppColors.lightDanger,
            ),
        ],
      ),
    );
  }
}

/// Compact vertical chip used in the horizontal "My Ingredients" row on Home.
class IngredientChip extends StatelessWidget {
  const IngredientChip({super.key, required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final urgency = ingredient.freshnessUrgency;
    final dotColor = urgency == FreshnessUrgency.expired
        ? (isDark ? AppColors.darkDanger : AppColors.lightDanger)
        : AppColors.mediumOrange;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: IngredientImage(
                    ingredient: ingredient,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                // Small freshness indicator dot in the corner — a full label
                // would overflow this compact 108x108 chip, so the color
                // alone (backed by the ingredient's name/quantity text
                // already visible below) carries the signal.
                if (urgency != FreshnessUrgency.none)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ingredient.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium,
          ),
          Text(
            ingredient.quantity,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
