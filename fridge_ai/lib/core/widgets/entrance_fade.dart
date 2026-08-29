import 'package:flutter/material.dart';

/// Staggered fade + slide-up entrance animation, used for ingredient cards,
/// recipe cards, and other list items appearing on screen.
class EntranceFade extends StatelessWidget {
  const EntranceFade({
    super.key,
    required this.child,
    this.index = 0,
    this.delayPerItem = const Duration(milliseconds: 45),
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final delayMs = (delayPerItem.inMilliseconds * index).clamp(0, 600);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + Duration(milliseconds: delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Hold at 0 for the delay portion, then animate — approximated by
        // easing the whole duration since TweenAnimationBuilder has no
        // native delay; the staggered total duration achieves the
        // staggered visual effect across a list without extra controllers.
        final eased = Curves.easeOutCubic.transform(value);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
