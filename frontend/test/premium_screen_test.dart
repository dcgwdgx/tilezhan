import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tilezhan/core/commerce/commerce_availability.dart';
import 'package:tilezhan/core/iap/iap_provider.dart';
import 'package:tilezhan/core/iap/iap_service.dart';
import 'package:tilezhan/features/premium/presentation/premium_screen.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';

class _FakeIapService implements IapService {
  _FakeIapService(this._state);

  final _stateCtrl = StreamController<IapState>.broadcast();
  final IapState _state;
  int initCalls = 0;
  int restoreCalls = 0;
  final List<String> purchaseIds = [];

  @override
  Stream<IapState> get stateStream => _stateCtrl.stream;

  @override
  IapState get state => _state;

  @override
  Future<void> init() async {
    initCalls++;
    scheduleMicrotask(() {
      if (!_stateCtrl.isClosed) _stateCtrl.add(_state);
    });
  }

  @override
  Future<void> purchase(String productId) async {
    purchaseIds.add(productId);
  }

  @override
  Future<void> restore() async {
    restoreCalls++;
  }

  @override
  void dispose() {
    if (!_stateCtrl.isClosed) _stateCtrl.close();
  }
}

CommerceAvailability _availability({
  required bool salesEnabled,
  bool restoreEnabled = true,
}) {
  return CommerceAvailability(
    platform: TargetPlatform.iOS,
    salesEnabled: salesEnabled,
    trainingLimitsEnabled: false,
    restoreEnabled: restoreEnabled,
  );
}

Widget _wrap({
  required CommerceAvailability availability,
  required _FakeIapService service,
  required VoidCallback onServiceCreated,
}) {
  return ProviderScope(
    overrides: [
      commerceAvailabilityProvider.overrideWithValue(availability),
      iapServiceProvider.overrideWith((ref) {
        onServiceCreated();
        service.init();
        return service;
      }),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [Locale('en')],
      home: PremiumScreen(),
    ),
  );
}

ProductDetails _product({
  required String id,
  required String title,
  required String description,
  required String price,
  required double rawPrice,
}) {
  return ProductDetails(
    id: id,
    title: title,
    description: description,
    price: price,
    rawPrice: rawPrice,
    currencyCode: 'USD',
  );
}

void main() {
  group('PremiumScreen release availability', () {
    testWidgets('free release does not initialize or expose IAP sales',
        (tester) async {
      var serviceCreations = 0;
      final service = _FakeIapService(const IapState(status: IapStatus.ready));
      addTearDown(service.dispose);

      await tester.pumpWidget(_wrap(
        availability: _availability(salesEnabled: false),
        service: service,
        onServiceCreated: () => serviceCreations++,
      ));
      await tester.pump();

      expect(
        find.text('All training is free in this version'),
        findsOneWidget,
      );
      expect(find.text('Choose Your Plan'), findsNothing);
      expect(find.text('CONTINUE'), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
      expect(serviceCreations, 0);
      expect(service.initCalls, 0);
    });

    testWidgets('restore initializes IAP only after the explicit tap',
        (tester) async {
      var serviceCreations = 0;
      final service = _FakeIapService(const IapState(status: IapStatus.ready));
      addTearDown(service.dispose);

      await tester.pumpWidget(_wrap(
        availability: _availability(salesEnabled: false),
        service: service,
        onServiceCreated: () => serviceCreations++,
      ));
      await tester.pump();

      expect(serviceCreations, 0);
      await tester.tap(find.text('Restore Purchases'));
      await tester.pump();

      expect(serviceCreations, 1);
      expect(service.initCalls, 1);
      expect(service.restoreCalls, 1);
    });

    testWidgets('restore action is absent when the platform disables it',
        (tester) async {
      var serviceCreations = 0;
      final service = _FakeIapService(const IapState(status: IapStatus.ready));
      addTearDown(service.dispose);

      await tester.pumpWidget(_wrap(
        availability: _availability(
          salesEnabled: false,
          restoreEnabled: false,
        ),
        service: service,
        onServiceCreated: () => serviceCreations++,
      ));
      await tester.pump();

      expect(find.text('Restore Purchases'), findsNothing);
      expect(serviceCreations, 0);
    });

    testWidgets('sales mode renders only actual store products',
        (tester) async {
      var serviceCreations = 0;
      final service = _FakeIapService(IapState(
        status: IapStatus.ready,
        products: [
          _product(
            id: TzProducts.monthly,
            title: 'Store Monthly',
            description: 'Localized store description',
            price: r'$7.31',
            rawPrice: 7.31,
          ),
        ],
      ));
      addTearDown(service.dispose);

      await tester.pumpWidget(_wrap(
        availability: _availability(salesEnabled: true),
        service: service,
        onServiceCreated: () => serviceCreations++,
      ));
      await tester.pumpAndSettle();

      expect(serviceCreations, 1);
      expect(find.text('Store Monthly'), findsOneWidget);
      expect(find.text(r'$7.31'), findsOneWidget);
      expect(find.text('Localized store description'), findsOneWidget);
      expect(find.text('MONTHLY'), findsNothing);
      expect(find.text('ANNUAL'), findsNothing);
      expect(find.text('LIFETIME'), findsNothing);
      expect(find.text(r'$4.99'), findsNothing);
      expect(find.text(r'$29.99'), findsNothing);
      expect(find.text(r'$49.99'), findsNothing);
      expect(find.text('★ POPULAR'), findsNothing);
    });

    testWidgets('sales mode with no products exposes no purchase CTA',
        (tester) async {
      final service = _FakeIapService(const IapState(
        status: IapStatus.ready,
        products: [],
      ));
      addTearDown(service.dispose);

      await tester.pumpWidget(_wrap(
        availability: _availability(salesEnabled: true),
        service: service,
        onServiceCreated: () {},
      ));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Purchases are temporarily unavailable. '
          'No store products are currently offered.',
        ),
        findsOneWidget,
      );
      expect(find.text('SELECT A PLAN'), findsNothing);
      expect(find.text('CONTINUE'), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
    });

    testWidgets('purchase uses the selected real product id', (tester) async {
      final service = _FakeIapService(IapState(
        status: IapStatus.ready,
        products: [
          _product(
            id: TzProducts.lifetime,
            title: 'Store Lifetime',
            description: '',
            price: '€41.00',
            rawPrice: 41,
          ),
        ],
      ));
      addTearDown(service.dispose);

      await tester.pumpWidget(_wrap(
        availability: _availability(salesEnabled: true),
        service: service,
        onServiceCreated: () {},
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Store Lifetime'));
      await tester.pump();
      await tester.tap(find.text('CONTINUE'));
      await tester.pump();

      expect(service.purchaseIds, [TzProducts.lifetime]);
    });
  });
}
