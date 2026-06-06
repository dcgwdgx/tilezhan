import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class GraveyardScreen extends ConsumerWidget {
  const GraveyardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        title: const Row(
          children: [
            Text('Tile Graveyard', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(width: 8),
            Text('👻 SRS Review', style: TextStyle(
              fontSize: 13, color: AppColors.demonPurple,
            )),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildRadarCard(),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("TODAY'S REVIEW · 12 DUE", style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                color: AppColors.jadeWhiteMuted,
              )),
            ),
          ),
          const SizedBox(height: 8),
          _buildReviewList(context),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/flashcard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('⚡ Review All (12)', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.jadeCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text('Weakness Radar', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.jadeWhiteDim,
            )),
            const SizedBox(height: 12),
            SizedBox(
              width: 140, height: 140,
              child: CustomPaint(
                painter: _RadarPainter(),
              ),
            ),
            const SizedBox(height: 8),
            const Text('⚠ Weakest: Manzu (42% error rate)', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.vermillionHover,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewList(BuildContext context) {
    final items = [
      ('🀋', '5-Man · Mistook for 6-Man', '5 errors · 3 days ago'),
      ('⚔️', 'Nani-Kiru · Discarded 7-Man instead of 4-Man', '3 errors · Yesterday'),
      ('🀝', '5-Pin · Mistook for 4-Pin', '2 errors · 5 days ago'),
    ];
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.jadeCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.jadeHover),
            ),
            child: Row(
              children: [
                Text(item.$1, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$2, style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.jadeWhite,
                      )),
                      const SizedBox(height: 2),
                      Text(item.$3, style: const TextStyle(
                        fontSize: 11, color: AppColors.jadeWhiteMuted,
                      )),
                    ],
                  ),
                ),
                const Text('Review →', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.vermillion,
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final paint = Paint()..style = PaintingStyle.stroke;

    // Grid rings
    for (int i = 1; i <= 3; i++) {
      paint.color = AppColors.jadeHover.withValues(alpha: 0.3 + i * 0.15);
      paint.strokeWidth = 0.5;
      _drawPentagon(canvas, center, radius * i / 3, paint);
    }

    // Axes
    paint.color = AppColors.jadeHover.withValues(alpha: 0.5);
    paint.strokeWidth = 0.5;
    for (int i = 0; i < 5; i++) {
      final angle = -3.14159 / 2 + i * 2 * 3.14159 / 5;
      canvas.drawLine(center, Offset(
        center.dx + radius * cos(angle), center.dy + radius * sin(angle),
      ), paint);
    }

    // Data (Manzu=0.42, Pinzu=0.20, Souzu=0.30, Honor=0.15, Nani=0.25)
    final data = [0.42, 0.20, 0.30, 0.15, 0.25];
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -3.14159 / 2 + i * 2 * 3.14159 / 5;
      final r = radius * data[i];
      final point = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) path.moveTo(point.dx, point.dy);
      else path.lineTo(point.dx, point.dy);
    }
    path.close();
    paint.color = AppColors.vermillion.withValues(alpha: 0.6);
    paint.strokeWidth = 2;
    canvas.drawPath(path, paint);
    paint.color = AppColors.vermillion.withValues(alpha: 0.15);
    paint.style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Labels
    // ... skip for brevity
  }

  void _drawPentagon(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -3.14159 / 2 + i * 2 * 3.14159 / 5;
      final point = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) path.moveTo(point.dx, point.dy);
      else path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
