import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/scanner/presentation/scanner_screen.dart';

void main() {
  group('ScannerScreen', () {
    testWidgets('renders yaku reference list', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ScannerScreen()));
      await tester.pump();
      expect(find.text('Yaku Scanner'), findsOneWidget);
      expect(find.text('Tanyao'), findsOneWidget);
      expect(find.text('Pinfu'), findsOneWidget);
    });

    testWidgets('shows locked indicators', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ScannerScreen()));
      await tester.pump();
      expect(find.text('🔒'), findsWidgets);
    });

    testWidgets('shows unlocked yaku', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ScannerScreen()));
      await tester.pump();
      expect(find.text('All Simples'), findsOneWidget);
    });
  });
}
