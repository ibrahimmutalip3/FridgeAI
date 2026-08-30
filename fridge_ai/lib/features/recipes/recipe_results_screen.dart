import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance_fade.dart';
import '../../core/widgets/liquid_glass_status_bar.dart';
import '../../core/widgets/skeleton.dart';
import '../../providers/pantry_providers.dart';
import '../../providers/recipe_providers.dart';
import 'widgets/recipe_card.dart';
import 'widgets/recipe_filter_chips.dart';

class RecipeResultsScreen extends ConsumerWidget {
  const RecipeResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generation = ref.watch(recipeGenerationProvider);
    final filtered = ref.watch(filteredRecipesProvider);
    final pantry = ref.watch(pantryProvider);

    return Scaffold(
      appBar: const LiquidGlassAppBar(title: Text('Made with what you have')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          // A cross-fade (rather than the default size+fade) keeps the
          // skeleton -> real-content handoff calm instead of a layout
          // jump, since both states are pinned to the same top-left
          // origin under Stack/Positioned.fill.
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          layoutBuilder: (currentChild, previousChildren) => Stack(
            children: [
              for (final child in previousChildren) Positioned.fill(child: child),
              if (currentChild != null) Positioned.fill(child: currentChild),
            ],
          ),
          child: Builder(
            key: ValueKey(generation.status),
            builder: (context) {
              if (generation.status == RecipeGenerationStatus.loading) {
                return const _GeneratingView();
              }
              if (generation.status == RecipeGenerationStatus.error) {
                return EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Something went wrong',
                  message: generation.errorMessage ?? 'Please try again.',
                  actionLabel: 'Try Again',
                  onAction: () => ref.read(recipeGenerationProvider.notifier).generate(pantry),
                );
              }
              if (generation.status == RecipeGenerationStatus.empty ||
                  generation.recipes.isEmpty) {
                return EmptyState(
                  icon: Icons.ramen_dining_rounded,
                  title: 'No recipes yet',
                  message: 'Scan some ingredients and I\u2019ll whip up recipe ideas for you.',
                  actionLabel: 'Scan Food',
                  onAction: () => context.push(AppRoutes.scanner),
                );
              }

              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: RecipeFilterChips(),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const EmptyState(
                            icon: Icons.filter_alt_off_rounded,
                            title: 'No matches',
                            message: 'Try a different filter to see more recipes.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.sm,
                              AppSpacing.lg,
                              AppSpacing.xl,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final recipe = filtered[index];
                              return EntranceFade(
                                index: index,
                                child: RecipeCard(
                                  recipe: recipe,
                                  onTap: () => context.push(AppRoutes.recipeDetails, extra: recipe),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Recipe Results loading state — a skeleton list shaped like the real
/// [RecipeCard] layout (rather than a bare centered spinner), plus a short
/// status line so the wait reads as "the AI is working" instead of "the
/// app is stuck."
class _GeneratingView extends StatelessWidget {
  const _GeneratingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primaryOrange),
                  backgroundColor: theme.dividerColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Cooking up some ideas from your ingredients\u2026',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const Expanded(child: RecipeListSkeleton()),
      ],
    );
  }
}
