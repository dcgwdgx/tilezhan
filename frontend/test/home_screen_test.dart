import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/home/presentation/home_screen.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeScreen())),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('shows Quick Access grid', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeScreen())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Flashcards'), findsOneWidget);
      expect(find.text('Nani-Kiru'), findsOneWidget);
      expect(find.text('Scanner'), findsOneWidget);
    });

    testWidgets('shows bottom tab bar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeScreen())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Tiles'), findsOneWidget);
    });

    testWidgets('shows quest card', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeScreen())),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('DAILY QUEST'), findsOneWidget);
    });
  });
}
