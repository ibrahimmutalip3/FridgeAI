import 'package:flutter/material.dart';

/// Wraps a list item so that deleting it plays a short shrink + fade + drift
/// exit animation *before* the underlying state actually removes it, rather
/// than the item just vanishing the instant the delete callback runs.
///
/// This intentionally avoids `AnimatedList` (which needs the parent to own
/// an explicit, mutable index-keyed list controller) so it can drop into
/// screens backed by simple immutable-list Riverpod state — such as the
/// pantry and scan-draft providers — without changing how that state is
/// modeled. The widget owns only the exit animation; the actual removal
/// (calling [onRemoved]) is deferred until the animation finishes, and the
/// widget's [key] should stay the same across rebuilds (e.g. the
/// ingredient's id) so Flutter doesn't recreate it mid-animation.
class AnimatedRemoval extends StatefulWidget {
  const AnimatedRemoval({
    super.key,
    required this.child,
    required this.onRemoved,
    this.duration = const Duration(milliseconds: 240),
  });

  final Widget child;

  /// Called once the exit animation finishes — this is where the caller
  /// should actually mutate state (e.g. `ref.read(...).remove(id)`).
  final VoidCallback onRemoved;

  final Duration duration;

  @override
  State<AnimatedRemoval> createState() => AnimatedRemovalState();
}

class AnimatedRemovalState extends State<AnimatedRemoval> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  bool _removing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Plays the exit animation, then invokes [AnimatedRemoval.onRemoved].
  /// Safe to call multiple times — only the first call has any effect.
  Future<void> remove() async {
    if (_removing) return;
    _removing = true;
    await _controller.forward();
    if (!mounted) return;
    widget.onRemoved();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeInCubic);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 1 - t,
            child: Opacity(
              opacity: 1 - t,
              child: Transform.translate(
                offset: Offset(24 * t, 0),
                child: child,
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
