import 'dart:math';
import 'package:flutter/material.dart';

/// Diagonal slash line — Nani-Kiru discard effect.
class TzSlashPainter extends CustomPainter {
  final double progress;
  final Color color;
  TzSlashPainter({required this.progress, this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final a = (1 - progress).clamp(0.0, 1.0);
    final p = Paint()..color=color.withOpacity(a)..style=PaintingStyle.stroke..strokeWidth=3*(1-progress)..strokeCap=StrokeCap.round;
    final mx = size.width / 2, my = size.height / 2;
    final dx = size.width * 0.4 * progress, dy = size.height * 0.4 * progress;
    canvas.drawLine(Offset(mx-dx, my-dy), Offset(mx+dx, my+dy), p);
  }

  @override
  bool shouldRepaint(TzSlashPainter o) => o.progress != progress;
}

/// Particle burst — perfect Nani-Kiru answer.
class TzParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  static const n = 20;
  TzParticlePainter({required this.progress, this.color = const Color(0xFFFFD700)});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final c = Offset(size.width / 2, size.height / 2);
    final maxD = min(size.width, size.height) * 0.5;
    final a = (1 - progress).clamp(0.0, 1.0);
    final rng = Random(42);
    final paint = Paint()..style=PaintingStyle.fill;
    for (int i = 0; i < n; i++) {
      final angle = (i/n) * 2*pi + (rng.nextDouble()-0.5)*0.5;
      final dist = maxD * progress * (0.5 + rng.nextDouble()*0.5);
      paint.color = color.withOpacity(a * (0.5 + rng.nextDouble()*0.5));
      final x = c.dx + cos(angle)*dist, y = c.dy + sin(angle)*dist;
      final r = 3.0*(1-progress) + 1.0;
      canvas.drawRect(Rect.fromCenter(center: Offset(x,y), width: r, height: r), paint);
    }
  }

  @override
  bool shouldRepaint(TzParticlePainter o) => o.progress != progress;
}
