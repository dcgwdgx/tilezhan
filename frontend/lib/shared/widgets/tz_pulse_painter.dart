import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Paints an expanding neon ring — used for correct-answer feedback.
class TzPulsePainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color color;
  final double maxRadius;

  TzPulsePainter({
    required this.progress,
    this.color = const Color(0xFF2CE574),
    this.maxRadius = 120,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = maxRadius * progress;

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.15 * (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(center, radius, glowPaint);

    // Main ring
    final ringPaint = Paint()
      ..color = color.withOpacity(1 - progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant TzPulsePainter old) =>
      old.progress != progress || old.color != color;
}
