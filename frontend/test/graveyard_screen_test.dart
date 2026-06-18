import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/graveyard/presentation/graveyard_screen.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';

void main() {
  group('GraveyardScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const GraveyardScreen(),
        ),
      ));
      await tester.pump();
      expect(find.byType(GraveyardScreen), findsOneWidget);
    });
  });
}
