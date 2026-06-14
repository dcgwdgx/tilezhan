/// 役种扫描参考列表 — 展示一副参考手牌可能组成的全部役种。
///
/// MVP 阶段提供一个精选的基础役种列表，每个役种带图标、名称、
/// 英文名、简介以及解锁状态。V2 将加入完整的手牌扫描功能。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

/// Simple Yaku Scanner — shows which yaku are possible from a reference hand.
/// MVP: displays a curated list of basic yaku with visual examples.
class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  static const _yakuList = [
    ('🥪', 'Tanyao', 'All Simples', 'No terminals or honors. Only tiles 2-8.', true),
    ('🛗', 'Pinfu', 'Peace', 'All sequences, pair not a value honor, two-sided wait.', false),
    ('🔫', 'Riichi', 'Ready Hand', 'Declare riichi when in tenpai. 1 han + chance for uradora.', false),
    ('🎨', 'Honitsu', 'Half Flush', 'All tiles from one suit + honors. Common intermediate yaku.', false),
    ('🧹', 'Chinitsu', 'Full Flush', 'All tiles from a single suit. 6 han (menzen) or 5 han (open).', false),
    ('👯', 'Toitoi', 'All Triplets', 'Four triplets + one pair. Open or closed.', false),
    ('🚢', 'Chiitoitsu', 'Seven Pairs', 'Seven distinct pairs. Always closed. 2 han.', false),
    ('👑', 'Yakuhai', 'Value Honors', 'Triplet of dragons, seat wind, or round wind.', false),
    ('🌀', 'Iipeikou', 'Pure Double Sequence', 'Two identical sequences in the same suit. Closed only.', false),
    ('🏔️', 'Chanta', 'Terminal in Each Set', 'Every meld and pair contains a terminal or honor.', false),
  ];

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
        title: const Text('Yaku Scanner', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          const Text('🔍', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.jadeCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.neonGold.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Text('📸', style: TextStyle(fontSize: 32)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Yaku Reference', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jadeWhite)),
                      SizedBox(height: 4),
                      Text('Full hand scanning coming in V2.\nBrowse all 10 basic yaku below.', style: TextStyle(fontSize: 12, color: AppColors.jadeWhiteDim)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('BASIC YAKU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.jadeWhiteMuted)),
          const SizedBox(height: 8),
          ..._yakuList.map((y) => _YakuCard(y.$1, y.$2, y.$3, y.$4, y.$5)),
        ],
      ),
    );
  }
}

class _YakuCard extends StatelessWidget {
  final String emoji, name, eng, desc;
  final bool unlocked;
  const _YakuCard(this.emoji, this.name, this.eng, this.desc, this.unlocked);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.jadeCard : AppColors.jadeCard.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: unlocked ? AppColors.jadeHover : AppColors.jadeHover.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 28, color: unlocked ? null : AppColors.jadeWhiteMuted.withOpacity(0.4))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: unlocked ? AppColors.neonGold : AppColors.jadeWhiteMuted)),
                  const SizedBox(width: 8),
                  Text(eng, style: TextStyle(fontSize: 11, color: unlocked ? AppColors.jadeWhiteDim : AppColors.jadeWhiteMuted.withOpacity(0.4))),
                ]),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 11, color: unlocked ? AppColors.jadeWhiteDim : AppColors.jadeWhiteMuted.withOpacity(0.3))),
              ],
            ),
          ),
          if (!unlocked) const Text('🔒', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
