import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/commerce/commerce_availability.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/iap/iap_provider.dart';
import '../../../core/iap/iap_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/tz_button.dart';
import '../../../shared/widgets/tz_card.dart';

/// Store screen whose contents are controlled by the current release policy.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  String? _selectedId;
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    // Read the release policy before touching any IAP provider. In a free
    // release this keeps StoreKit / Play Billing fully lazy.
    final availability = ref.watch(commerceAvailabilityProvider);

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
        child: availability.salesEnabled
            ? _buildSalesSurface(availability)
            : _buildFreeRelease(availability),
      ),
    );
  }

  Widget _buildFreeRelease(CommerceAvailability availability) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        const Icon(Icons.school_outlined, color: AppColors.neonGold, size: 52),
        const SizedBox(height: 16),
        Text(
          l10n.premiumFreeReleaseTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.neonGold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.premiumFreeReleaseBody,
          textAlign: TextAlign.center,
          style: const TextStyle(
            height: 1.5,
            fontSize: 14,
            color: AppColors.jadeWhiteDim,
          ),
        ),
        if (availability.restoreEnabled) ...[
          const SizedBox(height: 28),
          TzCard(
            child: Column(
              children: [
                Text(
                  l10n.premiumRestoreHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.jadeWhiteMuted,
                  ),
                ),
                const SizedBox(height: 12),
                TzButton(
                  label: _isRestoring
                      ? l10n.premiumRestoring
                      : l10n.premiumRestore,
                  style: TzButtonStyle.ghost,
                  onPressed: _isRestoring ? null : _restorePurchases,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildLegalLinks(),
      ],
    );
  }

  Widget _buildSalesSurface(CommerceAvailability availability) {
    final iapAsync = ref.watch(iapStateProvider);

    return iapAsync.when(
      data: (state) => _buildStoreContent(state, availability),
      loading: _buildLoading,
      error: (_, __) => _buildStoreMessage(
        AppLocalizations.of(context)!.premiumUnavailable,
        showRetry: true,
      ),
    );
  }

  Widget _buildLoading() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.neonGold),
          const SizedBox(height: 16),
          Text(
            l10n.premiumConnecting,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.jadeWhiteDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreContent(
    IapState state,
    CommerceAvailability availability,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (state.status == IapStatus.loading) return _buildLoading();
    if (state.status == IapStatus.error ||
        state.status == IapStatus.unavailable) {
      return _buildStoreMessage(l10n.premiumUnavailable, showRetry: true);
    }

    final products = List<ProductDetails>.of(state.products)
      ..sort((a, b) {
        final priceOrder = a.rawPrice.compareTo(b.rawPrice);
        return priceOrder != 0 ? priceOrder : a.id.compareTo(b.id);
      });
    final selectedProductAvailable =
        products.any((product) => product.id == _selectedId);
    final isPurchasing = state.status == IapStatus.purchasing;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('💎',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        Text(
          l10n.premiumTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.neonGold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 20),
        if (products.isEmpty)
          TzCard(
            child: Text(
              l10n.premiumNoProducts,
              textAlign: TextAlign.center,
              style: const TextStyle(
                height: 1.4,
                color: AppColors.jadeWhiteDim,
              ),
            ),
          )
        else ...[
          for (final product in products)
            _buildProductCard(product, disabled: isPurchasing),
          const SizedBox(height: 10),
          TzButton(
            label: isPurchasing
                ? l10n.premiumPurchasing
                : (selectedProductAvailable
                    ? l10n.premiumContinue
                    : l10n.premiumSelectPlan),
            style: TzButtonStyle.gold,
            onPressed: selectedProductAvailable && !isPurchasing
                ? () => _purchase(_selectedId!)
                : null,
          ),
        ],
        if (availability.restoreEnabled) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isRestoring ? null : _restorePurchases,
            child: Text(
              _isRestoring ? l10n.premiumRestoring : l10n.premiumRestore,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.jadeWhiteMuted,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildLegalLinks(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildProductCard(
    ProductDetails product, {
    required bool disabled,
  }) {
    final isSelected = _selectedId == product.id;
    final description = product.description.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: isSelected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: disabled
                ? null
                : () => setState(() => _selectedId = product.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.neonGold.withValues(alpha: 0.12)
                    : AppColors.jadeCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.neonGold : AppColors.jadeHover,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? AppColors.neonGold
                                : AppColors.jadeWhite,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        product.price,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.neonGold,
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        height: 1.35,
                        fontSize: 12,
                        color: AppColors.jadeWhiteDim,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreMessage(String message, {required bool showRetry}) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: TzCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.store_outlined,
                  color: AppColors.jadeWhiteDim, size: 36),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  height: 1.4,
                  fontSize: 13,
                  color: AppColors.jadeWhiteDim,
                ),
              ),
              if (showRetry) ...[
                const SizedBox(height: 14),
                TzButton(
                  label: l10n.premiumRetry,
                  style: TzButtonStyle.ghost,
                  onPressed: () => ref.read(iapServiceProvider).init(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalLinks() {
    final l10n = AppLocalizations.of(context)!;
    const privacyUrl = 'https://tz.slxing.com/privacy.html';
    const termsUrl = 'https://tz.slxing.com/terms.html';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => launchUrl(
            Uri.parse(privacyUrl),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(
            l10n.premiumPrivacy,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.neonGold.withValues(alpha: 0.7),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '·',
            style: TextStyle(
              color: AppColors.jadeWhiteMuted.withValues(alpha: 0.3),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => launchUrl(
            Uri.parse(termsUrl),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(
            l10n.premiumTerms,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.neonGold.withValues(alpha: 0.7),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _restorePurchases() async {
    if (_isRestoring) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isRestoring = true);

    try {
      // Reading this provider is intentionally delayed until this explicit tap.
      final service = ref.read(iapServiceProvider);
      var state = service.state;
      if (state.status == IapStatus.loading) {
        state = await service.stateStream
            .firstWhere((next) => next.status != IapStatus.loading)
            .timeout(const Duration(seconds: 15));
      }
      if (state.status == IapStatus.error ||
          state.status == IapStatus.unavailable) {
        throw StateError('Store unavailable');
      }

      await service.restore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.premiumRestoreRequested)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.premiumRestoreFailed),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _purchase(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final availability = ref.read(commerceAvailabilityProvider);
    final state = ref.read(iapServiceProvider).state;
    if (!availability.salesEnabled ||
        !state.products.any((product) => product.id == id)) {
      return;
    }

    try {
      await ref.read(iapServiceProvider).purchase(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.premiumPurchaseStarted)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.premiumPurchaseFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
