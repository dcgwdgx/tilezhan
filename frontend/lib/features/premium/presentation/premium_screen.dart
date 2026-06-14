import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/iap/iap_provider.dart';
import '../../../core/iap/iap_service.dart';
import '../../../shared/widgets/tz_button.dart';
import '../../../shared/widgets/tz_card.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  String? _selectedProductId;

  @override
  Widget build(BuildContext context) {
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
    return const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: AppColors.neonGold),
        SizedBox(height: 16),
        Text('Connecting to App Store...',
          style: TextStyle(fontSize: 14, color: AppColors.jadeWhiteDim)),
      ]),
    );
  }

  Widget _buildContent(IapState state) {
    final isPurchasing = state.status == IapStatus.purchasing;
    final isRestoring = state.status == IapStatus.restoring;
    final error = state.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Text('💎', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 8),
        const Text('TILEZHAN PRO',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
            color: AppColors.neonGold, letterSpacing: 3)),
        const SizedBox(height: 8),
        const Text('Unlimited Learning. Zero Interruptions.',
          style: TextStyle(fontSize: 14, color: AppColors.jadeWhiteDim)),
        const SizedBox(height: 24),
        _buildFeatureList(),
        const SizedBox(height: 24),

        if (error != null)
          _buildError(error)
        else if (state.hasProducts)
          ..._buildPricingCards(state, isPurchasing)
        else if (state.status == IapStatus.unavailable)
          TzCard(padding: const EdgeInsets.all(16), child: const Text(
            'In-App Purchases are not available on this device.',
            style: TextStyle(color: AppColors.jadeWhiteDim))),
        const SizedBox(height: 24),

        TzButton(
          label: isPurchasing ? 'PURCHASING...' : 'START FREE TRIAL',
          style: TzButtonStyle.gold,
          onPressed: _selectedProductId != null && !isPurchasing
            ? () => _purchase(_selectedProductId!)
            : null,
        ),
        const SizedBox(height: 16),
        _buildFooter(isRestoring),
        const SizedBox(height: 40),
      ]),
    );
  }

  List<Widget> _buildPricingCards(IapState state, bool disabled) {
    // Sort: yearly first (best value), then monthly, then weekly
    final sorted = state.products.toList()
      ..sort((a, b) => (b.rawPrice).compareTo(a.rawPrice));

    final badges = <String, String?>{
      TzProducts.yearly: '🌟 BEST VALUE — 50% OFF',
      TzProducts.monthly: null,
      TzProducts.weekly: null,
    };

    return sorted.map((p) {
      final id = p.id;
      final badge = badges[id];
      final isSelected = _selectedProductId == id;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: disabled ? null : () => setState(() => _selectedProductId = id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSelected
                ? AppColors.neonGold.withOpacity(0.12)
                : AppColors.jadeCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.neonGold : AppColors.jadeHover,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(children: [
              if (isSelected)
                Container(
                  width: 24, height: 24,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.neonGold),
                  child: const Icon(Icons.check, size: 16, color: Colors.black),
                ),
              const SizedBox(width: 8),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null)
                    Text(badge, style: const TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w700, color: AppColors.neonGold)),
                  Text(p.title, style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w800, color: isSelected
                      ? AppColors.neonGold : AppColors.jadeWhite)),
                  Text(p.price, style: const TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w900, color: AppColors.jadeWhite)),
                  Text(p.description, style: const TextStyle(fontSize: 12,
                    color: AppColors.jadeWhiteDim)),
                ],
              )),
            ]),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildFooter(bool isRestoring) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      GestureDetector(
        onTap: isRestoring ? null : _restore,
        child: Text(
          isRestoring ? 'RESTORING...' : 'Restore Purchases',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.jadeWhiteMuted.withOpacity(0.6),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      const Text('  ·  ', style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted)),
      const Text('Terms', style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted)),
      const Text('  ·  ', style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted)),
      const Text('Privacy', style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted)),
    ]);
  }

  Widget _buildError(String message) {
    return TzCard(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.jadeWhiteDim)),
        const SizedBox(height: 12),
        TzButton(
          label: 'RETRY',
          style: TzButtonStyle.ghost,
          onPressed: () => ref.read(iapServiceProvider).init(),
        ),
      ]),
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
      children: features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(f, style: const TextStyle(fontSize: 14,
          fontWeight: FontWeight.w600, color: AppColors.jadeWhite, height: 1.5)),
      )).toList(),
    ));
  }

  void _purchase(String productId) {
    ref.read(iapServiceProvider).purchase(productId).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')));
      }
    });
  }

  void _restore() {
    ref.read(iapServiceProvider).restore();
  }
}
