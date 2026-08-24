import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/commerce/commerce_availability.dart';
import 'package:tilezhan/core/hearts/heart_provider.dart';
import 'package:tilezhan/core/hearts/heart_service.dart';
import 'package:tilezhan/core/iap/iap_provider.dart';
import 'package:tilezhan/core/iap/iap_service.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';
import 'package:tilezhan/shared/widgets/tz_battle_report.dart';

class _FakeHeartService extends HeartService {
  _FakeHeartService({required this.comboRecord});

  final int comboRecord;

  @override
  int get hearts => 0;
  @override
  int get correct => 7;
  @override
  int get wrong => 3;
  @override
  int get maxCombo => 4;
  @override
  int get combo => 0;
  @override
  int get allTimeCombo => comboRecord;
  @override
  Future<void> init() async {}
  @override
  void recordCorrect() {}
  @override
  void recordWrong() {}
  @override
  bool consume() => false;
}

class _FakeIap implements IapService {
  final _stateCtrl = StreamController<IapState>.broadcast();

  @override
  Stream<IapState> get stateStream => _stateCtrl.stream;
  @override
  IapState get state => const IapState(status: IapStatus.ready);
  @override
  Future<void> init() async {
    scheduleMicrotask(() {
      if (!_stateCtrl.isClosed) _stateCtrl.add(state);
    });
  }

  @override
  Future<void> purchase(String id) async {}
  @override
  Future<void> restore() async {}
  @override
  void dispose() {
    if (!_stateCtrl.isClosed) _stateCtrl.close();
  }
}

Widget _wrap({
  required bool salesEnabled,
  required int comboRecord,
  required VoidCallback onIapCreated,
}) {
  return ProviderScope(
    overrides: [
      commerceAvailabilityProvider.overrideWithValue(CommerceAvailability(
        platform: TargetPlatform.iOS,
        salesEnabled: salesEnabled,
        trainingLimitsEnabled: false,
        restoreEnabled: true,
      )),
      heartServiceProvider.overrideWith(
        (ref) => _FakeHeartService(comboRecord: comboRecord),
      ),
      iapServiceProvider.overrideWith((ref) {
        onIapCreated();
        final service = _FakeIap()..init();
        ref.onDispose(service.dispose);
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
      home: Scaffold(body: TzBattleReport()),
    ),
  );
}

void main() {
  group('TzBattleReport commerce availability', () {
    testWidgets('free release keeps report actions and hides all sales CTAs',
        (tester) async {
      var iapCreations = 0;
      await tester.pumpWidget(_wrap(
        salesEnabled: false,
        comboRecord: 12,
        onIapCreated: () => iapCreations++,
      ));
      await tester.pump();

      expect(find.text("Today's Battle Report"), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Mistakes'), findsOneWidget);
      expect(find.text('Invite'), findsOneWidget);
      expect(find.text('View Premium Options'), findsNothing);
      expect(find.text('COMBO ×10!'), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
      expect(iapCreations, 0);
    });

    testWidgets('sales release shows a price-neutral Premium CTA',
        (tester) async {
      await tester.pumpWidget(_wrap(
        salesEnabled: true,
        comboRecord: 4,
        onIapCreated: () {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('View Premium Options'), findsOneWidget);
      expect(find.textContaining(r'$'), findsNothing);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Mistakes'), findsOneWidget);
      expect(find.text('Invite'), findsOneWidget);
    });
  });
}
