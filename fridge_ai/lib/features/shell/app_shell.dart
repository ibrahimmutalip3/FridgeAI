import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Bottom-navigation shell: Home, Recipes, (floating) Scan, Profile.
/// The Scan action is visually emphasized as a raised rounded floating
/// button per the design spec, sitting centered over the nav bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: SizedBox(
          height: 66,
          width: 66,
          child: FloatingActionButton(
            heroTag: 'scan_fab',
            elevation: 2,
            backgroundColor: AppColors.primaryOrange,
            shape: const CircleBorder(),
            onPressed: () => context.push(AppRoutes.scanner),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        elevation: 0,
        height: 68,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: navigationShell.currentIndex == 0,
              onTap: () => _goBranch(0),
            ),
            _NavItem(
              icon: Icons.menu_book_rounded,
              label: 'Recipes',
              selected: navigationShell.currentIndex == 1,
              onTap: () => _goBranch(1),
            ),
            const SizedBox(width: 56), // space for the docked Scan FAB
            _NavItem(
              icon: Icons.kitchen_rounded,
              label: 'Kitchen',
              selected: navigationShell.currentIndex == 2,
              onTap: () => _goBranch(2),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              selected: navigationShell.currentIndex == 3,
              onTap: () => _goBranch(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? AppColors.primaryOrange
        : theme.colorScheme.onSurface.withValues(alpha: 0.45);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
