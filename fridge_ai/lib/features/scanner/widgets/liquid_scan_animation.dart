import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A soft, liquid-style sweeping scan-line animation drawn over the
/// captured photo while Groq analyzes it — gives the "AI is thinking"
/// moment a premium, fluid feel rather than a generic spinner.
class LiquidScanAnimation extends StatefulWidget {
  const LiquidScanAnimation({super.key});

  @override
  State<LiquidScanAnimation> createState() => _LiquidScanAnimationState();
}

class _LiquidScanAnimationState extends State<LiquidScanAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _LiquidScanPainter(progress: _controller.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _LiquidScanPainter extends CustomPainter {
  _LiquidScanPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final sweepY = size.height * progress;

    // Soft tint below the scan line, fading toward the bottom.
    final overlayRect = Rect.fromLTWH(0, 0, size.width, sweepY);
    final overlayPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryOrange.withValues(alpha: 0.0),
          AppColors.primaryOrange.withValues(alpha: 0.12),
        ],
      ).createShader(overlayRect);
    canvas.drawRect(overlayRect, overlayPaint);

    // The glowing scan line itself, with a soft blur for a "liquid" feel.
    final lineRect = Rect.fromLTWH(0, sweepY - 1.5, size.width, 3);
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primaryOrange.withValues(alpha: 0.0),
          AppColors.primaryOrange,
          AppColors.primaryOrange.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRect(lineRect, linePaint);

    // Subtle secondary glow line trailing above the sweep.
    final trailY = sweepY - 22;
    if (trailY > 0) {
      final trailPaint = Paint()
        ..color = AppColors.primaryOrange.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRect(Rect.fromLTWH(0, trailY, size.width, 2), trailPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidScanPainter oldDelegate) => oldDelegate.progress != progress;
}
