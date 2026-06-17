import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/hearts/heart_provider.dart';
import 'package:tilezhan/core/hearts/heart_service.dart';
import 'package:tilezhan/core/iap/iap_provider.dart';
import 'package:tilezhan/core/iap/iap_service.dart';
import 'package:tilezhan/shared/widgets/tz_battle_report.dart';

class _FakeHeartService extends HeartService {
  @override int get hearts => 0;
  @override int get correct => 7;
  @override int get wrong => 3;
  @override int get maxCombo => 4;
  @override int get combo => 0;
  @override int get allTimeCombo => 5; // below 10, no promo
  @override Future<void> init() async {}
  @override void recordCorrect() {}
  @override void recordWrong() {}
  @override bool consume() => false;
}

class _FakeIap implements IapService {
  final _sc = StreamController<IapState>.broadcast();
  _FakeIap() { _sc.add(const IapState(status: IapStatus.ready)); }
  @override Stream<IapState> get stateStream => _sc.stream;
  @override IapState get state => const IapState(status: IapStatus.ready);
  @override Future<void> init() async {}
  @override Future<void> purchase(String id) async {}
  @override Future<void> restore() async {}
  @override void dispose() => _sc.close();
}

Widget _wrap(Widget child) {
  return ProviderScope(overrides: [
    heartServiceProvider.overrideWith((ref) => _FakeHeartService()),
    iapServiceProvider.overrideWith((ref) => _FakeIap()),
  ], child: MaterialApp(home: child));
}

void main() {
  group('TzBattleReport', () {
    testWidgets('shows stats', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: TzBattleReport())));
      await tester.pumpAndSettle();
      expect(find.text('Today\'s Battle Report'), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // 7+3 total
      expect(find.text('70%'), findsOneWidget);
    });

    testWidgets('shows Share button', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: TzBattleReport())));
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('shows premium CTA', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: TzBattleReport())));
      await tester.pumpAndSettle();
      expect(find.text('Mistakes'), findsOneWidget);
    });

    testWidgets('shows premium subscribe button', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: TzBattleReport())));
      await tester.pumpAndSettle();
      expect(find.textContaining('4.99'), findsOneWidget);
    });
  });
}
