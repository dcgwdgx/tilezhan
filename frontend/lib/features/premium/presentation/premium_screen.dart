import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/revenuecat/revenuecat_provider.dart';
import '../../../core/revenuecat/revenuecat_service.dart';
import '../../../shared/widgets/tz_button.dart';
import '../../../shared/widgets/tz_card.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerings = ref.watch(offeringsProvider);
    final isPro = ref.watch(isProProvider);

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
              isPro.when(
                data: (pro) => pro
                    ? const TzCard(padding: EdgeInsets.all(20), child: Text('✅ You are a Pro member!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.neonGold)))
                    : _buildPricing(context, ref, offerings),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonGold)),
                error: (_, __) => _buildPricing(context, ref, offerings),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await RevenueCatService.restore();
                  ref.invalidate(isProProvider);
                },
                child: const Text('Restore Purchases', style: TextStyle(color: AppColors.jadeWhiteMuted)),
              ),
              Text('Terms  ·  Privacy', style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted.withOpacity(0.6))),
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
    return TzCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(f, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.jadeWhite, height: 1.5)),
        )).toList(),
      ),
    );
  }

  Widget _buildPricing(BuildContext context, WidgetRef ref, AsyncValue<Offerings?> offerings) {
    final packages = offerings.valueOrNull?.current?.availablePackages ?? [];
    if (packages.isEmpty) {
      return TzButton(
        label: 'START FREE TRIAL',
        style: TzButtonStyle.gold,
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 Premium coming soon!'))),
      );
    }
    return Column(
      children: packages.map((pkg) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () async {
            try {
              await RevenueCatService.purchase(pkg);
              ref.invalidate(isProProvider);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Welcome to Pro!')));
            } catch (_) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase cancelled')));
            }
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: pkg.packageType == PackageType.annual ? AppColors.neonGold.withOpacity(0.08) : AppColors.jadeCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: pkg.packageType == PackageType.annual ? AppColors.neonGold : AppColors.jadeHover, width: 2),
            ),
            child: Row(
              children: [
                Expanded(child: Text(pkg.storeProduct.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.jadeWhite))),
                Text(pkg.storeProduct.priceString, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.neonGold)),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }
}
