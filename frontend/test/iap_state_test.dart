import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tilezhan/core/iap/iap_service.dart';

void main() {
  group('TzProducts', () {
    test('all product IDs use correct prefix', () {
      for (final id in TzProducts.all) {
        expect(id, startsWith('com.tilezhan.app.premium.'));
      }
    });

    test('all product IDs are unique', () {
      expect(TzProducts.all.length, 3);
      expect(TzProducts.all.toSet().length, 3);
    });
  });

  group('IapState', () {
    test('default state is loading with empty products', () {
      const state = IapState();
      expect(state.status, IapStatus.loading);
      expect(state.products, isEmpty);
      expect(state.activeEntitlements, isEmpty);
      expect(state.error, isNull);
      expect(state.isPremium, isFalse);
      expect(state.hasProducts, isFalse);
    });

    test('isPremium true when entitlements exist', () {
      const state = IapState(
        status: IapStatus.ready,
        activeEntitlements: {TzProducts.yearly},
      );
      expect(state.isPremium, isTrue);
    });

    test('isPremium false when no entitlements', () {
      const state = IapState(status: IapStatus.ready);
      expect(state.isPremium, isFalse);
    });

    test('copyWith preserves unset fields', () {
      const original = IapState(
        status: IapStatus.ready,
        products: [],
        activeEntitlements: {TzProducts.monthly},
      );
      final updated = original.copyWith(status: IapStatus.purchasing);
      expect(updated.status, IapStatus.purchasing);
      expect(updated.products, []);
      expect(updated.activeEntitlements, {TzProducts.monthly});
      expect(updated.error, isNull);
    });

    test('copyWith replaces all set fields', () {
      const original = IapState(status: IapStatus.ready);
      final updated = original.copyWith(
        status: IapStatus.error,
        error: 'test error',
        activeEntitlements: {},
      );
      expect(updated.status, IapStatus.error);
      expect(updated.error, 'test error');
      expect(updated.activeEntitlements, isEmpty);
    });

    test('copyWith clearError removes error', () {
      const original = IapState(status: IapStatus.error, error: 'fail');
      final cleared = original.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('operator [] finds product by id', () {
      final pd1 = _fakeProduct('a');
      final pd2 = _fakeProduct('b');
      final state = IapState(status: IapStatus.ready, products: [pd1, pd2]);
      expect(state['a']!.id, 'a');
      expect(state['b']!.id, 'b');
    });

    test('operator [] returns null for missing id', () {
      final state = IapState(status: IapStatus.ready, products: [_fakeProduct('x')]);
      expect(state['y'], isNull);
    });

    test('hasProducts true when products list is populated', () {
      final state = IapState(
        status: IapStatus.ready,
        products: [_fakeProduct('a')],
      );
      expect(state.hasProducts, isTrue);
    });
  });
}

ProductDetails _fakeProduct(String id) => ProductDetails(
  id: id,
  title: 'Test $id',
  description: 'Description for $id',
  price: '\$${id.hashCode % 10}.99',
  rawPrice: (id.hashCode % 10 + 0.99),
  currencyCode: 'USD',
);
