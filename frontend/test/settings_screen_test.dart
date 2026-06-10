import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/settings/presentation/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows learning section', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();
      expect(find.text('LEARNING'), findsOneWidget);
    });

    testWidgets('shows account section', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();
      expect(find.text('ACCOUNT'), findsOneWidget);
    });

    testWidgets('shows about section with version', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();
      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.text('1.0.0+1'), findsOneWidget);
    });
  });
}
