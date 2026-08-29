import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/fallback_image.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/cooking_step.dart';
import '../../models/recipe.dart';
import '../../providers/recipe_providers.dart';
import '../../services/recipe_image_resolver.dart';

class RecipeDetailsScreen extends ConsumerStatefulWidget {
  const RecipeDetailsScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends ConsumerState<RecipeDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoritesControllerProvider).recordViewed(widget.recipe);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = widget.recipe;
    final favoritesController = ref.read(favoritesControllerProvider);
    final isFavorite = favoritesController.isFavorite(recipe.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => context.pop(),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: _CircleButton(
                  icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: isFavorite ? AppColors.lightDanger : null,
                  onTap: () async {
                    await favoritesController.toggle(recipe);
                    setState(() {});
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'recipe_image_${recipe.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl)),
                  child: FallbackImage(
                    assetPath: RecipeImageResolver.assetForRecipe(recipe),
                    networkUrl: recipe.imageUrl,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(recipe.title, style: theme.textTheme.displayMedium),
                const SizedBox(height: AppSpacing.sm),
                if (recipe.description.isNotEmpty) ...[
                  Text(recipe.description, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.md),
                ],
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    DifficultyBadge(difficulty: recipe.difficulty),
                    InfoPill(icon: Icons.timer_outlined, label: '${recipe.cookingTimeMinutes} min'),
                    InfoPill(icon: Icons.groups_2_outlined, label: '${recipe.servings} servings'),
                    MatchBadge(percentage: recipe.matchPercentage),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Ingredients', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                if (recipe.availableIngredients.isNotEmpty) ...[
                  Text(
                    '\u2713 Already have',
                    style: theme.textTheme.titleSmall?.copyWith(color: AppColors.secondaryGreen),
                  ),
                  const SizedBox(height: 6),
                  ...recipe.availableIngredients.map(
                    (i) => _IngredientRow(name: i.name, quantity: i.quantity, available: true),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (recipe.missingIngredients.isNotEmpty) ...[
                  Text(
                    'Need to buy',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...recipe.missingIngredients.map(
                    (i) => _IngredientRow(name: i.name, quantity: i.quantity, available: false),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Text('Instructions', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                ...recipe.steps.map((step) => _StepRow(step: step)),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
          child: PrimaryButton(
            label: 'Start Cooking',
            icon: Icons.play_arrow_rounded,
            onPressed: recipe.steps.isEmpty
                ? null
                : () => context.push(AppRoutes.cookingMode, extra: recipe),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap, this.iconColor});

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.65),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.name, required this.quantity, required this.available});

  final String name;
  final String quantity;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
            size: 18,
            color: available
                ? AppColors.secondaryGreen
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(name, style: theme.textTheme.bodyLarge)),
          Text(quantity, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final CookingStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${step.order}',
              style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primaryOrangeDark),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(step.instruction, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
