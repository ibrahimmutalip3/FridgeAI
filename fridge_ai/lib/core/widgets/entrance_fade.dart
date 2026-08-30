import 'package:flutter/material.dart';

/// Staggered fade + slide-up entrance animation, used for ingredient cards,
/// recipe cards, and other list items appearing on screen.
///
/// Each item shares one fixed-length timeline (`duration + max stagger
/// window`) but is mapped through an [Interval] scoped to its own index, so
/// item 0 genuinely starts (and finishes) before item 4 does — rather than
/// every item starting at 0 simultaneously and merely taking longer to
/// finish the further down the list it sits, which is what a naive
/// "duration + delayMs" tween produces.
class EntranceFade extends StatelessWidget {
  const EntranceFade({
    super.key,
    required this.child,
    this.index = 0,
    this.delayPerItem = const Duration(milliseconds: 45),
    this.duration = const Duration(milliseconds: 380),
  });

  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;

  /// Cap how far into a long list the stagger keeps growing — beyond this,
  /// items past the fold would otherwise take increasingly long to appear
  /// as the user scrolls to them.
  static const int _maxStaggeredItems = 12;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return child;
    }

    final cappedIndex = index.clamp(0, _maxStaggeredItems);
    final delayMs = delayPerItem.inMilliseconds * cappedIndex;
    final totalMs = duration.inMilliseconds + delayMs;
    final startFraction = totalMs == 0 ? 0.0 : delayMs / totalMs;

    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Interval(startFraction, 1.0, curve: Curves.easeOutCubic),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

