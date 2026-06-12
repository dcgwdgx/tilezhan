import 'package:in_app_purchase/in_app_purchase.dart';

/// IAP service using Flutter's official in_app_purchase plugin.
/// Handles Apple App Store + Google Play purchases.
class RevenueCatService {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static bool _initialized = false;
  static List<ProductDetails> _products = [];

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _iap.restorePurchases();
  }

  static Future<List<ProductDetails>> getOfferings() async {
    if (_products.isNotEmpty) return _products;
    const ids = {
      'tilezhan_premium_monthly',
      'tilezhan_premium_yearly',
    };
    final response = await _iap.queryProductDetails(ids);
    _products = response.productDetails;
    return _products;
  }

  static Future<bool> purchase(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
    return true;
  }

  static Future<void> restore() async {
    await _iap.restorePurchases();
  }

  static Future<bool> isPro() async {
    await _iap.restorePurchases();
    // Check if any purchase was restored (simplified)
    return false; // Full implementation needs purchase stream
  }
}
