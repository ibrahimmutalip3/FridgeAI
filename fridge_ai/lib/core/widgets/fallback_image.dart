import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Image widget that never lets a failed load break the UI.
///
/// Resolution order:
///  1. If [networkUrl] is provided, try loading it (with a shimmer while
///     loading).
///  2. On network failure, or if no [networkUrl] was given, fall back to
///     [assetPath] (a bundled local placeholder).
///  3. If even the asset fails to decode, fall back to a soft icon tile —
///     this widget can never throw visibly.
class FallbackImage extends StatelessWidget {
  const FallbackImage({
    super.key,
    required this.assetPath,
    this.networkUrl,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.icon = Icons.restaurant_rounded,
  });

  final String assetPath;
  final String? networkUrl;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusMd);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = isDark ? AppColors.darkCream : AppColors.lightCream;

    Widget child;
    if (networkUrl != null && networkUrl!.trim().isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: networkUrl!,
        fit: fit,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: tileColor,
          highlightColor: isDark ? AppColors.darkBeige : AppColors.lightBeige,
          child: Container(color: tileColor),
        ),
        errorWidget: (context, url, error) => _AssetOrIcon(
          assetPath: assetPath,
          fit: fit,
          icon: icon,
          tileColor: tileColor,
        ),
      );
    } else {
      child = _AssetOrIcon(assetPath: assetPath, fit: fit, icon: icon, tileColor: tileColor);
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox.expand(child: child),
    );
  }
}

class _AssetOrIcon extends StatelessWidget {
  const _AssetOrIcon({
    required this.assetPath,
    required this.fit,
    required this.icon,
    required this.tileColor,
  });

  final String assetPath;
  final BoxFit fit;
  final IconData icon;
  final Color tileColor;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        color: tileColor,
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.primaryOrange, size: 32),
      ),
    );
  }
}
