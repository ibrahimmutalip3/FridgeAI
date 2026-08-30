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
import '../ingredients/widgets/edit_ingredient_sheet.dart';
import '../ingredients/widgets/ingredient_card.dart';

/// "My Kitchen" — the persisted pantry, organized into category sections
/// (Vegetables, Meat, Dairy, Fruits, Grains, Pantry) with add/scan actions.
class MyKitchenScreen extends ConsumerStatefulWidget {
  const MyKitchenScreen({super.key});

  @override
  ConsumerState<MyKitchenScreen> createState() => _MyKitchenScreenState();
}

class _MyKitchenScreenState extends ConsumerState<MyKitchenScreen> {
  // One removal-animation key per ingredient id — see the matching pattern
  // (and rationale) in IngredientResultsScreen.
  final _removalKeys = <String, GlobalKey<AnimatedRemovalState>>{};

  GlobalKey<AnimatedRemovalState> _keyFor(String id) {
    return _removalKeys.putIfAbsent(id, () => GlobalKey<AnimatedRemovalState>());
  }

  Future<void> _addIngredient(BuildContext context) async {
    final result = await showModalBottomSheet<Ingredient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EditIngredientSheet(ingredient: null),
    );
    if (result != null) {
      await ref.read(pantryProvider.notifier).addIngredient(result);
    }
  }

  Future<void> _editIngredient(BuildContext context, Ingredient ingredient) async {
    final result = await showModalBottomSheet<Ingredient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditIngredientSheet(ingredient: ingredient),
    );
    if (result != null) {
      await ref.read(pantryProvider.notifier).updateIngredient(result);
    }
  }

  /// Called once (and only once) per ingredient, either by [IngredientCard]'s
  /// delete button (which starts the exit animation) or, as a fallback, if
  /// the removal key was somehow already gone. This must be the single path
  /// that actually mutates persisted pantry state — see the matching note
  /// in [AnimatedRemoval.onRemoved] below.
  Future<void> _removeIngredient(String id) async {
    final state = _removalKeys[id]?.currentState;
    _removalKeys.remove(id);
    if (state != null) {
      // Plays the exit animation; AnimatedRemoval calls onRemoved itself
      // once it finishes, which is what actually removes the ingredient
      // from the persisted pantry (see onRemoved below). Do not also
      // remove it here — that would just be a no-op second call into an
      // already-animating/already-removed AnimatedRemovalState.
      await state.remove();
    } else {
      await ref.read(pantryProvider.notifier).removeIngredient(id);
    }
  }

  /// Builds the ordered list of non-empty category sections, each carrying
  /// a running [_SectionEntry.startIndex] so the entrance stagger continues
  /// smoothly across section boundaries instead of restarting at 0 for
  /// every category (which previously made whole sections fade in at once).
  List<_SectionEntry> _sectionsWithStartIndex(Map<IngredientCategory, List<Ingredient>> grouped) {
    final entries = <_SectionEntry>[];
    var runningIndex = 0;
    for (final category in IngredientCategory.values) {
      final ingredients = grouped[category]!;
      if (ingredients.isEmpty) continue;
      entries.add(_SectionEntry(category: category, ingredients: ingredients, startIndex: runningIndex));
      runningIndex += ingredients.length;
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = ref.watch(pantryGroupedProvider);
    final isEmpty = grouped.values.every((list) => list.isEmpty);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: LiquidGlassAppBar(
        title: Text(
          'My Kitchen',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.scanner),
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
            tooltip: 'Scan Kitchen',
          ),
        ],
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
            child: isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: kToolbarHeight),
                    child: Center(
                      child: EmptyState(
                        icon: Icons.kitchen_outlined,
                        title: 'Your kitchen is empty',
                        message: 'Scan your fridge or pantry, or add ingredients manually.',
                        actionLabel: 'Scan Kitchen',
                        onAction: () => context.push(AppRoutes.scanner),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      kToolbarHeight + AppSpacing.md,
                      AppSpacing.lg,
                      140,
                    ),
                    children: [
                      for (final entry in _sectionsWithStartIndex(grouped))
                        _CategorySection(
                          category: entry.category,
                          ingredients: entry.ingredients,
                          startIndex: entry.startIndex,
                          keyFor: _keyFor,
                          onEdit: (ingredient) => _editIngredient(context, ingredient),
                          onDelete: _removeIngredient,
                        ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.scanner),
                        icon: const Icon(Icons.camera_alt_outlined, size: 20),
                        label: const Text('Scan Kitchen'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Add Ingredient',
                        icon: Icons.add_rounded,
                        onPressed: () => _addIngredient(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// A single category section paired with the running entrance-stagger index
/// its first ingredient card should use (see [MyKitchenScreen._sectionsWithStartIndex]).
class _SectionEntry {
  const _SectionEntry({required this.category, required this.ingredients, required this.startIndex});

  final IngredientCategory category;
  final List<Ingredient> ingredients;
  final int startIndex;
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.ingredients,
    required this.startIndex,
    required this.keyFor,
    required this.onEdit,
    required this.onDelete,
  });

  final IngredientCategory category;
  final List<Ingredient> ingredients;
  final int startIndex;
  final GlobalKey<AnimatedRemovalState> Function(String id) keyFor;
  final void Function(Ingredient) onEdit;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.label, style: theme.textTheme.headlineSmall),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${ingredients.length}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < ingredients.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: EntranceFade(
                index: startIndex + i,
                child: Builder(
                  builder: (context) {
                    final removalKey = keyFor(ingredients[i].id);
                    return AnimatedRemoval(
                      key: removalKey,
                      // The only place real state is mutated — runs once
                      // the exit animation finishes.
                      onRemoved: () => onDelete(ingredients[i].id),
                      child: IngredientCard(
                        ingredient: ingredients[i],
                        onEdit: () => onEdit(ingredients[i]),
                        // Route through the same onDelete (-> _removeIngredient)
                        // that AnimatedRemoval.onRemoved uses, instead of
                        // poking removalKey.currentState directly — a second,
                        // independent entry point here previously caused the
                        // ingredient to only *appear* removed (animation
                        // played) without ever actually being deleted from
                        // the persisted pantry.
                        onDelete: () => onDelete(ingredients[i].id),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
