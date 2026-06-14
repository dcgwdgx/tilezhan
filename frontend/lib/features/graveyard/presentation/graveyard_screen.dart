import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/tile_model.dart';
import '../../../shared/widgets/tz_card.dart';
import '../domain/graveyard_provider.dart';

/// 错题墓地 — 复习列表界面
///
/// Displays the user's SRS due queue: a weakness radar summarising error
/// rates across the five mahjong suits, a scrollable list of overdue
/// flashcard and nanikiru items, and a "Review All" button that launches
/// the flashcard session. 所有数据通过 Riverpod providers 驱动。
class GraveyardScreen extends ConsumerWidget {
  const GraveyardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
          onPressed: () => context.pop(),
        ),
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
      body: Consumer(
        builder: (context, ref, _) {
          final dueItems = ref.watch(graveyardDueProvider);
          final suitRates = ref.watch(suitErrorRatesProvider);
          return Column(
            children: [
              _buildRadarCard(suitRates),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("TODAY'S REVIEW · ${dueItems.length} DUE", style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                    color: AppColors.jadeWhiteMuted,
                  )),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildReviewList(context, dueItems)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: dueItems.isEmpty ? null : () => context.push('/flashcard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text('⚡ Review All (${dueItems.length})', style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800,
                    )),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRadarCard(Map<String, double> suitRates) {
    final suits = ['man', 'pin', 'sou', 'wind', 'dragon'];
    final labels = ['Man', 'Pin', 'Sou', 'Wind', 'Dgn'];
    final worst = suits.reduce((a, b) => (suitRates[a] ?? 0) > (suitRates[b] ?? 0) ? a : b);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: TzCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Weakness Radar', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.jadeWhiteDim,
            )),
            const SizedBox(height: 12),
            SizedBox(
              width: 140, height: 140,
              child: CustomPaint(
                painter: _RadarPainter(data: suits.map((s) => suitRates[s] ?? 0).toList()),
              ),
            ),
            const SizedBox(height: 8),
            Text('⚠ Weakest: ${labels[suits.indexOf(worst)]} (${((suitRates[worst] ?? 0) * 100).round()}% error rate)', style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.vermillionHover,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewList(BuildContext context, List<(dynamic, TileModel?)> dueItems) {
    if (dueItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎉', style: TextStyle(fontSize: 40)),
            SizedBox(height: 8),
            Text('Nothing due!\nAll caught up.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.jadeWhiteDim)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: dueItems.length,
      itemBuilder: (_, i) {
        final (item, tile) = dueItems[i];
        final emoji = tile?.mnemonic.emoji ?? '🀄';
        final name = tile?.mnemonic.name ?? item.itemId;
        final daysAgo = ((DateTime.now().millisecondsSinceEpoch - item.nextReviewAt) / 86400000).round();
        final route = item.type == 'nanikiru'
            ? '/nanikiru'
            : '/flashcard?suite=${tile?.suit.name ?? 'all'}';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => context.push(route),
            child: TzCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 12,
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$name · ${item.type == 'flashcard' ? 'Flashcard' : 'Nani-Kiru'}', style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.jadeWhite,
                        )),
                        const SizedBox(height: 2),
                        Text('${item.errors} errors · ${daysAgo}d overdue', style: const TextStyle(
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
            ),
          ),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> data;
  const _RadarPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final paint = Paint()..style = PaintingStyle.stroke;

    // Grid rings
    for (int i = 1; i <= 3; i++) {
      paint.color = AppColors.jadeHover.withOpacity(0.3 + i * 0.15);
      paint.strokeWidth = 0.5;
      _drawPentagon(canvas, center, radius * i / 3, paint);
    }

    // Axes
    paint.color = AppColors.jadeHover.withOpacity(0.5);
    paint.strokeWidth = 0.5;
    for (int i = 0; i < 5; i++) {
      final angle = -3.14159 / 2 + i * 2 * 3.14159 / 5;
      canvas.drawLine(center, Offset(
        center.dx + radius * cos(angle), center.dy + radius * sin(angle),
      ), paint);
    }

    // Data polygon
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -3.14159 / 2 + i * 2 * 3.14159 / 5;
      final r = radius * (data.length > i ? data[i].clamp(0.0, 1.0) : 0.0);
      final point = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) path.moveTo(point.dx, point.dy);
      else path.lineTo(point.dx, point.dy);
    }
    path.close();
    paint.color = AppColors.vermillion.withOpacity(0.6);
    paint.strokeWidth = 2;
    canvas.drawPath(path, paint);
    paint.color = AppColors.vermillion.withOpacity(0.15);
    paint.style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
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
