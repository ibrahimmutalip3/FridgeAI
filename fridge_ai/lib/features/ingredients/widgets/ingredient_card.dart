import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/fallback_image.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../models/ingredient.dart';
import '../../../services/recipe_image_resolver.dart';

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

    return SoftCard(
      onTap: onEdit,
      child: Row(
        children: [
          SizedBox(
            height: 56,
            width: 56,
            child: FallbackImage(
              assetPath: RecipeImageResolver.assetForIngredient(ingredient),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              icon: _iconFor(ingredient.category),
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
              color: AppColors.lightDanger,
            ),
        ],
      ),
    );
  }

  IconData _iconFor(IngredientCategory category) {
    switch (category) {
      case IngredientCategory.vegetables:
        return Icons.eco_rounded;
      case IngredientCategory.meat:
        return Icons.set_meal_rounded;
      case IngredientCategory.dairy:
        return Icons.icecream_rounded;
      case IngredientCategory.fruits:
        return Icons.apple_rounded;
      case IngredientCategory.grains:
        return Icons.grain_rounded;
      case IngredientCategory.pantry:
        return Icons.kitchen_rounded;
    }
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
            child: SizedBox(
              width: double.infinity,
              child: FallbackImage(
                assetPath: RecipeImageResolver.assetForIngredient(ingredient),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
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
