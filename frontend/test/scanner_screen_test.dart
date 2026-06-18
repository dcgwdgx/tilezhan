import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';
import 'package:tilezhan/features/scanner/presentation/scanner_screen.dart';

void main() {
  Hive.init('./test/hive_scanner');

  setUp(() async {
    await Hive.openBox('yaku_favorites');
  });

  tearDown(() async {
    await Hive.close();
  });

  group('ScannerScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: ScannerScreen(),
        ),
      ));
      await tester.pump();
      expect(find.byType(ScannerScreen), findsOneWidget);
    });
  });
}
