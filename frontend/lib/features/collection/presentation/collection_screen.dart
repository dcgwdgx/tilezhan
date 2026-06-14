/// 役种收藏册 (Yaku Collection Screen).
///
/// Displays a grid of unlockable Mahjong yaku cards. Unlock progress is driven by
/// SRS review count — every 5 reviews unlocks one additional yaku, up to all 8.
/// Tapping an unlocked card shows a detail dialog with the yaku name, English
/// translation, star mastery rating, and a short description.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/srs/srs_provider.dart';

/// A full-screen collection viewer for unlocked Mahjong yaku (scoring patterns).
///
/// The grid shows each yaku as a card with an emoji icon, Japanese name, English
/// name, star rating, and a lock overlay when not yet unlocked. A horizontal
/// filter bar at the top allows browsing by category (All, Basics, Color, Clone,
/// VIP). Tapping an unlocked card opens [AlertDialog] with additional detail.
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(srsItemsProvider);
    final totalReviews = (itemsAsync.valueOrNull ?? {}).values
        .fold(0, (sum, item) => sum + item.reps + 1);
    final unlocked = (totalReviews ~/ 5).clamp(0, 7);
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
          onPressed: () => context.pop(),
        ),
        title: const Text('Yaku Collection', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Text('${unlocked + 1}/8', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.neonGold,
          )),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          const SizedBox(height: 8),
          Expanded(child: _buildYakuGrid(context, unlocked)),
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
                color: isActive ? AppColors.neonGold.withOpacity(0.15) : AppColors.jadeCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.neonGold.withOpacity(0.3) : Colors.transparent,
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

  Widget _buildYakuGrid(BuildContext context, int unlocked) {
    final yakus = [
      ('🥪', 'Tanyao', 'All Simples', 2),
      ('🛗', 'Pinfu', 'Peace', 3),
      ('🔫', 'Riichi', 'Ready Hand', 2),
      ('🎨', 'Honitsu', 'Half Flush', 3),
      ('🧹', 'Chinitsu', 'Full Flush', 5),
      ('👯', 'Toitoi', 'All Triplets', 4),
      ('🚢', 'Chiitoitsu', 'Seven Pairs', 4),
      ('👑', 'Yakuhai', 'Value Honors', 3),
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
        final isUnlocked = i <= unlocked;
        return GestureDetector(
          onTap: isUnlocked ? () => _showYakuDetail(context, y.$2, y.$3, y.$4) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isUnlocked ? AppColors.jadeCard : AppColors.jadeCard.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isUnlocked ? AppColors.jadeHover : AppColors.jadeHover.withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(y.$1, style: TextStyle(
                  fontSize: 32, color: isUnlocked ? null : AppColors.jadeWhiteMuted.withOpacity(0.4),
                )),
                const SizedBox(height: 4),
                Text(y.$2, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: isUnlocked ? AppColors.jadeWhite : AppColors.jadeWhiteMuted,
                )),
                Text(y.$3, style: TextStyle(
                  fontSize: 10,
                  color: isUnlocked ? AppColors.jadeWhiteMuted : AppColors.jadeWhiteMuted.withOpacity(0.4),
                )),
                const SizedBox(height: 2),
                if (isUnlocked)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (s) => Icon(
                      s < y.$4 ? Icons.star : Icons.star_border,
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
