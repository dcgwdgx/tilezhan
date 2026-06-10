import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/graveyard/presentation/graveyard_screen.dart';

void main() {
  group('GraveyardScreen', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: GraveyardScreen())),
      );
      await tester.pump();
      expect(find.text('Tile Graveyard'), findsOneWidget);
    });

    testWidgets('shows SRS review header', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: GraveyardScreen())),
      );
      await tester.pump();
      expect(find.text('👻 SRS Review'), findsOneWidget);
    });

    testWidgets('shows weakness radar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: GraveyardScreen())),
      );
      await tester.pump();
      expect(find.text('Weakness Radar'), findsOneWidget);
    });

    testWidgets('shows review button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: GraveyardScreen())),
      );
      await tester.pump();
      expect(find.textContaining('Review All'), findsOneWidget);
    });
  });
}
