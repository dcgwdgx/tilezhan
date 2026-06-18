import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/hearts/heart_provider.dart';
import 'package:tilezhan/core/hearts/heart_service.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';
import 'package:tilezhan/shared/widgets/tz_combo_promo.dart';

/// Fake HeartService with 10+ combo for promo trigger.
class _PromoFake extends HeartService {
  @override int get allTimeCombo => 10;
  @override int get hearts => 5;
  @override int get correct => 0;
  @override int get wrong => 0;
  @override int get maxCombo => 0;
  @override Future<void> init() async {}
  @override void recordCorrect() {}
  @override void recordWrong() {}
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [heartServiceProvider.overrideWith((ref) => _PromoFake())],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: child,
    ),
  );
}

void main() {
  group('TzComboPromo', () {
    testWidgets('shows COMBO x10 title', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: TzComboPromo())));
      await tester.pumpAndSettle();
      expect(find.text('COMBO ×10!'), findsOneWidget);
    });

    testWidgets('shows discounted price', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: TzComboPromo())));
      await tester.pumpAndSettle();
      // Text.rich + TzButton label both contain the price
      expect(find.textContaining(r'23.99'), findsWidgets);
    });

    testWidgets('shows original price with strikethrough', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: TzComboPromo())));
      await tester.pumpAndSettle();
      expect(find.textContaining(r'29.99'), findsAtLeast(1));
    });

    testWidgets('shows UNLOCK NOW button', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: TzComboPromo())));
      await tester.pumpAndSettle();
      expect(find.text('UNLOCK NOW — \$23.99'), findsOneWidget);
    });

    testWidgets('shows Maybe later dismiss', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: TzComboPromo())));
      await tester.pumpAndSettle();
      expect(find.text('Maybe later'), findsOneWidget);
    });
  });
}
