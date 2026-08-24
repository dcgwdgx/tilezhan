/// Verifies locale switching actually changes UI text.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tilezhan/core/providers/locale_provider.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';

void main() {
  setUpAll(() async {
    Hive.init('./test/hive_locale_test');
    await Hive.openBox('prefs');
    Hive.box('prefs').put('app_language', 'en');
    localeModel.init();
  });

  group('Locale switch — pure l10n test', () {
    // Use a simple Text widget directly to test locale switching without complex widget trees
    Widget simpleTestApp() {
      return ProviderScope(
        child: ListenableBuilder(
          listenable: localeModel,
          builder: (context, _) => MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: localeModel.locale,
            home: Builder(builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(body: Center(child: Text(l10n.battleShare)));
            }),
          ),
        ),
      );
    }

    testWidgets('English shows Share', (tester) async {
      localeModel.switchTo('en');
      await tester.pumpWidget(simpleTestApp());
      await tester.pump();
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('German shows Teilen', (tester) async {
      localeModel.switchTo('de');
      await tester.pumpWidget(simpleTestApp());
      await tester.pump();
      expect(find.text('Teilen'), findsOneWidget);
    });

    testWidgets('French shows Partager', (tester) async {
      localeModel.switchTo('fr');
      await tester.pumpWidget(simpleTestApp());
      await tester.pump();
      expect(find.text('Partager'), findsOneWidget);
    });
  });
}
