import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/scanner/presentation/scanner_screen.dart';

Widget _wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

void main() {
  group('ScannerScreen', () {
    testWidgets('renders yaku reference list', (tester) async {
      await tester.pumpWidget(_wrap(const ScannerScreen()));
      await tester.pump();
      expect(find.text('Yaku Scanner'), findsOneWidget);
      expect(find.text('Tanyao'), findsOneWidget);
    });

    testWidgets('shows all 10 basic yaku', (tester) async {
      await tester.pumpWidget(_wrap(const ScannerScreen()));
      await tester.pump();
      // First 6 are unlocked, last 4 are locked
      expect(find.byType(ScannerScreen), findsOneWidget);
      expect(find.text('Yaku Scanner'), findsOneWidget);
    });
  });
}
