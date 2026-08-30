import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Large rounded primary CTA button with a subtle scale-down press
/// animation, per the "button press feedback" animation requirement.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _scale = pressed ? 0.96 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = widget.onPressed == null || widget.isLoading;

    final button = ElevatedButton(
      onPressed: disabled ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
        minimumSize: const Size(0, 58),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      child: widget.isLoading
          ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.foregroundColor ?? Colors.white,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: widget.foregroundColor ?? Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );

    final animated = AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: button,
    );

    final gestureWrapped = GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: animated,
    );

    return widget.expand ? SizedBox(width: double.infinity, child: gestureWrapped) : gestureWrapped;
  }
}
