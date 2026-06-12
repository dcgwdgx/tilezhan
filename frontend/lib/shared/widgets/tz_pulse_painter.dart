import 'package:flutter/material.dart';

/// Expanding neon ring — correct answer feedback.
class TzPulsePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double maxRadius;

  TzPulsePainter({required this.progress, this.color = const Color(0xFFFFD700), this.maxRadius = 180});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final c = Offset(size.width / 2, size.height / 2);
    final r = maxRadius * progress;
    canvas.drawCircle(c, r, Paint()..color=color.withOpacity(0.15*(1-progress))..style=PaintingStyle.stroke..strokeWidth=12..maskFilter=const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(c, r, Paint()..color=color.withOpacity(1-progress)..style=PaintingStyle.stroke..strokeWidth=3);
  }

  @override
  bool shouldRepaint(TzPulsePainter o) => o.progress != progress;
}
