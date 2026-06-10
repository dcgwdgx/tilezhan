import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Paints a diagonal slash line — Nani-Kiru discard effect.
class TzSlashPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color color;

  TzSlashPainter({
    required this.progress,
    this.color = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final p = progress;
    final alpha = (1 - p).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = color.withOpacity(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - p)
      ..strokeCap = StrokeCap.round;

    // Diagonal slash from top-left to bottom-right
    final startX = size.width * 0.1;
    final startY = size.height * 0.1;
    final endX = size.width * 0.9;
    final endY = size.height * 0.9;

    // The slash "grows" with progress — from center outward
    final midX = (startX + endX) / 2;
    final midY = (startY + endY) / 2;
    final dx = (endX - startX) / 2 * p;
    final dy = (endY - startY) / 2 * p;

    canvas.drawLine(
      Offset(midX - dx, midY - dy),
      Offset(midX + dx, midY + dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant TzSlashPainter old) => old.progress != progress;
}

/// Paints particle burst — used for perfect Nani-Kiru answer.
class TzParticlePainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color color;
  static const _particleCount = 20;

  TzParticlePainter({
    required this.progress,
    this.color = const Color(0xFFFFD700),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxDist = math.min(size.width, size.height) * 0.5;
    final alpha = (1 - progress).clamp(0.0, 1.0);

    // Precompute all particle positions
    final points = Float32List(_particleCount * 2);
    final colors = <Color>[];
    final rng = math.Random(42); // Fixed seed for determinism

    for (int i = 0; i < _particleCount; i++) {
      final angle = (i / _particleCount) * 2 * math.pi + (rng.nextDouble() - 0.5) * 0.5;
      final dist = maxDist * progress * (0.5 + rng.nextDouble() * 0.5);
      points[i * 2] = center.dx + math.cos(angle) * dist;
      points[i * 2 + 1] = center.dy + math.sin(angle) * dist;
      colors.add(color.withOpacity(alpha * (0.5 + rng.nextDouble() * 0.5)));
    }

    // Single draw call for all particles
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < _particleCount; i++) {
      paint.color = colors[i];
      final x = points[i * 2];
      final y = points[i * 2 + 1];
      final r = 3.0 * (1 - progress) + 1.0;
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: r, height: r), paint);
    }
  }

  @override
  bool shouldRepaint(covariant TzParticlePainter old) => old.progress != progress;
}
