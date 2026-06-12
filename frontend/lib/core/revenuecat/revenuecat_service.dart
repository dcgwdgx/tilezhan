import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat IAP service. Requires API keys configured in App Store Connect.
/// Free tier: $10K MTR (Monthly Tracked Revenue) before fees.
class RevenueCatService {
  static bool _initialized = false;

  /// Call once at app startup. Keys configured via RevenueCat dashboard.
  static Future<void> init({String? appleApiKey}) async {
    if (_initialized) return;
    try {
      await Purchases.configure(
        PurchasesConfiguration(appleApiKey ?? 'REPLACE_WITH_RC_APPLE_KEY'),
      );
      _initialized = true;
    } catch (_) {
      // Silently fail — IAP unavailable in dev/sim
    }
  }

  static Future<List<Package>> getOfferings() async {
    if (!_initialized) return [];
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<CustomerInfo> purchase(Package pkg) async {
    final result = await Purchases.purchasePackage(pkg);
    return result;
  }

  static Future<CustomerInfo> restore() async {
    return Purchases.restorePurchases();
  }

  static Future<bool> isPro() async {
    if (!_initialized) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey('pro');
    } catch (_) {
      return false;
    }
  }
}
