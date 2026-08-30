import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A single shimmering rounded-rect bone, the basic building block for
/// every skeleton layout below. Sized and positioned to mirror the real
/// content it stands in for, so the transition from skeleton -> content
/// doesn't cause a layout jump.
class _Bone extends StatelessWidget {
  const _Bone({this.width, this.height = 14, this.borderRadius});

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCream : AppColors.lightCream,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.xs),
      ),
    );
  }
}

/// Wraps a skeleton layout in a single shimmer sweep, using the same
/// palette [FallbackImage] already uses for its own loading shimmer so the
/// whole app's "loading" language stays consistent.
class SkeletonShimmer extends StatelessWidget {
  const SkeletonShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkCream : AppColors.lightCream,
      highlightColor: isDark ? AppColors.darkBeige : AppColors.lightBeige,
      child: child,
    );
  }
}

/// Skeleton placeholder mirroring [RecipeCard]'s exact geometry (92x92
/// image, two-line title, pill row, match badge) — used while recipes are
/// generating so the loading state already reads as "recipes are coming"
/// rather than a generic spinner.
class RecipeCardSkeleton extends StatelessWidget {
  const RecipeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bone(
            width: 92,
            height: 92,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Bone(width: double.infinity, height: 15),
                const SizedBox(height: 8),
                _Bone(width: 120, height: 15),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Bone(width: 56, height: 22, borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                    const SizedBox(width: AppSpacing.sm),
                    _Bone(width: 64, height: 22, borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                  ],
                ),
                const SizedBox(height: 8),
                _Bone(width: 96, height: 20, borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A vertically stacked list of [RecipeCardSkeleton]s under one shimmer
/// sweep, used as the Recipe Results loading state.
class RecipeListSkeleton extends StatelessWidget {
  const RecipeListSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => const RecipeCardSkeleton(),
      ),
    );
  }
}

/// Skeleton placeholder mirroring [IngredientCard]'s geometry (56x56
/// image, name + quantity lines) — available for any screen that needs an
/// ingredient-shaped loading state.
class IngredientCardSkeleton extends StatelessWidget {
  const IngredientCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Row(
        children: [
          _Bone(width: 56, height: 56, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bone(width: 140, height: 15),
                const SizedBox(height: 8),
                _Bone(width: 70, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
