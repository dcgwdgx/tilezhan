import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/hearts/heart_provider.dart';
import 'package:tilezhan/core/hearts/heart_service.dart';
import 'package:tilezhan/core/iap/iap_provider.dart';
import 'package:tilezhan/core/iap/iap_service.dart';
import 'package:tilezhan/features/home/presentation/home_screen.dart';

/// Fake HeartService — returns preset values, never touches Hive.
class _FakeHeartService extends HeartService {
  @override int get hearts => 8;
  @override bool get hasHearts => true;
  @override int get correct => 3;
  @override int get wrong => 1;
  @override int get combo => 0;
  @override int get maxCombo => 2;
  @override int get dailyChallengeRemaining => 2;
  @override Future<void> init() async {}
  @override void recordCorrect() {}
  @override void recordWrong() {}
  @override bool consume() => false;
  @override bool useDailyChallenge() => true;
}

/// Fake IapService returning free status.
class _FakeIapService extends IapService {
  @override
  Future<void> init() async {}
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      heartServiceProvider
          .overrideWith((ref) => _FakeHeartService()),
      iapServiceProvider.overrideWith((ref) => _FakeIapService()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  // Shimmer animation repeats forever → pump with fixed frames
  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  group('HomeScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      await settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('shows Quick Access grid', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      await settle(tester);
      expect(find.text('Flashcards'), findsOneWidget);
      expect(find.text('Nani-Kiru'), findsOneWidget);
      expect(find.text('Scanner'), findsOneWidget);
    });

    testWidgets('shows bottom tab bar', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      await settle(tester);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Tiles'), findsOneWidget);
    });

    testWidgets('shows daily challenge card', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      await settle(tester);
      expect(find.textContaining('DAILY CHALLENGE'), findsOneWidget);
    });

    testWidgets('shows heart count', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      await settle(tester);
      expect(find.text('8/10'), findsOneWidget);
    });

    testWidgets('shows daily challenge start button', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      await settle(tester);
      expect(find.text('⚡ START CHALLENGE'), findsOneWidget);
    });

    testWidgets('shows free challenge count on daily challenge', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      await settle(tester);
      expect(find.text('2/3 free'), findsOneWidget);
    });

    testWidgets('premium section has upgrade badge', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      await settle(tester);
      expect(find.textContaining('UPGRADE'), findsOneWidget);
    });
  });
}
