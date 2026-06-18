import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';

void main() {
  group('LeaderboardScreen', () {
    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: LeaderboardScreen(),
      ));
      // Shows a circular progress indicator while loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders title bar', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: LeaderboardScreen(),
      ));
      await tester.pump();
      expect(find.text('Leaderboard'), findsOneWidget);
    });
  });
}
