import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/tz_button.dart';
import '../../../shared/widgets/tz_card.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('💎', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text('TILEZHAN PRO', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.neonGold, letterSpacing: 3)),
              const SizedBox(height: 8),
              const Text('Unlimited Learning. Zero Interruptions.', style: TextStyle(fontSize: 14, color: AppColors.jadeWhiteDim)),
              const SizedBox(height: 24),
              _buildFeatureList(),
              const SizedBox(height: 24),
              _buildPricingCard('🌟 MOST POPULAR', 'YEARLY', '\$29.99 / year', '\$2.50 / month', '50% OFF', true),
              const SizedBox(height: 10),
              _buildPricingCard(null, 'MONTHLY', '\$4.99 / month', null, null, false),
              const SizedBox(height: 10),
              _buildPricingCard(null, 'WEEKLY', '\$1.49 / week', null, null, false),
              const SizedBox(height: 24),
              TzButton(
                label: 'START FREE TRIAL',
                style: TzButtonStyle.gold,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 Premium coming soon!'))),
              ),
              const SizedBox(height: 16),
              Text('Restore Purchases  ·  Terms  ·  Privacy', style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted.withOpacity(0.6))),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      '✅  Unlimited Hearts — Never wait again',
      '✅  All Mnemonic Illustrations Unlocked',
      '✅  Advanced Puzzle Packs',
      '✅  Full Yaku Collection (40 Han)',
      '✅  Ad-Free Experience',
    ];
    return TzCard(padding: const EdgeInsets.all(20), child: Column(
      children: features.map((f) => Padding(padding: const EdgeInsets.only(bottom: 10),
        child: Text(f, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.jadeWhite, height: 1.5)),
      )).toList(),
    ));
  }

  Widget _buildPricingCard(String? badge, String label, String price, String? subPrice, String? discount, bool isPopular) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isPopular ? AppColors.neonGold.withOpacity(0.08) : AppColors.jadeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPopular ? AppColors.neonGold : AppColors.jadeHover, width: isPopular ? 2 : 1),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (badge != null) Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.neonGold)),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isPopular ? AppColors.neonGold : AppColors.jadeWhite)),
          Text(price, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.jadeWhite)),
          if (subPrice != null) Text(subPrice, style: const TextStyle(fontSize: 12, color: AppColors.jadeWhiteDim)),
        ])),
        if (discount != null) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.neonGold, borderRadius: BorderRadius.circular(12)), child: Text(discount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black))),
      ]),
    );
  }
}
