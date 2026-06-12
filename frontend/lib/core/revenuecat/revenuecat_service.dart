import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Purchases.configure(PurchasesConfiguration('REPLACE_WITH_RC_KEY'));
      _initialized = true;
    } catch (_) {}
  }

  static Future<Offerings?> getOfferings() async {
    if (!_initialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  static Future<CustomerInfo> purchase(Package pkg) async {
    return Purchases.purchasePackage(pkg);
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
