import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Baseline soft, rounded card container used throughout the app —
/// no sharp corners, no aggressive shadows.
///
/// When [onTap] is set, the whole card scales down very slightly on press
/// (in addition to the ink ripple) — the same restrained tactile cue
/// [PrimaryButton] already uses, so every tappable surface in the app
/// responds to touch consistently rather than only the button doing it.
class SoftCard extends StatefulWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.borderRadius,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? color;

  @override
  State<SoftCard> createState() => _SoftCardState();
}

class _SoftCardState extends State<SoftCard> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    if (widget.onTap == null) return;
    setState(() => _scale = pressed ? 0.98 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = widget.borderRadius ?? BorderRadius.circular(AppSpacing.radiusMd);

    final card = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color ?? theme.cardTheme.color,
        borderRadius: radius,
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: radius,
            child: card,
          ),
        ),
      ),
    );
  }
}
