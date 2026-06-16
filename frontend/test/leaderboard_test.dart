import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/leaderboard/presentation/leaderboard_screen.dart';

void main() {
  group('LeaderboardScreen', () {
    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LeaderboardScreen()));
      // Shows a circular progress indicator while loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders title bar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LeaderboardScreen()));
      await tester.pump();
      expect(find.text('Leaderboard'), findsOneWidget);
    });
  });
}
