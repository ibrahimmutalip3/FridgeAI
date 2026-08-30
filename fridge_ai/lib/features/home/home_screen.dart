import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/entrance_fade.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/screen_header_background.dart';
import '../../core/widgets/section_header.dart';
import '../../providers/pantry_providers.dart';
import '../../providers/preferences_providers.dart';
import '../../providers/recipe_providers.dart';
import '../ingredients/widgets/ingredient_card.dart';
import '../recipes/widgets/recipe_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final preferences = ref.watch(preferencesProvider);
    final pantry = ref.watch(pantryProvider);
    final recommended = ref.watch(pantryBasedRecipesProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Real, static theme photo fading into the scaffold background —
          // pinned behind everything, above the status bar.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ScreenHeaderBackground(query: ScreenBackgrounds.home, height: 300),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    140,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                preferences.userName,
                                style: theme.textTheme.displayMedium?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.profileTab),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white.withValues(alpha: 0.85),
                              child: Text(
                                preferences.userName.isNotEmpty
                                    ? preferences.userName[0].toUpperCase()
                                    : 'C',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: AppColors.primaryOrangeDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _HeroScanCard(onTap: () => context.push(AppRoutes.scanner)),
                      const SizedBox(height: AppSpacing.xl),
                      SectionHeader(
                        title: 'My Ingredients',
                        actionLabel: pantry.isNotEmpty ? 'See all' : null,
                        onActionTap: () => context.push(AppRoutes.myKitchen),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 108,
                        child: pantry.isEmpty
                            ? _EmptyIngredientsRow(onTap: () => context.push(AppRoutes.scanner))
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: pantry.length,
                                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final ingredient = pantry[index];
                                  return EntranceFade(
                                    index: index,
                                    child: SizedBox(
                                      width: 108,
                                      child: IngredientChip(ingredient: ingredient),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SectionHeader(
                        title: 'Recommended for you',
                        actionLabel: recommended.isNotEmpty ? 'See all' : null,
                        onActionTap: () => context.push(AppRoutes.recipeResults),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (recommended.isEmpty)
                        _RecommendedEmptyCard(
                          hasPantry: pantry.isNotEmpty,
                          onGenerate: () {
                            ref.read(recipeGenerationProvider.notifier).generate(pantry);
                            context.push(AppRoutes.recipeResults);
                          },
                          onScan: () => context.push(AppRoutes.scanner),
                        )
                      else
                        Column(
                          children: [
                            for (var i = 0; i < recommended.length.clamp(0, 3); i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: EntranceFade(
                                  index: i,
                                  child: RecipeCard(
                                    recipe: recommended[i],
                                    onTap: () => context.push(
                                      AppRoutes.recipeDetails,
                                      extra: recommended[i],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroScanCard extends StatelessWidget {
  const _HeroScanCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryOrange,
            AppColors.primaryOrangeDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\u2019s in your fridge?',
            style: theme.textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Take a photo and I\u2019ll find something delicious.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92)),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Scan Food',
            icon: Icons.camera_alt_rounded,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryOrangeDark,
            expand: false,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class _EmptyIngredientsRow extends StatelessWidget {
  const _EmptyIngredientsRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCream : AppColors.lightCream,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        alignment: Alignment.center,
        child: Text(
          'No ingredients yet \u2014 tap to scan your fridge',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _RecommendedEmptyCard extends StatelessWidget {
  const _RecommendedEmptyCard({
    required this.hasPantry,
    required this.onGenerate,
    required this.onScan,
  });

  final bool hasPantry;
  final VoidCallback onGenerate;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCream : AppColors.lightCream,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryOrange, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasPantry ? 'Ready when you are' : 'Scan your fridge to get started',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            hasPantry
                ? 'Generate recipes using the ingredients you\u2019ve saved.'
                : 'Once you add ingredients, I\u2019ll suggest recipes here.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: hasPantry ? 'Find Recipes' : 'Scan Food',
            expand: false,
            onPressed: hasPantry ? onGenerate : onScan,
          ),
        ],
      ),
    );
  }
}
