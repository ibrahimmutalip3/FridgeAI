import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance_fade.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/ingredient.dart';
import '../../providers/pantry_providers.dart';
import '../../providers/recipe_providers.dart';
import 'widgets/edit_ingredient_sheet.dart';
import 'widgets/ingredient_card.dart';

class IngredientResultsScreen extends ConsumerWidget {
  const IngredientResultsScreen({super.key});

  Future<void> _editIngredient(BuildContext context, WidgetRef ref, Ingredient ingredient) async {
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

  Future<void> _addIngredient(BuildContext context, WidgetRef ref) async {
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

  Future<void> _confirmAndFindRecipes(BuildContext context, WidgetRef ref) async {
    final draft = ref.read(scanDraftProvider);
    if (draft.isEmpty) return;

    await ref.read(pantryProvider.notifier).addIngredients(draft);
    ref.read(scanDraftProvider.notifier).clear();

    if (!context.mounted) return;
    ref.read(recipeGenerationProvider.notifier).generate(draft);
    context.pushReplacement(AppRoutes.recipeResults);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(scanDraftProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Here\u2019s what I found')),
      body: SafeArea(
        child: draft.isEmpty
            ? EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No ingredients here yet',
                message: 'Add an ingredient manually, or head back and rescan.',
                actionLabel: 'Add Ingredient',
                onAction: () => _addIngredient(context, ref),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 160),
                itemCount: draft.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final ingredient = draft[index];
                  return EntranceFade(
                    index: index,
                    child: IngredientCard(
                      ingredient: ingredient,
                      onEdit: () => _editIngredient(context, ref, ingredient),
                      onDelete: () => ref.read(scanDraftProvider.notifier).remove(ingredient.id),
                    ),
                  );
                },
              ),
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
                      onPressed: () => _addIngredient(context, ref),
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
                onPressed: draft.isEmpty ? null : () => _confirmAndFindRecipes(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
