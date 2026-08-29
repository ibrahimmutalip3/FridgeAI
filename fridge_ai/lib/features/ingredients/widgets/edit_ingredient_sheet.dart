import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/ingredient.dart';

/// Rounded bottom sheet for editing an existing ingredient, or (when
/// [ingredient] is null) adding a brand new one manually.
class EditIngredientSheet extends StatefulWidget {
  const EditIngredientSheet({super.key, required this.ingredient});

  final Ingredient? ingredient;

  @override
  State<EditIngredientSheet> createState() => _EditIngredientSheetState();
}

class _EditIngredientSheetState extends State<EditIngredientSheet> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.ingredient?.name ?? '');
  late final TextEditingController _quantityController =
      TextEditingController(text: widget.ingredient?.quantity ?? '');
  late IngredientCategory _category = widget.ingredient?.category ?? IngredientCategory.pantry;
  DateTime? _expirationDate = widget.ingredient?.expirationDate;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiration() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final quantity = _quantityController.text.trim().isEmpty ? '1' : _quantityController.text.trim();

    final result = widget.ingredient?.copyWith(
          name: name,
          quantity: quantity,
          category: _category,
          expirationDate: _expirationDate,
          clearExpirationDate: _expirationDate == null,
        ) ??
        Ingredient(
          name: name,
          quantity: quantity,
          category: _category,
          expirationDate: _expirationDate,
        );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.ingredient != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(isEditing ? 'Edit Ingredient' : 'Add Ingredient', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Tomatoes'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity', hintText: 'e.g. 3 or 500 g'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IngredientCategory.values.map((category) {
                final selected = category == _category;
                return ChoiceChip(
                  label: Text(category.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = category),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _expirationDate == null
                        ? 'No expiration date set'
                        : 'Expires ${_expirationDate!.month}/${_expirationDate!.day}/${_expirationDate!.year}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: _pickExpiration,
                  child: Text(_expirationDate == null ? 'Set date' : 'Change'),
                ),
                if (_expirationDate != null)
                  IconButton(
                    onPressed: () => setState(() => _expirationDate = null),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: isEditing ? 'Save Changes' : 'Add Ingredient', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
