import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/hearts/heart_provider.dart';
import 'package:tilezhan/core/hearts/heart_service.dart';
import 'package:tilezhan/shared/widgets/tz_battle_report.dart';

class _FakeHeartService extends HeartService {
  @override int get hearts => 0;
  @override int get correct => 7;
  @override int get wrong => 3;
  @override int get maxCombo => 4;
  @override int get combo => 0;
  @override Future<void> init() async {}
  @override void recordCorrect() {}
  @override void recordWrong() {}
  @override bool consume() => false;
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [heartServiceProvider.overrideWith((ref) => _FakeHeartService())],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('TzBattleReport', () {
    testWidgets('shows battle report with correct stats', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: TzBattleReport())));
      await tester.pumpAndSettle();
      expect(find.text('Today\'s Battle Report'), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // 7 + 3 total
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('4×'), findsOneWidget);
    });

    testWidgets('shows premium CTA', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: TzBattleReport())));
      await tester.pumpAndSettle();
      expect(find.textContaining('4.99'), findsOneWidget);
    });

    testWidgets('shows action buttons: Share, Mistakes, Invite', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: TzBattleReport())));
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Mistakes'), findsOneWidget);
      expect(find.text('Invite'), findsOneWidget);
    });

    testWidgets('shows app domain', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: TzBattleReport())));
      await tester.pumpAndSettle();
      expect(find.text('tilezhan.app'), findsOneWidget);
    });
  });
}
