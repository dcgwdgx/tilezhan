import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tilezhan/core/hearts/heart_service.dart';
import 'package:tilezhan/core/hearts/heart_provider.dart';
import 'package:tilezhan/core/iap/iap_provider.dart';
import 'package:tilezhan/core/iap/iap_service.dart';
import 'package:tilezhan/features/premium/presentation/premium_screen.dart';

/// Fake HeartService — returns no promo, always ready.
class _FakeHeartService extends HeartService {
  @override int get hearts => 10;
  @override Future<void> init() async {}
  @override bool isLifetimePromoActive(bool _) => true;
}

/// Fake IapService that returns products without StoreKit.
class _FakeIapService implements IapService {
  final _stateCtrl = StreamController<IapState>.broadcast();
  late IapState _state;

  _FakeIapService() {
    _state = IapState(
      status: IapStatus.ready,
      products: [
        ProductDetails(
          id: TzProducts.monthly,
          title: 'MONTHLY',
          description: 'Unlimited puzzles',
          price: '\$4.99',
          rawPrice: 4.99,
          currencyCode: 'USD',
        ),
        ProductDetails(
          id: TzProducts.yearly,
          title: 'ANNUAL',
          description: 'Best value',
          price: '\$29.99',
          rawPrice: 29.99,
          currencyCode: 'USD',
        ),
        ProductDetails(
          id: TzProducts.lifetime,
          title: 'LIFETIME',
          description: 'Pay once',
          price: '\$49.99',
          rawPrice: 49.99,
          currencyCode: 'USD',
        ),
      ],
    );
    // Emit initial state on next tick so StreamProvider picks it up
    Future.microtask(() => _stateCtrl.add(_state));
  }

  @override
  Stream<IapState> get stateStream => _stateCtrl.stream;
  @override
  IapState get state => _state;

  @override
  Future<void> init() async {}
  @override
  Future<void> purchase(String productId) async {}
  @override
  Future<void> restore() async {}
  @override
  void dispose() => _stateCtrl.close();
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      iapServiceProvider.overrideWith((ref) => _FakeIapService()),
      heartServiceProvider.overrideWith((ref) => _FakeHeartService()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('PremiumScreen', () {
    testWidgets('renders title and plan names', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Plan'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('MONTHLY'), findsOneWidget);
      expect(find.text('ANNUAL'), findsOneWidget);
      expect(find.text('LIFETIME'), findsOneWidget);
    });

    testWidgets('shows correct price for each plan', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumScreen()));
      await tester.pumpAndSettle();

      expect(find.text('\$0'), findsOneWidget);
      expect(find.text('\$4.99'), findsOneWidget);
      expect(find.text('\$29.99'), findsOneWidget);
      expect(find.text('\$49.99'), findsOneWidget);
    });

    testWidgets('shows popular badge on monthly', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumScreen()));
      await tester.pumpAndSettle();

      expect(find.text('★ POPULAR'), findsOneWidget);
    });

    testWidgets('shows best value badge on annual', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumScreen()));
      await tester.pumpAndSettle();

      expect(find.text('BEST VALUE — Save 50%'), findsOneWidget);
    });

    testWidgets('shows pay once badge on lifetime', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumScreen()));
      await tester.pumpAndSettle();

      expect(find.text('PAY ONCE'), findsOneWidget);
    });

    testWidgets('shows restore purchases', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Restore Purchases'), findsOneWidget);
    });

    testWidgets('free plan features listed', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumScreen()));
      await tester.pumpAndSettle();

      expect(find.text('10 puzzles/day'), findsOneWidget);
      expect(find.text('Mistakes free forever'), findsOneWidget);
    });

    testWidgets('unlimited feature in paid plans', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Unlimited puzzles'), findsOneWidget);
    });

    testWidgets('footer lists what all plans include', (tester) async {
      await tester.pumpWidget(_wrap(const PremiumScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('All paid plans include:'), findsOneWidget);
    });
  });
}
