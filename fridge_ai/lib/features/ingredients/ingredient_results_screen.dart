import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_removal.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance_fade.dart';
import '../../core/widgets/liquid_glass_status_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/screen_header_background.dart';
import '../../models/ingredient.dart';
import '../../providers/pantry_providers.dart';
import '../../providers/recipe_providers.dart';
import 'widgets/edit_ingredient_sheet.dart';
import 'widgets/ingredient_card.dart';

class IngredientResultsScreen extends ConsumerStatefulWidget {
  const IngredientResultsScreen({super.key});

  @override
  ConsumerState<IngredientResultsScreen> createState() => _IngredientResultsScreenState();
}

class _IngredientResultsScreenState extends ConsumerState<IngredientResultsScreen> {
  // One removal-animation key per ingredient id, so tapping delete can
  // trigger that specific card's exit animation before the ingredient is
  // actually removed from state. Entries are pruned as ingredients leave
  // the draft so this never grows unbounded across a long session.
  final _removalKeys = <String, GlobalKey<AnimatedRemovalState>>{};

  GlobalKey<AnimatedRemovalState> _keyFor(String id) {
    return _removalKeys.putIfAbsent(id, () => GlobalKey<AnimatedRemovalState>());
  }

  Future<void> _editIngredient(BuildContext context, Ingredient ingredient) async {
    final result = await showModalBottomSheet<Ingredient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditIngredientSheet(ingredient: ingredient),
    );
    if (result != null) {
      ref.read(scanDraftProvider.notifier).update(result);
    }
  }

  Future<void> _addIngredient(BuildContext context) async {
    final result = await showModalBottomSheet<Ingredient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EditIngredientSheet(ingredient: null),
    );
    if (result != null) {
      ref.read(scanDraftProvider.notifier).add(result);
    }
  }

  Future<void> _removeIngredient(String id) async {
    // Play the exit animation first, then actually mutate state — the
    // key's currentState may already be gone if the list rebuilt for an
    // unrelated reason, in which case we fall back to an instant removal.
    final state = _removalKeys[id]?.currentState;
    _removalKeys.remove(id);
    if (state != null) {
      await state.remove();
    } else {
      ref.read(scanDraftProvider.notifier).remove(id);
    }
  }

  Future<void> _confirmAndFindRecipes(BuildContext context) async {
    final draft = ref.read(scanDraftProvider);
    if (draft.isEmpty) return;

    await ref.read(pantryProvider.notifier).addIngredients(draft);
    ref.read(scanDraftProvider.notifier).clear();

    if (!context.mounted) return;
    ref.read(recipeGenerationProvider.notifier).generate(draft);
    context.pushReplacement(AppRoutes.recipeResults);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(scanDraftProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: LiquidGlassAppBar(
        title: Text(
          'Here\u2019s what I found',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
        ),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Real, static theme photo behind the app bar, fading into the
          // scaffold background further down the screen.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ScreenHeaderBackground(query: ScreenBackgrounds.kitchen, height: 260),
          ),
          SafeArea(
            child: draft.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: kToolbarHeight),
                    child: Center(
                      child: EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No ingredients here yet',
                        message: 'Add an ingredient manually, or head back and rescan.',
                        actionLabel: 'Add Ingredient',
                        onAction: () => _addIngredient(context),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      kToolbarHeight + AppSpacing.md,
                      AppSpacing.lg,
                      160,
                    ),
                    itemCount: draft.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final ingredient = draft[index];
                      return EntranceFade(
                        index: index,
                        child: AnimatedRemoval(
                          key: _keyFor(ingredient.id),
                          onRemoved: () => ref.read(scanDraftProvider.notifier).remove(ingredient.id),
                          child: IngredientCard(
                            ingredient: ingredient,
                            onEdit: () => _editIngredient(context, ingredient),
                            onDelete: () => _removeIngredient(ingredient.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addIngredient(context),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add ingredient'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.replay_rounded, size: 20),
                      label: const Text('Scan Again'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: 'Find Recipes',
                icon: Icons.auto_awesome_rounded,
                onPressed: draft.isEmpty ? null : () => _confirmAndFindRecipes(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
