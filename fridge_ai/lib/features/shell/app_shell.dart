import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Bottom-navigation shell: Home, Recipes, (floating) Scan, Profile.
/// The Scan action is visually emphasized as a raised rounded floating
/// button per the design spec, sitting centered over the nav bar.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Tracks the previous tab so the cross-fade can slide in the direction
  // that matches how far the user moved across the bottom bar (e.g. Home
  // -> Profile drifts right-to-left, Profile -> Home drifts the opposite
  // way), rather than every switch using the same generic motion.
  int _previousIndex = 0;

  void _goBranch(int index) {
    if (index != widget.navigationShell.currentIndex) {
      _previousIndex = widget.navigationShell.currentIndex;
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = widget.navigationShell.currentIndex;
    final movingForward = currentIndex >= _previousIndex;

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          // Only the incoming tab should slide in from the side; the
          // outgoing one simply fades out in place, which reads as a much
          // cleaner "switch" than both tabs sliding past each other.
          final isIncoming = child.key == ValueKey(currentIndex);
          final beginOffset = isIncoming
              ? Offset(movingForward ? 0.06 : -0.06, 0)
              : Offset.zero;
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(animation),
              child: child,
            ),
          );
        },
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topLeft,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        child: KeyedSubtree(
          key: ValueKey(currentIndex),
          child: widget.navigationShell,
        ),
      ),
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
              outlinedIcon: Icons.home_outlined,
              label: 'Home',
              selected: currentIndex == 0,
              onTap: () => _goBranch(0),
            ),
            _NavItem(
              icon: Icons.menu_book_rounded,
              outlinedIcon: Icons.menu_book_outlined,
              label: 'Recipes',
              selected: currentIndex == 1,
              onTap: () => _goBranch(1),
            ),
            const SizedBox(width: 56), // space for the docked Scan FAB
            _NavItem(
              icon: Icons.kitchen_rounded,
              outlinedIcon: Icons.kitchen_outlined,
              label: 'Kitchen',
              selected: currentIndex == 2,
              onTap: () => _goBranch(2),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              outlinedIcon: Icons.person_outline_rounded,
              label: 'Profile',
              selected: currentIndex == 3,
              onTap: () => _goBranch(3),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single bottom-nav destination. On selection it cross-fades from the
/// outlined to the filled icon variant (a common, subtle "arrived" cue),
/// scales up slightly, and grows a soft rounded highlight behind it — all
/// driven by cheap implicit animations so four of these animating at once
/// stays smooth on any device.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? AppColors.primaryOrange
        : theme.colorScheme.onSurface.withValues(alpha: 0.45);

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
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
                duration: _duration,
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: _duration,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryOrange.withValues(alpha: 0.14) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: _duration,
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                    child: Icon(
                      selected ? icon : outlinedIcon,
                      key: ValueKey(selected),
                      color: color,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: _duration,
                curve: Curves.easeOutCubic,
                style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
