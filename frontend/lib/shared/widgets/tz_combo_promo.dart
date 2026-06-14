/// 10 连斩组合促销弹窗。
///
/// 免费用户连续答对 10 题时触发，展示 20% OFF 年费优惠，
/// 引导跳转 /premium 完成转化。付费用户永不可见。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/tz_button.dart';

/// 10 连斩组合促销弹窗——免费用户连续答对 10 题后触发。
///
/// 展示 20% OFF 的年费优惠（$23.99），引导到 /premium 购买。
/// 付费用户永远不会看到这个弹窗。
class TzComboPromo extends ConsumerWidget {
  const TzComboPromo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.jadeDeep,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.neonGold.withOpacity(0.3)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // 拖动条
        Container(width: 40, height: 4, decoration: BoxDecoration(
          color: AppColors.jadeWhiteMuted.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(height: 20),
        // 标题
        const Text('🔥', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        const Text('COMBO ×10!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
            color: AppColors.neonGold)),
        const SizedBox(height: 8),
        const Text('You\'re on fire! Unlock unlimited play\nand keep your streak alive.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.jadeWhiteDim, height: 1.5)),
        const SizedBox(height: 20),
        // 促销卡片
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.neonGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.neonGold.withOpacity(0.3)),
          ),
          child: Column(children: [
            const Text('SPECIAL OFFER',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.neonGold, letterSpacing: 2)),
            const SizedBox(height: 8),
            // 折后价
            const Text.rich(TextSpan(children: [
              TextSpan(text: '\$23.99',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                  color: AppColors.jadeWhite)),
              TextSpan(text: '/year',
                style: TextStyle(fontSize: 14, color: AppColors.jadeWhiteDim)),
            ])),
            const SizedBox(height: 4),
            // 原价 + 折扣标签
            Text.rich(TextSpan(children: [
              const TextSpan(text: '\$29.99',
                style: TextStyle(fontSize: 14, decoration: TextDecoration.lineThrough,
                  color: AppColors.jadeWhiteMuted)),
              const TextSpan(text: '  20% OFF',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                  color: AppColors.vermillion)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        // CTA
        TzButton(
          label: 'UNLOCK NOW — \$23.99',
          style: TzButtonStyle.gold,
          onPressed: () {
            Navigator.pop(context);
            context.push('/premium');
          },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Maybe later',
            style: TextStyle(fontSize: 13, color: AppColors.jadeWhiteMuted)),
        ),
        const SizedBox(height: 12),
      ]),
    );
  }
}
