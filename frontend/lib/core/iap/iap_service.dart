import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Product IDs — must match App Store Connect exactly.
class TzProducts {
  TzProducts._();

  static const String yearly = 'com.tilezhan.app.premium.yearly';
  static const String monthly = 'com.tilezhan.app.premium.monthly';
  static const String weekly = 'com.tilezhan.app.premium.weekly';

  static const Set<String> all = {yearly, monthly, weekly};
}

/// Reactive IAP state.
class IapState {
  final IapStatus status;
  final List<ProductDetails> products;
  final Set<String> activeEntitlements;
  final String? error;

  const IapState({
    this.status = IapStatus.loading,
    this.products = const [],
    this.activeEntitlements = const {},
    this.error,
  });

  bool get isPremium => activeEntitlements.isNotEmpty;
  bool get hasProducts => products.isNotEmpty;

  ProductDetails? operator [](String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

enum IapStatus { loading, ready, purchasing, restoring, error, unavailable }

/// Thin wrapper around [InAppPurchase] with Riverpod-friendly streams.
class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;

  final _stateCtrl = StreamController<IapState>.broadcast();
  IapState _state = const IapState();

  Stream<IapState> get stateStream => _stateCtrl.stream;
  IapState get state => _state;

  Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) {
      _emit(_state.copyWith(status: IapStatus.unavailable));
      return;
    }
    _iap.purchaseStream.listen(_onPurchaseUpdate);
    await _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await _iap.queryProductDetails(TzProducts.all);
      if (response.notFoundIDs.isNotEmpty) {
        // Products not yet configured in App Store Connect — not fatal.
        print('⚠ SKUs not found: ${response.notFoundIDs}');
      }
      _emit(_state.copyWith(
        status: IapStatus.ready,
        products: response.productDetails,
      ));
    } catch (e) {
      _emit(_state.copyWith(status: IapStatus.error, error: e.toString()));
    }
  }

  Future<void> purchase(String productId) async {
    final details = _state.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw StateError('Product not found: $productId'),
    );
    _emit(_state.copyWith(status: IapStatus.purchasing));
    try {
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: details));
    } catch (e) {
      _emit(_state.copyWith(status: IapStatus.error, error: e.toString()));
      rethrow;
    }
  }

  Future<void> restore() async {
    _emit(_state.copyWith(status: IapStatus.restoring));
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _emit(_state.copyWith(status: IapStatus.error, error: e.toString()));
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final entitlements = {..._state.activeEntitlements, p.productID};
          _iap.completePurchase(p);
          _emit(_state.copyWith(
            status: IapStatus.ready,
            activeEntitlements: entitlements,
          ));
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          _emit(_state.copyWith(status: IapStatus.error, error: p.error?.message));
        case PurchaseStatus.canceled:
          _emit(_state.copyWith(status: IapStatus.ready));
      }
    }
  }

  void _emit(IapState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  void dispose() => _stateCtrl.close();
}

// Helpers for immutable state
extension _IapStateCopy on IapState {
  IapState copyWith({
    IapStatus? status,
    List<ProductDetails>? products,
    Set<String>? activeEntitlements,
    String? error,
    bool clearError = false,
  }) {
    return IapState(
      status: status ?? this.status,
      products: products ?? this.products,
      activeEntitlements: activeEntitlements ?? this.activeEntitlements,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
