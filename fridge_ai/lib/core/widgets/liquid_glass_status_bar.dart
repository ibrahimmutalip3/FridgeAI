import 'dart:ui';

import 'package:flutter/material.dart';

/// A translucent, frosted-glass strip pinned to the very top of the
/// screen, exactly as tall as the status bar (+ a little extra so the
/// blur has room to taper). Used everywhere the app needs the status bar
/// to sit on top of scrolling content — home feed, photo headers, list
/// screens — so time/battery/signal always read clearly no matter what's
/// underneath (a photo, a solid color, or scrolling text).
///
/// This does not host any content of its own — it is purely the visual
/// "glass" layer. Place it last in a [Stack] (on top of everything else)
/// and let your actual header content (title, back button, avatar…) sit
/// in its own layer above or below it as the screen needs. For the common
/// case of an [AppBar] that should get this treatment, wrap it with
/// [LiquidGlassAppBar] instead, which handles the layering for you.
class LiquidGlassStatusBar extends StatelessWidget {
  const LiquidGlassStatusBar({
    super.key,
    this.extraHeight = 12,
    this.blurSigma = 18,
    this.tintOpacity = 0.16,
  });

  /// Extra height below the status bar itself, so the frosted effect and
  /// its fade-out have a little room rather than cutting off abruptly
  /// right at the status bar boundary.
  final double extraHeight;

  /// Blur strength — matches the soft, heavy blur of iOS/Android's
  /// system "liquid glass" materials rather than a light UI blur.
  final double blurSigma;

  /// How strongly the frosted tint reads over whatever is behind it.
  /// Kept low so it reads as "glass over content" rather than a flat bar.
  final double tintOpacity;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tint = isDark ? Colors.black : Colors.white;

    return IgnorePointer(
      child: ClipRect(
        child: SizedBox(
          height: topInset + extraHeight,
          width: double.infinity,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    tint.withValues(alpha: tintOpacity),
                    tint.withValues(alpha: tintOpacity * 0.35),
                    tint.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Drop-in replacement for using an [AppBar] directly when a screen wants
/// the frosted "liquid glass" status-bar treatment: makes the app bar
/// itself transparent and blurred, and — when [extendBodyBehindAppBar] is
/// true on the parent [Scaffold] — lets whatever scrolls underneath (a
/// photo header, a list) show through the glass rather than sitting under
/// a flat, opaque bar.
///
/// Usage is the same as a normal `appBar:` — pass your existing [AppBar]'s
/// properties through, or wrap an existing [AppBar] instance via
/// [LiquidGlassAppBar.wrap].
class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LiquidGlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle,
    this.automaticallyImplyLeading = true,
    this.foregroundColor,
    this.tintOpacity = 0.16,
  });

  /// Wraps an existing [AppBar] configuration so screens that already
  /// build one don't need to duplicate its properties by hand.
  factory LiquidGlassAppBar.wrap(AppBar appBar, {double tintOpacity = 0.16}) => LiquidGlassAppBar(
        title: appBar.title,
        leading: appBar.leading,
        actions: appBar.actions,
        centerTitle: appBar.centerTitle,
        automaticallyImplyLeading: appBar.automaticallyImplyLeading,
        foregroundColor: appBar.foregroundColor,
        tintOpacity: tintOpacity,
      );

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool? centerTitle;
  final bool automaticallyImplyLeading;

  /// Color for the title/icons — pass [Colors.white] for app bars that sit
  /// on top of a photo header, or leave null to use the theme default for
  /// app bars over a plain background.
  final Color? foregroundColor;

  /// How strongly the frosted tint reads. Photo headers usually want this
  /// lower (glass over an already-busy image); plain-background app bars
  /// can use the default.
  final double tintOpacity;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tint = isDark ? Colors.black : Colors.white;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AppBar(
          title: title,
          leading: leading,
          actions: actions,
          centerTitle: centerTitle,
          automaticallyImplyLeading: automaticallyImplyLeading,
          foregroundColor: foregroundColor,
          iconTheme: foregroundColor != null ? IconThemeData(color: foregroundColor) : null,
          backgroundColor: tint.withValues(alpha: tintOpacity),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
    );
  }
}
