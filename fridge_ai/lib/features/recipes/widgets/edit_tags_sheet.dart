import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';

/// Rounded bottom sheet for editing a free-text list of tags (dietary
/// preferences, allergies, favorite cuisines) via a simple chip input.
class EditTagsSheet extends StatefulWidget {
  const EditTagsSheet({super.key, required this.title, required this.initialTags});

  final String title;
  final List<String> initialTags;

  @override
  State<EditTagsSheet> createState() => _EditTagsSheetState();
}

class _EditTagsSheetState extends State<EditTagsSheet> {
  late final List<String> _tags = List.of(widget.initialTags);
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    if (_tags.any((t) => t.toLowerCase() == trimmed.toLowerCase())) {
      _inputController.clear();
      return;
    }
    setState(() {
      _tags.add(trimmed);
      _inputController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            Text(widget.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _inputController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type and press add',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_rounded, color: AppColors.primaryOrange),
                  onPressed: () => _addTag(_inputController.text),
                ),
              ),
              onSubmitted: _addTag,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_tags.isEmpty)
              Text('Nothing added yet.', style: theme.textTheme.bodySmall)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => _removeTag(tag),
                        ))
                    .toList(),
              ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Save',
              onPressed: () => Navigator.of(context).pop(_tags),
            ),
          ],
        ),
      ),
    );
  }
}
