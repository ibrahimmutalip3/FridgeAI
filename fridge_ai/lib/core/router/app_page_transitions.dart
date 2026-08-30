import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared page-transition recipes for [GoRoute]s, applied consistently
/// across the app so navigation always feels intentional instead of
/// falling back to the platform default slide.
///
/// Follows a simple motion hierarchy:
///  - [AppPageTransitions.reveal] — for moments that deserve emphasis (the
///    scan → AI analysis → results flow): a soft fade + gentle scale-up, as
///    if the next screen is surfacing from underneath the current one.
///  - [AppPageTransitions.forward] — the default for routine push
///    navigation (recipe details, cooking mode, settings-style sheets): a
///    restrained fade + slide-from-right, quicker and less showy than
///    [reveal].
///  - [AppPageTransitions.fade] — for cross-fades where a slide would read
///    as spatially wrong (e.g. modal-like full-screen takeovers).
///
/// All durations stay within the "full-screen navigation ≤ 500ms" budget,
/// with exits always shorter than enters.
class AppPageTransitions {
  AppPageTransitions._();

  static const Duration _revealDuration = Duration(milliseconds: 420);
  static const Duration _forwardDuration = Duration(milliseconds: 320);
  static const Duration _fadeDuration = Duration(milliseconds: 260);

  /// Emphasized transition for key AI/scan moments — fade + slight scale +
  /// upward drift, so the destination feels like it's surfacing rather than
  /// sliding in from off-screen.
  static Page<T> reveal<T>({required Widget child, required GoRouterState state}) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: _revealDuration,
      reverseTransitionDuration: Duration(milliseconds: (_revealDuration.inMilliseconds * 0.7).round()),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final entering = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

        return FadeTransition(
          opacity: entering,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - entering.value)),
            child: Transform.scale(
              scale: 0.97 + (0.03 * entering.value),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Standard forward navigation — restrained fade + slide-from-right.
  /// Used for most pushed routes (recipe details, cooking mode).
  static Page<T> forward<T>({required Widget child, required GoRouterState state}) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: _forwardDuration,
      reverseTransitionDuration: Duration(milliseconds: (_forwardDuration.inMilliseconds * 0.75).round()),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final entering = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final primaryOffset = Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(entering);

        return FadeTransition(
          opacity: entering,
          child: SlideTransition(position: primaryOffset, child: child),
        );
      },
    );
  }

  /// Modal-style slide-up-from-bottom, used for full-screen tool takeovers
  /// (the camera scanner) where the destination is a temporary overlay
  /// rather than "the next page in a stack" — communicates that context,
  /// mirroring the iOS/Android modal-presentation convention.
  static Page<T> modalUp<T>({required Widget child, required GoRouterState state}) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: _forwardDuration,
      reverseTransitionDuration: Duration(milliseconds: (_forwardDuration.inMilliseconds * 0.75).round()),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final entering = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(entering);

        return FadeTransition(
          opacity: entering,
          child: SlideTransition(position: offset, child: child),
        );
      },
    );
  }

  /// Simple cross-fade — used where a directional slide would be spatially
  /// misleading.
  static Page<T> fade<T>({required Widget child, required GoRouterState state}) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: _fadeDuration,
      reverseTransitionDuration: Duration(milliseconds: (_fadeDuration.inMilliseconds * 0.75).round()),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }
}
