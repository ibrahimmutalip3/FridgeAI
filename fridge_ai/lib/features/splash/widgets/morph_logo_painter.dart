import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints the FridgeAI logo mark — a looping script "G" with a sparkle
/// tracing up and off its ascender — as a set of animated strokes.
///
/// The mark is drawn progressively (a "draw-on" reveal) and then settles
/// into a soft breathing glow, echoing the shape of the app icon
/// (assets/icons/app_icon.png) without depending on a bitmap so every part
/// of the entrance can be morphed/animated in code.
class MorphLogoPainter extends CustomPainter {
  MorphLogoPainter({
    required this.drawProgress,
    required this.morphProgress,
    required this.sparkleProgress,
    required this.color,
  });

  /// 0 -> 1: the swoosh + G traces on, stroke by stroke.
  final double drawProgress;

  /// 0 -> 1: after drawing completes, the mark "settles" — a gentle
  /// scale/weight morph from a thin outline into its resting stroke width.
  final double morphProgress;

  /// 0 -> 1 -> loops: drives the sparkle's twinkle/pulse once idle.
  final double sparkleProgress;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.width < size.height ? size.width : size.height;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    // The path below is authored on a 200x200 logical canvas centered at
    // its own middle; scale it to fill the available shortest side.
    final scale = shortest / 200;
    canvas.scale(scale, scale);
    canvas.translate(-100, -100);

    final strokeWidth = 9.0 + (morphProgress * 4.0);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // --- The looping "G" body -------------------------------------------------
    final gPath = _buildGPath();
    _drawPartial(canvas, gPath, paint, _segmentProgress(drawProgress, 0.0, 0.72));

    // --- The ascending swoosh feeding into the sparkle -------------------------
    final swooshPath = _buildSwooshPath();
    _drawPartial(canvas, swooshPath, paint, _segmentProgress(drawProgress, 0.45, 0.85));

    // --- The sparkle / star ------------------------------------------------
    final sparkleReveal = _segmentProgress(drawProgress, 0.78, 1.0);
    if (sparkleReveal > 0) {
      _paintSparkle(canvas, sparkleReveal, paint);
    }

    canvas.restore();
  }

  double _segmentProgress(double t, double start, double end) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return (t - start) / (end - start);
  }

  /// The rounded, looping "G" — an open circular stroke with an inward
  /// spiral flourish, echoing the icon's script lettering.
  Path _buildGPath() {
    final path = Path();
    // Outer bowl of the G (open circle, gap on the right for the bar).
    path.addArc(
      Rect.fromCircle(center: const Offset(100, 118), radius: 46),
      _deg(-20),
      _deg(300),
    );
    // Inner flourish loop (the small spiral where the bar meets the bowl).
    final spiral = Path()
      ..moveTo(100, 118)
      ..relativeCubicTo(-10, -6, -18, 2, -16, 12)
      ..relativeCubicTo(1.5, 8, 13, 9, 16, -2);
    path.addPath(spiral, Offset.zero);
    // The horizontal bar of the G.
    path.moveTo(100, 118);
    path.cubicTo(118, 112, 142, 112, 150, 118);
    return path;
  }

  /// The upward swoosh stroke that leads from the G's bowl up toward the
  /// sparkle — mirrors the icon's ascending flick above the letterform.
  Path _buildSwooshPath() {
    return Path()
      ..moveTo(78, 96)
      ..cubicTo(70, 78, 74, 60, 92, 52)
      ..cubicTo(118, 40, 128, 60, 118, 74);
  }

  void _paintSparkle(Canvas canvas, double reveal, Paint basePaint) {
    const sparkleCenter = Offset(132, 46);
    final twinkle = 0.85 + (0.15 * (0.5 + 0.5 * _sine(sparkleProgress)));
    final radius = 15.0 * twinkle * reveal.clamp(0.0, 1.0);

    final sparklePaint = Paint()
      ..color = color.withValues(alpha: reveal.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = basePaint.strokeWidth * 0.72
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _fourPointStarPath(sparkleCenter, radius);
    canvas.drawPath(path, sparklePaint);

    // Soft glow behind the sparkle once fully drawn, pulsing gently.
    if (reveal > 0.98) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.16 * (0.5 + 0.5 * _sine(sparkleProgress)))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawCircle(sparkleCenter, radius * 1.1, glowPaint);
    }
  }

  Path _fourPointStarPath(Offset c, double r) {
    final inner = r * 0.32;
    final path = Path();
    final points = <Offset>[
      c + Offset(0, -r),
      c + Offset(inner, -inner),
      c + Offset(r, 0),
      c + Offset(inner, inner),
      c + Offset(0, r),
      c + Offset(-inner, inner),
      c + Offset(-r, 0),
      c + Offset(-inner, -inner),
    ];
    path.moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  void _drawPartial(Canvas canvas, Path path, Paint paint, double t) {
    if (t <= 0) return;
    final clamped = t.clamp(0.0, 1.0);
    if (clamped >= 1.0) {
      canvas.drawPath(path, paint);
      return;
    }
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final extractLength = metric.length * clamped;
      final extracted = metric.extractPath(0, extractLength);
      canvas.drawPath(extracted, paint);
    }
  }

  /// Returns sin(2*pi*t), i.e. one full oscillation as [t] goes 0 -> 1.
  double _sine(double t) => math.sin(2 * math.pi * t);

  double _deg(double degrees) => degrees * math.pi / 180;

  @override
  bool shouldRepaint(covariant MorphLogoPainter oldDelegate) {
    return oldDelegate.drawProgress != drawProgress ||
        oldDelegate.morphProgress != morphProgress ||
        oldDelegate.sparkleProgress != sparkleProgress ||
        oldDelegate.color != color;
  }
}
