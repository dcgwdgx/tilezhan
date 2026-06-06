import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        title: const Text('Yaku Collection', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Text('12/40', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.neonGold,
          )),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          const SizedBox(height: 8),
          Expanded(child: _buildYakuGrid(context)),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final chips = ['All', '⭐ Basics', '🎨 Color', '👯 Clone', '👑 VIP'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: chips.asMap().entries.map((e) {
          final isActive = e.key == 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? AppColors.neonGold.withValues(alpha: 0.15) : AppColors.jadeCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.neonGold.withValues(alpha: 0.3) : Colors.transparent,
                ),
              ),
              child: Text(e.value, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: isActive ? AppColors.neonGold : AppColors.jadeWhiteDim,
              )),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildYakuGrid(BuildContext context) {
    final yakus = [
      ('🥪', 'Tanyao', 'All Simples', true, 2),
      ('🛗', 'Pinfu', 'Peace', true, 3),
      ('🔫', 'Riichi', 'Ready Hand', true, 2),
      ('🎨', 'Honitsu', 'Half Flush', false, 0),
      ('🧹', 'Chinitsu', 'Full Flush', false, 0),
      ('👯', 'Toitoi', 'All Triplets', false, 0),
      ('🚢', 'Chiitoitsu', 'Seven Pairs', false, 0),
      ('👑', 'Yakuhai', 'Value Honors', false, 0),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: yakus.length,
      itemBuilder: (_, i) {
        final y = yakus[i];
        return GestureDetector(
          onTap: y.$4 ? () => _showYakuDetail(context, y.$2, y.$3, y.$5) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: y.$4 ? AppColors.jadeCard : AppColors.jadeCard.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: y.$4 ? AppColors.jadeHover : AppColors.jadeHover.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(y.$1, style: TextStyle(
                  fontSize: 32, color: y.$4 ? null : AppColors.jadeWhiteMuted.withValues(alpha: 0.4),
                )),
                const SizedBox(height: 4),
                Text(y.$2, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: y.$4 ? AppColors.jadeWhite : AppColors.jadeWhiteMuted,
                )),
                Text(y.$3, style: TextStyle(
                  fontSize: 10,
                  color: y.$4 ? AppColors.jadeWhiteMuted : AppColors.jadeWhiteMuted.withValues(alpha: 0.4),
                )),
                const SizedBox(height: 2),
                if (y.$4)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (s) => Icon(
                      s < y.$5 ? Icons.star : Icons.star_border,
                      color: AppColors.neonGold, size: 14,
                    )),
                  )
                else
                  const Text('🔒', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showYakuDetail(BuildContext context, String name, String engName, int stars) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.jadeDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(name, style: const TextStyle(
          fontWeight: FontWeight.w800, color: AppColors.neonGold,
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(engName, style: const TextStyle(color: AppColors.jadeWhiteDim)),
            const SizedBox(height: 8),
            Text('Mastery: ${'⭐' * stars}${'☆' * (3 - stars)}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            const Text('This Yaku requires all tiles to be within 2-8 range, with no terminals or honor tiles.',
                style: TextStyle(fontSize: 13, color: AppColors.jadeWhiteDim)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.neonGold)),
          ),
        ],
      ),
    );
  }
}
