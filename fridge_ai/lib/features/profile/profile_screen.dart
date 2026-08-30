import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/soft_card.dart';
import '../../models/user_preferences.dart';
import '../../providers/preferences_providers.dart';
import '../recipes/widgets/edit_tags_sheet.dart';

/// Profile — avatar, cooking stats, dietary/allergy/cuisine preferences,
/// and app settings (theme, notifications).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Alex'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(preferencesProvider.notifier).setUserName(result);
    }
  }

  Future<void> _editTags({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required List<String> current,
    required Future<void> Function(List<String>) onSave,
  }) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTagsSheet(title: title, initialTags: current),
    );
    if (result != null) {
      await onSave(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final preferences = ref.watch(preferencesProvider);
    final stats = ref.watch(userStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.18),
                    child: Text(
                      preferences.userName.isNotEmpty ? preferences.userName[0].toUpperCase() : 'C',
                      style: theme.textTheme.displayMedium?.copyWith(color: AppColors.primaryOrangeDark),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => _editName(context, ref, preferences.userName),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(preferences.userName, style: theme.textTheme.headlineMedium),
                        const SizedBox(width: 6),
                        Icon(Icons.edit_rounded, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _StatCard(label: 'Recipes cooked', value: '${stats.recipesCooked}'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(label: 'Favorites', value: '${stats.favoritesCount}'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(label: 'Ingredients scanned', value: '${stats.ingredientsScanned}'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Preferences', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            SoftCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _TagsRow(
                    icon: Icons.restaurant_menu_rounded,
                    label: 'Dietary preferences',
                    tags: preferences.dietaryPreferences,
                    onTap: () => _editTags(
                      context: context,
                      ref: ref,
                      title: 'Dietary preferences',
                      current: preferences.dietaryPreferences,
                      onSave: (tags) => ref.read(preferencesProvider.notifier).setDietaryPreferences(tags),
                    ),
                  ),
                  const Divider(height: 1),
                  _TagsRow(
                    icon: Icons.warning_amber_rounded,
                    label: 'Allergies',
                    tags: preferences.allergies,
                    onTap: () => _editTags(
                      context: context,
                      ref: ref,
                      title: 'Allergies',
                      current: preferences.allergies,
                      onSave: (tags) => ref.read(preferencesProvider.notifier).setAllergies(tags),
                    ),
                  ),
                  const Divider(height: 1),
                  _TagsRow(
                    icon: Icons.public_rounded,
                    label: 'Favorite cuisines',
                    tags: preferences.favoriteCuisines,
                    onTap: () => _editTags(
                      context: context,
                      ref: ref,
                      title: 'Favorite cuisines',
                      current: preferences.favoriteCuisines,
                      onSave: (tags) => ref.read(preferencesProvider.notifier).setFavoriteCuisines(tags),
                    ),
                  ),
                  const Divider(height: 1),
                  _ServingSizeRow(preferences: preferences),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Settings', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            SoftCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Appearance', style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                    child: SegmentedButton<AppThemeMode>(
                      segments: const [
                        ButtonSegment(value: AppThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Light')),
                        ButtonSegment(value: AppThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Dark')),
                        ButtonSegment(value: AppThemeMode.system, icon: Icon(Icons.settings_suggest_rounded), label: Text('System')),
                      ],
                      selected: {preferences.themeMode},
                      onSelectionChanged: (selection) =>
                          ref.read(preferencesProvider.notifier).setThemeMode(selection.first),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    value: preferences.notificationsEnabled,
                    onChanged: (value) =>
                        ref.read(preferencesProvider.notifier).setNotificationsEnabled(value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(
      child: Column(
        children: [
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.primaryOrangeDark)),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TagsRow extends StatelessWidget {
  const _TagsRow({
    required this.icon,
    required this.label,
    required this.tags,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<String> tags;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryOrangeDark),
      title: Text(label),
      subtitle: Text(
        tags.isEmpty ? 'None set' : tags.join(', '),
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _ServingSizeRow extends ConsumerWidget {
  const _ServingSizeRow({required this.preferences});

  final UserPreferences preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.groups_2_outlined, color: AppColors.primaryOrangeDark),
      title: const Text('Default serving size'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: preferences.servingSize <= 1
                ? null
                : () => ref.read(preferencesProvider.notifier).setServingSize(preferences.servingSize - 1),
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Text('${preferences.servingSize}', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            onPressed: () => ref.read(preferencesProvider.notifier).setServingSize(preferences.servingSize + 1),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}
