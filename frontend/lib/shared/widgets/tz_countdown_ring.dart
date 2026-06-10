import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TzCountdownRing extends StatelessWidget {
  final double progress;     // 0.0-1.0
  final int secondsLeft;     // display number
  final double size;
  final bool urgent;

  const TzCountdownRing({
    super.key,
    required this.progress,
    required this.secondsLeft,
    this.size = 100,
    this.urgent = false,
  });

  Color get _color => urgent ? AppColors.vermillion : AppColors.neonGold;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(progress: progress, color: _color, urgent: urgent),
          ),
          Text(secondsLeft.toString(),
            style: TextStyle(
              fontSize: size * 0.32, fontWeight: FontWeight.w700,
              color: _color, fontFamily: 'JetBrains Mono',
            )),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool urgent;
  const _RingPainter({required this.progress, required this.color, required this.urgent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    canvas.drawCircle(center, radius, Paint()
      ..color = AppColors.jadeHover..style = PaintingStyle.stroke..strokeWidth = 3);

    if (progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, progress * 2 * math.pi, false, Paint()
          ..color = color.withOpacity(0.3)..style = PaintingStyle.stroke
          ..strokeWidth = 8..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, progress * 2 * math.pi, false, Paint()
        ..color = color..style = PaintingStyle.stroke
        ..strokeWidth = 3..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.urgent != urgent;
}
