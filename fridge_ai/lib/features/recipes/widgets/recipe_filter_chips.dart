import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/recipe.dart';
import '../../../providers/recipe_providers.dart';

/// Horizontal scrollable filter chip row (Quick, Easy, Medium, High
/// Protein, Vegetarian, Breakfast, Lunch, Dinner, Dessert) plus an "All"
/// chip that clears the filter.
class RecipeFilterChips extends ConsumerWidget {
  const RecipeFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(recipeFilterProvider);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () => ref.read(recipeFilterProvider.notifier).state = null,
          ),
          for (final tag in RecipeTag.values)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _Chip(
                label: tag.label,
                selected: selected == tag,
                onTap: () => ref.read(recipeFilterProvider.notifier).state = tag,
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

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
