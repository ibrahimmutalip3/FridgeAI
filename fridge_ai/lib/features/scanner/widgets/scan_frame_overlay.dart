import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Rounded scanning frame drawn over the camera preview, with animated
/// corner brackets that gently pulse to draw the eye toward framing.
class ScanFrameOverlay extends StatefulWidget {
  const ScanFrameOverlay({super.key});

  @override
  State<ScanFrameOverlay> createState() => _ScanFrameOverlayState();
}

class _ScanFrameOverlayState extends State<ScanFrameOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.8,
        heightFactor: 0.42,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final glow = 0.4 + (_controller.value * 0.4);
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: glow),
                  width: 3,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
