import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Product IDs — must match App Store Connect configuration.
/// These serve as the single source of truth for IAP product references.
class TzProducts {
  TzProducts._();

  // Subscriptions
  static const String premiumMonthly = 'com.tilezhan.app.premium.monthly';
  static const String premiumYearly = 'com.tilezhan.app.premium.yearly';

  // One-time purchases
  static const String lifetime = 'com.tilezhan.app.lifetime';
  static const String coinPackSmall = 'com.tilezhan.app.coins.small';
  static const String coinPackLarge = 'com.tilezhan.app.coins.large';

  /// All product IDs the app can query.
  static const Set<String> all = {
    premiumMonthly,
    premiumYearly,
    lifetime,
    coinPackSmall,
    coinPackLarge,
  };
}

/// Represents the IAP connection / purchase state.
enum IapStatus {
  /// Store not yet initialised.
  loading,

  /// Store available, products fetched.
  ready,

  /// Store unavailable (Simulator, parental controls, etc.).
  unavailable,

  /// A purchase is in flight.
  purchasing,

  /// An error occurred.
  error,
}

/// Wraps [ProductDetails] + an optional entitlement flag for UI convenience.
class TzProduct {
  final ProductDetails details;
  final bool isOwned;

  const TzProduct({required this.details, this.isOwned = false});

  String get id => details.id;
  String get title => details.title;
  String get description => details.description;
  String get price => details.price;
  String get currencyCode => details.currencyCode;
  bool get isSubscription =>
      details.id == TzProducts.premiumMonthly ||
      details.id == TzProducts.premiumYearly;
}

/// Lightweight IAP service backed by [in_app_purchase].
///
/// Responsibilities:
/// - Initialise the store connection.
/// - Fetch product metadata from the App Store.
/// - Execute purchases and restore previous purchases.
/// - Expose reactive state via [statusStream] and [productsStream].
class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;

  final StreamController<IapStatus> _statusCtrl =
      StreamController<IapStatus>.broadcast();
  final StreamController<List<TzProduct>> _productsCtrl =
      StreamController<List<TzProduct>>.broadcast();

  IapStatus _status = IapStatus.loading;
  List<ProductDetails> _storeProducts = [];
  Set<String> _entitlements = {};

  // ---------------------------------------------------------------------------
  // Public streams
  // ---------------------------------------------------------------------------

  Stream<IapStatus> get statusStream => _statusCtrl.stream;
  Stream<List<TzProduct>> get productsStream => _productsCtrl.stream;
  IapStatus get status => _status;
  List<TzProduct> get products => _storeProducts
      .map((p) => TzProduct(details: p, isOwned: _entitlements.contains(p.id)))
      .toList();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initialise the store connection and start listening for purchase updates.
  Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) {
      _setStatus(IapStatus.unavailable);
      return;
    }

    // Listen for purchase updates from the store (across sessions).
    _iap.purchaseStream.listen(_onPurchaseUpdate);

    await _fetchProducts();
  }

  /// Release resources.
  void dispose() {
    _statusCtrl.close();
    _productsCtrl.close();
  }

  // ---------------------------------------------------------------------------
  // Product fetching
  // ---------------------------------------------------------------------------

  Future<void> _fetchProducts() async {
    try {
      final response = await _iap.queryProductDetails(TzProducts.all);
      if (response.notFoundIDs.isNotEmpty) {
        // Products not configured in App Store Connect yet — not fatal.
        // ignore: avoid_print
        print('⚠ IAP products not found: ${response.notFoundIDs}');
      }
      _storeProducts = response.productDetails;
      _setStatus(IapStatus.ready);
      _emitProducts();
    } catch (e) {
      _setStatus(IapStatus.error);
    }
  }

  /// Re-fetch products (e.g. after StoreKit changes).  Safe to call anytime.
  Future<void> refreshProducts() => _fetchProducts();

  // ---------------------------------------------------------------------------
  // Purchases
  // ---------------------------------------------------------------------------

  /// Kick off a purchase for [productId].
  Future<bool> purchase(String productId) async {
    final details = _storeProducts.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw StateError('Product not found: $productId'),
    );

    _setStatus(IapStatus.purchasing);

    final param = PurchaseParam(productDetails: details);
    try {
      await _iap.buyNonConsumable(purchaseParam: param);
      return true;
    } catch (e) {
      _setStatus(IapStatus.error);
      rethrow;
    }
  }

  /// Restore previously purchased non-consumable / subscription products.
  Future<void> restore() async {
    _setStatus(IapStatus.loading);
    try {
      await _iap.restorePurchases();
      // Results arrive via [purchaseStream]; status is updated there.
    } catch (e) {
      _setStatus(IapStatus.error);
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      _handlePurchase(p);
    }
  }

  void _handlePurchase(PurchaseDetails purchase) {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        // Waiting for parental approval or similar — do nothing yet.
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        _entitlements.add(purchase.productID);
        _iap.completePurchase(purchase);
        _emitProducts();
        _setStatus(IapStatus.ready);
        break;

      case PurchaseStatus.error:
        _setStatus(IapStatus.error);
        break;

      case PurchaseStatus.canceled:
        _setStatus(IapStatus.ready);
        break;
    }
  }

  void _setStatus(IapStatus s) {
    _status = s;
    _statusCtrl.add(s);
  }

  void _emitProducts() {
    _productsCtrl.add(products);
  }
}
