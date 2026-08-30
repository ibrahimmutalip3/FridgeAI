import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/entrance_fade.dart';
import '../../core/widgets/liquid_glass_status_bar.dart';
import '../../core/widgets/screen_header_background.dart';
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

    // Running index for the entrance stagger across every section below,
    // so the whole screen reads as one continuous reveal rather than each
    // block restarting the animation from 0 (same pattern as My Kitchen's
    // category sections).
    var i = 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: LiquidGlassAppBar(
        title: Text(
          'Profile',
          style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
        ),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ScreenHeaderBackground(query: ScreenBackgrounds.profile, height: 260),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                kToolbarHeight + AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                EntranceFade(
                  index: i++,
                  child: Center(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 38,
                                backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.18),
                                child: Text(
                                  preferences.userName.isNotEmpty
                                      ? preferences.userName[0].toUpperCase()
                                      : 'C',
                                  style: theme.textTheme.displayMedium
                                      ?.copyWith(color: AppColors.primaryOrangeDark),
                                ),
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: GestureDetector(
                                onTap: () => _editName(context, ref, preferences.userName),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryOrange,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GestureDetector(
                          onTap: () => _editName(context, ref, preferences.userName),
                          child: Text(
                            preferences.userName,
                            style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                EntranceFade(
                  index: i++,
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.restaurant_rounded,
                          label: 'Recipes cooked',
                          value: '${stats.recipesCooked}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.favorite_rounded,
                          label: 'Favorites',
                          value: '${stats.favoritesCount}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.camera_alt_rounded,
                          label: 'Scanned',
                          value: '${stats.ingredientsScanned}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                EntranceFade(index: i++, child: Text('Preferences', style: theme.textTheme.headlineSmall)),
                const SizedBox(height: AppSpacing.sm),
                EntranceFade(
                  index: i++,
                  child: SoftCard(
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
                            onSave: (tags) =>
                                ref.read(preferencesProvider.notifier).setDietaryPreferences(tags),
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
                            onSave: (tags) =>
                                ref.read(preferencesProvider.notifier).setFavoriteCuisines(tags),
                          ),
                        ),
                        const Divider(height: 1),
                        _ServingSizeRow(preferences: preferences),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                EntranceFade(index: i++, child: Text('Settings', style: theme.textTheme.headlineSmall)),
                const SizedBox(height: AppSpacing.sm),
                EntranceFade(
                  index: i++,
                  child: SoftCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Appearance', style: theme.textTheme.titleMedium),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                          child: _AppearanceSelector(
                            selected: preferences.themeMode,
                            onChanged: (mode) =>
                                ref.read(preferencesProvider.notifier).setThemeMode(mode),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented light/dark/system control with an animated sliding highlight
/// behind the selected option, rather than the stock [SegmentedButton]'s
/// instant selection swap — matches the "state changes animate" motion
/// rule used for the bottom nav and filter chips elsewhere in the app.
class _AppearanceSelector extends StatelessWidget {
  const _AppearanceSelector({required this.selected, required this.onChanged});

  final AppThemeMode selected;
  final ValueChanged<AppThemeMode> onChanged;

  static const _options = [
    (mode: AppThemeMode.light, icon: Icons.light_mode_rounded, label: 'Light'),
    (mode: AppThemeMode.dark, icon: Icons.dark_mode_rounded, label: 'Dark'),
    (mode: AppThemeMode.system, icon: Icons.settings_suggest_rounded, label: 'System'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = _options.indexWhere((o) => o.mode == selected);

    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = constraints.maxWidth / _options.length;
        return Container(
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: theme.dividerColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment(
                  selectedIndex == 0 ? -1 : (selectedIndex == 1 ? 0 : 1),
                  0,
                ),
                child: FractionallySizedBox(
                  widthFactor: 1 / _options.length,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm - 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final option in _options)
                    SizedBox(
                      width: segmentWidth,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm - 2),
                        onTap: () => onChanged(option.mode),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              option.icon,
                              size: 16,
                              color: option.mode == selected
                                  ? AppColors.primaryOrangeDark
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                option.label,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: option.mode == selected
                                      ? AppColors.primaryOrangeDark
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontWeight: option.mode == selected ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryOrangeDark),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.primaryOrangeDark)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// A preference row (dietary preferences, allergies, favorite cuisines)
/// showing each tag as its own small pill — rather than one comma-joined
/// line — so a longer list stays scannable instead of truncating into an
/// ellipsis.
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
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryOrangeDark, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(label, style: theme.textTheme.bodyLarge),
                  ),
                  if (tags.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('None set', style: theme.textTheme.bodySmall),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCream : AppColors.lightCream,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                ),
                                child: Text(tag, style: theme.textTheme.labelSmall),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
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
