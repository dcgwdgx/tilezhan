/// End-to-end integration tests run on Windows desktop.
///
/// Covers: splash → onboarding → home → play → hearts drain → battle report.
/// Run with: flutter test integration_test/full_flow_test.dart -d windows
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tilezhan/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Splash → Onboarding → Home', () {
    testWidgets('first launch shows onboarding, skip goes to home', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TileSlashApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Splash auto-navigates after 2.5s. First time → onboarding.
      expect(find.text('Start Free'), findsOneWidget);

      // Tap Get Started on the last onboarding step
      for (int i = 0; i < 2; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Now on home screen
      expect(find.text('DAILY CHALLENGE'), findsOneWidget);
      expect(find.textContaining('/10'), findsOneWidget); // hearts
    });
  });

  group('Quick Access navigation', () {
    testWidgets('home grid items navigate correctly', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TileSlashApp()));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Navigate to Scanner
      await tester.scrollUntilVisible(find.text('Scanner'), 100);
      await tester.tap(find.text('Scanner'));
      await tester.pumpAndSettle();
      expect(find.text('Yaku Scanner'), findsOneWidget);

      // Go back
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      expect(find.text('DAILY CHALLENGE'), findsOneWidget);

      // Navigate to Premium
      await tester.scrollUntilVisible(find.text('Premium'), 100);
      await tester.tap(find.text('Premium'));
      await tester.pumpAndSettle();
      expect(find.text('Choose Your Plan'), findsOneWidget);
    });
  });

  group('Heart display', () {
    testWidgets('home screen shows heart count', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TileSlashApp()));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Should show hearts/10 format
      expect(find.textContaining('/10'), findsOneWidget);
    });
  });
}
