import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/fallback_image.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../models/recipe.dart';
import '../../../services/recipe_image_resolver.dart';

/// Recipe card used on Home, Recipe Results, and Recipes screens.
/// Uses a [Hero] tag keyed by recipe id so the details screen can morph
/// the hero image in on navigation.
class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'recipe_image_${recipe.id}',
            child: SizedBox(
              height: 92,
              width: 92,
              child: FallbackImage(
                assetPath: RecipeImageResolver.assetForRecipe(recipe),
                networkUrl: recipe.imageUrl,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    InfoPill(icon: Icons.timer_outlined, label: '${recipe.cookingTimeMinutes} min'),
                    const SizedBox(width: AppSpacing.sm),
                    DifficultyBadge(difficulty: recipe.difficulty),
                  ],
                ),
                const SizedBox(height: 6),
                MatchBadge(percentage: recipe.matchPercentage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
