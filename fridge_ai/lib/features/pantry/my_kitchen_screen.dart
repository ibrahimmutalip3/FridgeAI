import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance_fade.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/screen_header_background.dart';
import '../../models/ingredient.dart';
import '../../providers/pantry_providers.dart';
import '../ingredients/widgets/edit_ingredient_sheet.dart';
import '../ingredients/widgets/ingredient_card.dart';

/// "My Kitchen" — the persisted pantry, organized into category sections
/// (Vegetables, Meat, Dairy, Fruits, Grains, Pantry) with add/scan actions.
class MyKitchenScreen extends ConsumerWidget {
  const MyKitchenScreen({super.key});

  Future<void> _addIngredient(BuildContext context, WidgetRef ref) async {
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

  Future<void> _editIngredient(BuildContext context, WidgetRef ref, Ingredient ingredient) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(pantryGroupedProvider);
    final isEmpty = grouped.values.every((list) => list.isEmpty);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Kitchen',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      kToolbarHeight + AppSpacing.md,
                      AppSpacing.lg,
                      140,
                    ),
                    children: [
                      for (final category in IngredientCategory.values)
                        if (grouped[category]!.isNotEmpty)
                          _CategorySection(
                            category: category,
                            ingredients: grouped[category]!,
                            onEdit: (ingredient) => _editIngredient(context, ref, ingredient),
                            onDelete: (id) => ref.read(pantryProvider.notifier).removeIngredient(id),
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
                        onPressed: () => _addIngredient(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.ingredients,
    required this.onEdit,
    required this.onDelete,
  });

  final IngredientCategory category;
  final List<Ingredient> ingredients;
  final void Function(Ingredient) onEdit;
  final void Function(String) onDelete;

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
                index: i,
                child: IngredientCard(
                  ingredient: ingredients[i],
                  onEdit: () => onEdit(ingredients[i]),
                  onDelete: () => onDelete(ingredients[i].id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
