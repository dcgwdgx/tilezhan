import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/profile/presentation/profile_screen.dart';

void main() {
  group('ProfileScreen', () {
    testWidgets('renders profile header', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ProfileScreen())),
      );
      await tester.pump();
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('shows stat labels', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ProfileScreen())),
      );
      await tester.pump(const Duration(milliseconds: 100));
      // Stats may show defaults since storage isn't available
      expect(find.text('ELO'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
    });

    testWidgets('shows account section', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ProfileScreen())),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('ACCOUNT'), findsOneWidget);
    });
  });
}
