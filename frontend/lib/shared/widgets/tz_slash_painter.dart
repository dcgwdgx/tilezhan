/// 对角斜切 + 粒子爆发 CustomPainter。
///
/// 为 Nani-Kiru（何切る）模式提供两种视觉反馈效果：
/// - [TzSlashPainter]: 牌面丢弃时的对角斜切线，随进度消退
/// - [TzParticlePainter]: 完美解（perfect answer）确认时的粒子爆发效果
///
/// 两者均使用 [progress] (0→1) 驱动动画，由外部 AnimationController 控制。
import 'dart:math';
import 'package:flutter/material.dart';

/// 对角斜切线绘制器 —— 牌面丢弃（discard）动画效果。
///
/// 从牌面中心画一条斜对角线，线宽和透明度随 [progress] 增大而减小，
/// 最终在 progress=1 时完全消失。
class TzSlashPainter extends CustomPainter {
  /// 动画进度 (0→1)，0=不可见, 1=完全消失。
  final double progress;
  /// 斜线颜色，默认白色。
  final Color color;
  /// 创建斜线绘制器。
  ///
  /// [progress] 必传，[color] 默认为白色。
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

/// 粒子爆发绘制器 —— 完美解（perfect answer）确认效果。
///
/// 从牌面中心向外扩散 [n] 个随机方形粒子，粒子的距离、透明度和随机偏移
/// 由 [progress] 驱动，progress=1 时全部消散。
class TzParticlePainter extends CustomPainter {
  /// 动画进度 (0→1)，0=不可见, 1=完全消失。
  final double progress;
  /// 粒子颜色，默认金色 (#FFD700)。
  final Color color;
  /// 粒子数量。
  static const n = 20;
  /// 创建粒子爆发绘制器。
  ///
  /// [progress] 必传，[color] 默认为金色。
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
