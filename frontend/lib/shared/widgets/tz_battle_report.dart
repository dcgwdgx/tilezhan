import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/hearts/heart_provider.dart';
import '../widgets/tz_button.dart';

/// Shown when free user runs out of hearts. Shows session stats
/// and CTA to subscribe. Premium users never see this.
class TzBattleReport extends ConsumerWidget {
  final VoidCallback? onClose;

  const TzBattleReport({super.key, this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(battleReportProvider);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.jadeDeep,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar
        Container(width: 40, height: 4, decoration: BoxDecoration(
          color: AppColors.jadeWhiteMuted.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(height: 20),
        const Text('🎯', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        const Text('今日战绩',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
            color: AppColors.neonGold)),
        const SizedBox(height: 24),
        // Stats row
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _stat('总题数', '${report.total}'),
          _stat('正确率', '${(report.accuracy * 100).toInt()}%'),
          _stat('最大连斩', '${report.maxCombo}×'),
        ]),
        const SizedBox(height: 24),
        // Ghost mode notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.jadeCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(children: [
            Icon(Icons.auto_fix_high, color: AppColors.neonGold, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text(
              '错题永远免费重练，不限次数',
              style: TextStyle(fontSize: 13, color: AppColors.jadeWhiteDim),
            )),
          ]),
        ),
        const SizedBox(height: 20),
        // Premium CTA
        TzButton(
          label: '\$4.99/月  无限刷题',
          style: TzButtonStyle.gold,
          onPressed: () {
            context.push('/premium');
          },
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onClose,
          child: const Text('继续免费错题',
            style: TextStyle(fontSize: 13, color: AppColors.jadeWhiteMuted)),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _stat(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 24,
        fontWeight: FontWeight.w900, color: AppColors.jadeWhite)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11,
        color: AppColors.jadeWhiteMuted)),
    ]);
  }
}
