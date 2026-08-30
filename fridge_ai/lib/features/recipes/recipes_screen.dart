import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance_fade.dart';
import '../../core/widgets/section_header.dart';
import '../../models/recipe.dart';
import '../../providers/pantry_providers.dart';
import '../../providers/recipe_providers.dart';
import 'widgets/recipe_card.dart';

/// The "Recipes" tab — search, category filter chips, and sections for
/// ingredient-based suggestions, recently viewed, and favorites.
class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  RecipeTag? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> _applyQuery(List<Recipe> recipes) {
    var filtered = recipes;
    if (_category != null) {
      filtered = filtered.where((r) => r.tags.contains(_category)).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      filtered = filtered.where((r) => r.title.toLowerCase().contains(q)).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final pantry = ref.watch(pantryProvider);
    final basedOnIngredients = _applyQuery(ref.watch(pantryBasedRecipesProvider));
    final recentlyViewed = _applyQuery(ref.watch(recentlyViewedProvider));
    final favorites = _applyQuery(ref.watch(favoriteRecipesProvider));

    final hasAnyContent =
        basedOnIngredients.isNotEmpty || recentlyViewed.isNotEmpty || favorites.isNotEmpty;

    // Running index across every section below, so the whole screen reads
    // as one continuous stagger rather than each section restarting the
    // entrance animation from item 0 (same fix applied to My Kitchen's
    // category sections).
    var runningIndex = 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 140),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search recipes',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CategoryChip(
                          label: 'All',
                          selected: _category == null,
                          onTap: () => setState(() => _category = null),
                        ),
                        for (final tag in RecipeTag.values)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _CategoryChip(
                              label: tag.label,
                              selected: _category == tag,
                              onTap: () => setState(() => _category = tag),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    // Keyed by content shape so switching filters/search
                    // cross-fades to the new set instead of the list just
                    // snapping to different cards mid-scroll.
                    child: KeyedSubtree(
                      key: ValueKey('$_category-$_query-$hasAnyContent'),
                      child: !hasAnyContent
                          ? EmptyState(
                              icon: Icons.menu_book_outlined,
                              title: 'No recipes yet',
                              message: pantry.isEmpty
                                  ? 'Scan your fridge to get personalized recipe ideas.'
                                  : 'Generate recipes from your ingredients to see them here.',
                              actionLabel: pantry.isEmpty ? 'Scan Food' : 'Find Recipes',
                              onAction: () {
                                if (pantry.isEmpty) {
                                  context.push(AppRoutes.scanner);
                                } else {
                                  ref.read(recipeGenerationProvider.notifier).generate(pantry);
                                  context.push(AppRoutes.recipeResults);
                                }
                              },
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (basedOnIngredients.isNotEmpty) ...[
                                  const SectionHeader(title: 'Based on your ingredients'),
                                  const SizedBox(height: AppSpacing.sm),
                                  _RecipeList(
                                    recipes: basedOnIngredients,
                                    startIndex: runningIndex,
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                ],
                                if (favorites.isNotEmpty) ...[
                                  const SectionHeader(title: 'Favorites'),
                                  const SizedBox(height: AppSpacing.sm),
                                  _RecipeList(
                                    recipes: favorites,
                                    startIndex: runningIndex += basedOnIngredients.length,
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                ],
                                if (recentlyViewed.isNotEmpty) ...[
                                  const SectionHeader(title: 'Recently viewed'),
                                  const SizedBox(height: AppSpacing.sm),
                                  _RecipeList(
                                    recipes: recentlyViewed,
                                    startIndex: runningIndex += favorites.length,
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeList extends StatelessWidget {
  const _RecipeList({required this.recipes, this.startIndex = 0});

  final List<Recipe> recipes;
  final int startIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < recipes.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: EntranceFade(
              index: startIndex + i,
              child: RecipeCard(
                recipe: recipes[i],
                onTap: () => context.push(AppRoutes.recipeDetails, extra: recipes[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
