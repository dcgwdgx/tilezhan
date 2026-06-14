/// 答对脉冲扩散金环 — correct-answer pulse-expanding gold ring.
///
/// This file provides [TzPulsePainter], a [CustomPainter] that draws an
/// expanding concentric ring used as visual feedback when the player answers
/// correctly in TileZhan. The ring animates outward from the center with a
/// blurry glow layer and a crisp inner stroke, fading out as it grows.
import 'package:flutter/material.dart';

/// Correct-answer pulse ring [CustomPainter].
///
/// Paints two concentric circles that expand from the widget center:
/// - A thick blurred outer ring (glow) whose opacity decays with radius.
/// - A thin crisp inner ring whose opacity also decays.
///
/// Driven by a [progress] value from 0→1 (center→maxRadius), typically
/// supplied by an [AnimationController] so the ring "pulses" on each
/// correct answer.
class TzPulsePainter extends CustomPainter {
  /// Current expansion progress, 0 (center) to 1 (maxRadius).
  final double progress;

  /// Base colour of the ring (default: gold 0xFFFFD700).
  final Color color;

  /// Maximum radius in logical pixels before the ring fully fades (default: 180).
  final double maxRadius;

  /// Creates a pulse-ring painter.
  ///
  /// [progress] must be between 0 and 1 (values outside are a no-op).
  /// [color] defaults to gold; [maxRadius] defaults to 180 logical pixels.
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
