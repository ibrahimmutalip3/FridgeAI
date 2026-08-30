import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../services/recipe_image_resolver.dart';
import '../theme/app_colors.dart';

/// A real, static photo pinned to the top of a screen that fades smoothly
/// into the scaffold background further down — used to give the Home
/// screen and the "My Kitchen" / ingredients screen a bit of warmth and
/// realism without hurting text legibility.
///
/// Usage: wrap the screen's `Scaffold` body in a `Stack`, put this widget
/// first (so it sits behind everything, pinned to the top), then lay the
/// normal scrollable content on top with a transparent app bar / top
/// padding to match.
///
/// The photo is resolved via [RecipeImageResolver.urlForQuery] using a
/// **fixed** search phrase per screen (see [ScreenBackgrounds]) — not
/// derived from the user's actual pantry — so it's a stable, predictable
/// "theme photo" rather than something that changes as their fridge
/// contents change. It reuses the exact same Unsplash Search API path (and
/// in-memory cache) already used for recipe/ingredient photos elsewhere in
/// the app, so it needs no extra setup beyond the `UNSPLASH_ACCESS_KEY`
/// that's already wired into CI. If the lookup fails or no key is
/// configured, it quietly falls back to a soft themed gradient — the
/// screen never looks broken.
class ScreenHeaderBackground extends StatefulWidget {
  const ScreenHeaderBackground({
    super.key,
    required this.query,
    this.height = 300,
  });

  /// Fixed Unsplash search phrase for this screen's theme photo, e.g.
  /// "fresh vegetables flat lay". Kept constant regardless of the user's
  /// actual pantry contents — see [ScreenBackgrounds] for the ones used
  /// across the app.
  final String query;

  /// How tall the photo area is before it's fully faded out.
  final double height;

  @override
  State<ScreenHeaderBackground> createState() => _ScreenHeaderBackgroundState();
}

class _ScreenHeaderBackgroundState extends State<ScreenHeaderBackground> {
  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = RecipeImageResolver.urlForQuery(widget.query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final placeholderTile = isDark ? AppColors.darkCream : AppColors.lightCream;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0.0, 0.42, 1.0],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<String>(
              future: _urlFuture,
              builder: (context, snapshot) {
                final url = snapshot.data;
                if (url == null || url.isEmpty) {
                  // Still loading, or resolution failed / no API key —
                  // either way, show a soft themed gradient instead of a
                  // broken image or an indefinite shimmer at the top of
                  // the screen.
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [AppColors.darkCream, AppColors.darkBackground]
                            : [AppColors.lightCream, AppColors.lightBackground],
                      ),
                    ),
                  );
                }
                return CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 400),
                  placeholder: (context, url) => Container(color: placeholderTile),
                  errorWidget: (context, url, error) => DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [AppColors.darkCream, AppColors.darkBackground]
                            : [AppColors.lightCream, AppColors.lightBackground],
                      ),
                    ),
                  ),
                );
              },
            ),
            // A gentle scrim near the very top so status-bar icons / header
            // text sitting directly on the photo stay legible on any photo.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: widget.height * 0.4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.22),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Final blend into the exact scaffold background color so the
            // seam where the photo ends is invisible, not just "faded".
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: widget.height * 0.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      backgroundColor.withValues(alpha: 0.0),
                      backgroundColor,
                    ],
                    stops: const [0.0, 0.92],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Curated, fixed background photo search phrases for screens that use
/// [ScreenHeaderBackground]. Kept constant on purpose (not derived from
/// pantry contents), so each screen has one stable, well-composed "theme
/// photo" rather than a background that jumps around as ingredients are
/// added/removed.
class ScreenBackgrounds {
  ScreenBackgrounds._();

  /// Warm, overhead flat-lay of fresh produce — behind the Home screen
  /// header.
  static const String home = 'fresh produce flat lay overhead';

  /// Bright, colorful ingredients close-up — behind the "My Kitchen" /
  /// ingredients list header.
  static const String kitchen = 'colorful vegetables kitchen counter';

  /// Warm, cozy home-cooking scene — behind the Profile screen header.
  static const String profile = 'cozy home cooking warm kitchen';
}
