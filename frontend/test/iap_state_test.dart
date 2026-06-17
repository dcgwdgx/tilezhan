/// IapState 应用内购买状态模型和商品定义测试
/// 测试覆盖：商品ID前缀、唯一性、默认状态、会员判定、copyWith 行为、商品查找、hasProducts
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tilezhan/core/iap/iap_service.dart';

void main() {
  group('TzProducts', () {
    // 所有商品 ID 使用统一前缀 com.tilezhan.app.premium.
    test('all product IDs use correct prefix', () {
      for (final id in TzProducts.all) {
        expect(id, startsWith('com.tilezhan.app.premium.'));
      }
    });

    // 3 个商品 ID 互不相同
    test('all product IDs are unique', () {
      expect(TzProducts.all.length, 3);
      expect(TzProducts.all.toSet().length, 3);
    });
  });

  group('IapState', () {
    // 默认状态：loading、空商品列表、无权益、非会员
    test('default state is loading with empty products', () {
      const state = IapState();
      expect(state.status, IapStatus.loading);
      expect(state.products, isEmpty);
      expect(state.activeEntitlements, isEmpty);
      expect(state.error, isNull);
      expect(state.isPremium, isFalse);
      expect(state.hasProducts, isFalse);
    });

    // 存在权益时 isPremium 为 true
    test('isPremium true when entitlements exist', () {
      const state = IapState(
        status: IapStatus.ready,
        activeEntitlements: {TzProducts.yearly},
      );
      expect(state.isPremium, isTrue);
    });

    // 无权益时 isPremium 为 false
    test('isPremium false when no entitlements', () {
      const state = IapState(status: IapStatus.ready);
      expect(state.isPremium, isFalse);
    });

    // copyWith 只修改指定字段，保留其他字段原值
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

    // copyWith 同时替换所有传入的字段
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

    // clearError 标志位能清除错误信息
    test('copyWith clearError removes error', () {
      const original = IapState(status: IapStatus.error, error: 'fail');
      final cleared = original.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    // operator [] 按商品 ID 查找对应的 ProductDetails
    test('operator [] finds product by id', () {
      final pd1 = _fakeProduct('a');
      final pd2 = _fakeProduct('b');
      final state = IapState(status: IapStatus.ready, products: [pd1, pd2]);
      expect(state['a']!.id, 'a');
      expect(state['b']!.id, 'b');
    });

    // operator [] 对不存在的 ID 返回 null
    test('operator [] returns null for missing id', () {
      final state = IapState(status: IapStatus.ready, products: [_fakeProduct('x')]);
      expect(state['y'], isNull);
    });

    // 商品列表非空时 hasProducts 为 true
    test('hasProducts true when products list is populated', () {
      final state = IapState(
        status: IapStatus.ready,
        products: [_fakeProduct('a')],
      );
      expect(state.hasProducts, isTrue);
    });
  });
}

/// 创建伪 ProductDetails 用于测试
ProductDetails _fakeProduct(String id) => ProductDetails(
  id: id,
  title: 'Test $id',
  description: 'Description for $id',
  price: '\$${id.hashCode % 10}.99',
  rawPrice: (id.hashCode % 10 + 0.99),
  currencyCode: 'USD',
);
