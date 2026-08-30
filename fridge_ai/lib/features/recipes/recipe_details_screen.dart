import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/entrance_fade.dart';
import '../../core/widgets/fallback_image.dart';
import '../../core/widgets/liquid_glass_status_bar.dart';
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
      body: Stack(
        children: [
          CustomScrollView(
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
                    child: _FavoriteButton(
                      isFavorite: isFavorite,
                      onTap: () async {
                        HapticFeedback.lightImpact();
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
                      borderRadius:
                          const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl)),
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
                  // A light, four-beat stagger across whole sections (title,
                  // info pills, ingredients, instructions) rather than one per
                  // line — the page transition already carries most of the
                  // "arrival" motion, so this just keeps content from popping
                  // in all at once underneath it.
                  delegate: SliverChildListDelegate([
                    EntranceFade(
                      index: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(recipe.title, style: theme.textTheme.displayMedium),
                          const SizedBox(height: AppSpacing.sm),
                          if (recipe.description.isNotEmpty) ...[
                            Text(recipe.description, style: theme.textTheme.bodyLarge),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ),
                    ),
                    EntranceFade(
                      index: 1,
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          DifficultyBadge(difficulty: recipe.difficulty),
                          InfoPill(icon: Icons.timer_outlined, label: '${recipe.cookingTimeMinutes} min'),
                          InfoPill(icon: Icons.groups_2_outlined, label: '${recipe.servings} servings'),
                          MatchBadge(percentage: recipe.matchPercentage),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    EntranceFade(
                      index: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    EntranceFade(
                      index: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Instructions', style: theme.textTheme.headlineSmall),
                          const SizedBox(height: AppSpacing.sm),
                          ...recipe.steps.map((step) => _StepRow(step: step)),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          const Positioned(top: 0, left: 0, right: 0, child: LiquidGlassStatusBar()),
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
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

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
          child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

/// The recipe-details favorite toggle — a circular button matching
/// [_CircleButton]'s chrome, but with its own brief overshoot scale pop on
/// toggle (rather than [_CircleButton]'s plain tap) since favoriting is a
/// meaningful, infrequent action worth a touch more delight than a generic
/// icon button.
class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _popped = false;

  Future<void> _handleTap() async {
    widget.onTap();
    setState(() => _popped = true);
    await Future.delayed(const Duration(milliseconds: 160));
    if (mounted) setState(() => _popped = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final favoriteColor = isDark ? AppColors.darkDanger : AppColors.lightDanger;

    return Material(
      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.65),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _handleTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedScale(
            scale: _popped ? 1.25 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: Icon(
              widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
              color: widget.isFavorite ? favoriteColor : theme.colorScheme.onSurface,
            ),
          ),
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
