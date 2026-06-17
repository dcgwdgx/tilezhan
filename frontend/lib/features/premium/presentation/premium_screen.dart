/// Premium subscription screen with four-tier pricing (Free / Monthly / Annual / Lifetime).
///
/// Displays plan cards with badge highlights, feature lists, and real Store prices
/// fetched via IAP. Supports purchase, restore, and error retry flows. The launch
/// promo banner shows a limited-time lifetime discount.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/hearts/heart_provider.dart';
import '../../../core/iap/iap_provider.dart';
import '../../../core/iap/iap_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/tz_button.dart';
import '../../../shared/widgets/tz_card.dart';

/// Premium pricing page: Free / Monthly / Annual / Lifetime tiers.
///
/// Reads product details from [IapState] (via Riverpod) and renders
/// selectable plan cards with real Store prices. Tapping a plan sets the
/// selection; the bottom CTA triggers the purchase flow through [IapService].
/// The "Restore Purchases" link and per-tier feature lists are also rendered here.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final iapAsync = ref.watch(iapStateProvider);

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
        child: iapAsync.when(
          data: (state) => _buildContent(state),
          loading: () => _buildLoading(),
          error: (e, _) => _buildContent(IapState(
            status: IapStatus.error,
            error: e.toString(),
          )),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppColors.neonGold),
        const SizedBox(height: 16),
        Text(l10n.premiumConnecting,
          style: TextStyle(fontSize: 14, color: AppColors.jadeWhiteDim)),
      ]),
    );
  }

  Widget _buildContent(IapState state) {
    final l10n = AppLocalizations.of(context)!;
    final error = state.error;
    final isPurchasing = state.status == IapStatus.purchasing;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Text('💎', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        Text(l10n.premiumTitle,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
            color: AppColors.neonGold, letterSpacing: 1)),
        const SizedBox(height: 16),
        // 首开 48h Lifetime 促销（付费用户不显示）
        if (ref.read(heartServiceProvider).isLifetimePromoActive(false))
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.neonGold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neonGold.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Text('🚀', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.premiumLaunchBanner,
                style: TextStyle(fontSize: 12, color: AppColors.neonGold))),
            ]),
          ),
        if (error != null)
          _buildError(error)
        else if (state.hasProducts)
          ..._buildPlanCards(state, isPurchasing),

        const SizedBox(height: 20),

        TzButton(
          label: isPurchasing
            ? l10n.premiumPurchasing
            : (_selectedId != null ? l10n.premiumContinue : l10n.premiumSelectPlan),
          style: TzButtonStyle.gold,
          onPressed: _selectedId != null && !isPurchasing
            ? () => _purchase(_selectedId!)
            : null,
        ),
        const SizedBox(height: 12),
        _buildRestoreButton(),
        const SizedBox(height: 8),
        _buildAllPlansFooter(),
        const SizedBox(height: 40),
      ]),
    );
  }

  List<Widget> _buildPlanCards(IapState state, bool disabled) {
    final l10n = AppLocalizations.of(context)!;
    final products = Map<String, ProductDetails>.fromEntries(
      state.products.map((p) => MapEntry(p.id, p)),
    );

    final plans = [
      _Plan(
        id: 'free',
        title: l10n.premiumFree,
        price: '\$0',
        subtitle: '10/day',
        badge: null,
        features: const ['10 puzzles/day', 'Mistakes free forever', 'Daily challenge'],
        isFree: true,
      ),
      _Plan(
        id: TzProducts.monthly,
        title: l10n.premiumMonthly,
        price: products[TzProducts.monthly]?.price ?? '\$4.99',
        subtitle: '/month',
        badge: l10n.premiumPopular,
        features: const ['Unlimited puzzles', 'SRS mistake tracking', 'Full stats & analytics', 'All difficulties'],
      ),
      _Plan(
        id: TzProducts.yearly,
        title: l10n.premiumAnnual,
        price: products[TzProducts.yearly]?.price ?? '\$29.99',
        subtitle: '/year',
        badge: l10n.premiumBestValue,
        features: const ['Everything in Monthly', 'ELO deep analysis', 'Exclusive skins', 'Priority support'],
      ),
      _Plan(
        id: TzProducts.lifetime,
        title: l10n.premiumLifetime,
        price: products[TzProducts.lifetime]?.price ?? '\$49.99',
        subtitle: 'one time',
        badge: l10n.premiumPayOnce,
        features: const ['Everything forever', 'All future features', 'Founder badge', 'No subscriptions'],
      ),
    ];

    return plans.map((plan) {
      final isSelected = _selectedId == plan.id;
      final isFree = plan.isFree;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: disabled ? null : () => setState(() => _selectedId = plan.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                ? AppColors.neonGold.withOpacity(0.12)
                : isFree
                  ? AppColors.jadeCard.withOpacity(0.6)
                  : AppColors.jadeCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                  ? AppColors.neonGold
                  : isFree ? AppColors.jadeHover : AppColors.jadeHover,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Badge + title row
              Row(children: [
                Expanded(child: Text(plan.title, style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? AppColors.neonGold : AppColors.jadeWhite,
                  letterSpacing: 1,
                ))),
                if (plan.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: plan.id == TzProducts.lifetime
                        ? AppColors.neonGold.withOpacity(0.2)
                        : AppColors.neonGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(plan.badge!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                        color: plan.id == TzProducts.lifetime
                          ? AppColors.neonGold : Colors.black,
                    )),
                  ),
              ]),
              const SizedBox(height: 6),
              // Price
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(plan.price, style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.jadeWhite)),
                if (plan.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(plan.subtitle, style: const TextStyle(
                      fontSize: 12, color: AppColors.jadeWhiteDim)),
                  ),
              ]),
              const SizedBox(height: 10),
              // Features
              ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const Icon(Icons.check, size: 14, color: AppColors.neonGold),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: const TextStyle(
                    fontSize: 12, color: AppColors.jadeWhiteDim, height: 1.4))),
                ]),
              )),
            ]),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildError(String message) {
    return TzCard(padding: const EdgeInsets.all(16), child: Column(children: [
      const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: AppColors.jadeWhiteDim)),
      const SizedBox(height: 12),
      TzButton(label: 'RETRY', style: TzButtonStyle.ghost,
        onPressed: () => ref.read(iapServiceProvider).init()),
    ]));
  }

  Widget _buildRestoreButton() {
    final l10n = AppLocalizations.of(context)!;
    return TextButton(
      onPressed: () => ref.read(iapServiceProvider).restore(),
      child: Text(l10n.premiumRestore,
        style: TextStyle(fontSize: 12, color: AppColors.jadeWhiteMuted,
          decoration: TextDecoration.underline)),
    );
  }

  Widget _buildAllPlansFooter() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.jadeCard.withOpacity(0.5),
      ),
      child: Column(children: [
        Text(l10n.premiumAllPlansHeader,
          style: const TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted)),
        const SizedBox(height: 6),
        Text(l10n.premiumAllPlansFooter,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteDim)),
      ]),
    );
  }

  void _purchase(String id) {
    if (id == 'free') {
      context.pop();
      return;
    }
    // 显示购买中状态
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connecting to App Store...'),
        duration: Duration(seconds: 2)));

    ref.read(iapServiceProvider).purchase(id).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase successful! 🎉'),
            backgroundColor: Colors.green));
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
      }
    });
  }
}

/// Models one pricing tier for the UI.
class _Plan {
  final String id;
  final String title;
  final String price;
  final String subtitle;
  final String? badge;
  final List<String> features;
  final bool isFree;

  const _Plan({
    required this.id,
    required this.title,
    required this.price,
    this.subtitle = '',
    this.badge,
    this.features = const [],
    this.isFree = false,
  });
}
