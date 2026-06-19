import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_state.dart';
import 'package:tilezhan/features/nanikiru/presentation/nanikiru_feedback_panel.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';

Widget _wrap(NanikiruFeedbackPanel panel) {
  return ProviderScope(child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: Scaffold(body: SingleChildScrollView(child: SizedBox(height: 900, child: panel))),
  ));
}

void main() {
  final panelSlide = AlwaysStoppedAnimation<Offset>(Offset.zero);

  group('NanikiruFeedbackPanel', () {
    testWidgets('shows PERFECT header and action buttons', (tester) async {
      const state = NaniKiruState(
        isPerfect: true,
        phase: NaniKiruPhase.feedback,
        correctDiscardId: 'm1',
        ukeireCount: 12,
        ukeireTypes: 3,
        allDiscardUkeire: {'m1': 12},
      );

      await tester.pumpWidget(_wrap(NanikiruFeedbackPanel(
        state: state,
        panelSlide: panelSlide,
        onNextPuzzle: () {},
        onReviewAgain: () {},
      )));

      expect(find.text('🎯 PERFECT!'), findsOneWidget);
      expect(find.text('Next Puzzle'), findsOneWidget);
      expect(find.text('Review Again'), findsOneWidget);
    });

    testWidgets('shows BLUNDER header and comparison bar on wrong answer', (tester) async {
      const state = NaniKiruState(
        isPerfect: false,
        phase: NaniKiruPhase.feedback,
        selectedTileId: 'z1',
        correctDiscardId: 'm5',
        ukeireCount: 15,
        ukeireTypes: 5,
        allDiscardUkeire: {'z1': 4, 'm5': 15},
        allDiscardUkeireTiles: {'m5': ['m3', 'm4', 'm6']},
      );

      await tester.pumpWidget(_wrap(NanikiruFeedbackPanel(
        state: state,
        panelSlide: panelSlide,
        onNextPuzzle: () {},
        onReviewAgain: () {},
      )));

      expect(find.text('💥 BLUNDER!'), findsOneWidget);
      expect(find.text('Acceptance Comparison'), findsOneWidget);
      // Both action buttons present
      expect(find.text('Next Puzzle'), findsOneWidget);
      expect(find.text('Review Again'), findsOneWidget);
    });

    testWidgets('handles null ukeire data gracefully', (tester) async {
      const state = NaniKiruState(
        isPerfect: true,
        phase: NaniKiruPhase.feedback,
        correctDiscardId: 'm1',
        // No ukeire data at all
      );

      await tester.pumpWidget(_wrap(NanikiruFeedbackPanel(
        state: state,
        panelSlide: panelSlide,
        onNextPuzzle: () {},
        onReviewAgain: () {},
      )));

      // Should still render without crashing
      expect(find.text('🎯 PERFECT!'), findsOneWidget);
    });
  });
}
