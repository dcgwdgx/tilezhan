import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_state.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_teaching_analysis.dart';
import 'package:tilezhan/features/nanikiru/presentation/nanikiru_feedback_panel.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';

const _defaultSize = Size(360, 640);

NanikiruCandidateAnalysis _candidate({
  required String discardId,
  required int rank,
  required int shantenAfter,
  required int ukeireCount,
  required int shantenDifferenceFromBest,
  required int? ukeireLossFromBest,
  required bool isOptimal,
  List<String> ukeireTileIds = const ['p1', 'p4'],
  Set<NanikiruTeachingTag> tags = const {
    NanikiruTeachingTag.generalTileEfficiency,
  },
}) {
  return NanikiruCandidateAnalysis(
    discardId: discardId,
    rank: rank,
    shantenAfter: shantenAfter,
    ukeireTileIds: ukeireTileIds,
    ukeireCount: ukeireCount,
    shantenDifferenceFromBest: shantenDifferenceFromBest,
    ukeireLossFromBest: ukeireLossFromBest,
    isOptimal: isOptimal,
    tags: tags,
  );
}

NanikiruTeachingAnalysis _analysis({
  required List<NanikiruCandidateAnalysis> topCandidates,
  required List<NanikiruCandidateAnalysis> allCandidates,
  String? selectedDiscardId,
}) {
  final byDiscard = {
    for (final candidate in allCandidates) candidate.discardId: candidate,
  };
  return NanikiruTeachingAnalysis(
    topCandidates: topCandidates,
    selectedCandidate:
        selectedDiscardId == null ? null : byDiscard[selectedDiscardId],
    byDiscard: byDiscard,
    evaluatedCandidateCount: allCandidates.length,
  );
}

NanikiruTeachingAnalysis _rankedAnalysis({
  String? selectedDiscardId,
  bool dense = false,
}) {
  final candidates = [
    _candidate(
      discardId: 'm1',
      rank: 1,
      shantenAfter: 0,
      ukeireCount: 12,
      shantenDifferenceFromBest: 0,
      ukeireLossFromBest: 0,
      isOptimal: true,
      ukeireTileIds: dense
          ? const [
              'm1',
              'm9',
              'p1',
              'p9',
              's1',
              's9',
              'z1',
              'z2',
              'z3',
              'z4',
              'z5',
              'z6',
              'z7',
            ]
          : const ['p1', 'p4'],
      tags: dense
          ? const {
              NanikiruTeachingTag.isolatedTileHandling,
              NanikiruTeachingTag.taatsuOverload,
              NanikiruTeachingTag.pairProtection,
              NanikiruTeachingTag.chiitoitsuCompetition,
              NanikiruTeachingTag.kokushiTendency,
            }
          : const {NanikiruTeachingTag.generalTileEfficiency},
    ),
    _candidate(
      discardId: 'm2',
      rank: 1,
      shantenAfter: 0,
      ukeireCount: 12,
      shantenDifferenceFromBest: 0,
      ukeireLossFromBest: 0,
      isOptimal: true,
    ),
    _candidate(
      discardId: 'm3',
      rank: 3,
      shantenAfter: 0,
      ukeireCount: 9,
      shantenDifferenceFromBest: 0,
      ukeireLossFromBest: 3,
      isOptimal: false,
    ),
    _candidate(
      discardId: 'm4',
      rank: 4,
      shantenAfter: 1,
      ukeireCount: 20,
      shantenDifferenceFromBest: 1,
      ukeireLossFromBest: null,
      isOptimal: false,
    ),
  ];
  return _analysis(
    topCandidates: candidates.take(3).toList(growable: false),
    allCandidates: candidates,
    selectedDiscardId: selectedDiscardId,
  );
}

NanikiruTeachingAnalysis _singleTagAnalysis(NanikiruTeachingTag tag) {
  final candidates = [
    _candidate(
      discardId: 's1',
      rank: 1,
      shantenAfter: 0,
      ukeireCount: 8,
      shantenDifferenceFromBest: 0,
      ukeireLossFromBest: 0,
      isOptimal: true,
      tags: {tag},
    ),
    _candidate(
      discardId: 's2',
      rank: 2,
      shantenAfter: 0,
      ukeireCount: 6,
      shantenDifferenceFromBest: 0,
      ukeireLossFromBest: 2,
      isOptimal: false,
    ),
  ];
  return _analysis(
    topCandidates: candidates,
    allCandidates: candidates,
    selectedDiscardId: 's1',
  );
}

NaniKiruState _feedbackState({
  required NaniKiruOutcome outcome,
  required NanikiruTeachingAnalysis analysis,
  String? selectedTileId,
}) {
  return NaniKiruState(
    phase: NaniKiruPhase.feedback,
    outcome: outcome,
    isPerfect: outcome == NaniKiruOutcome.perfect,
    selectedTileId: selectedTileId,
    correctDiscardId: analysis.bestCandidate.discardId,
    teachingAnalysis: analysis,
  );
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required NaniKiruState state,
  Locale locale = const Locale('en'),
  Size size = _defaultSize,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        );
      },
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: NanikiruFeedbackPanel(
                state: state,
                panelSlide: const AlwaysStoppedAnimation<Offset>(Offset.zero),
                onNextPuzzle: () {},
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppLocalizations _l10n(WidgetTester tester) {
  return AppLocalizations.of(
    tester.element(find.byType(NanikiruFeedbackPanel)),
  )!;
}

String _outcomeTitle(AppLocalizations l10n, NaniKiruOutcome outcome) {
  return switch (outcome) {
    NaniKiruOutcome.perfect => l10n.nanikiruPerfect,
    NaniKiruOutcome.incorrect => l10n.nanikiruNotOptimalTitle,
    NaniKiruOutcome.skipped => l10n.nanikiruSkippedTitle,
    NaniKiruOutcome.timedOut => l10n.nanikiruTimedOutTitle,
    NaniKiruOutcome.unanswered => l10n.nanikiruNotOptimalTitle,
  };
}

String _skillLabel(AppLocalizations l10n, NanikiruTeachingTag tag) {
  return switch (tag) {
    NanikiruTeachingTag.isolatedTileHandling => l10n.nanikiruSkillIsolatedTile,
    NanikiruTeachingTag.taatsuOverload => l10n.nanikiruSkillTaatsuOverload,
    NanikiruTeachingTag.pairProtection => l10n.nanikiruSkillPairProtection,
    NanikiruTeachingTag.chiitoitsuCompetition => l10n.nanikiruSkillChiitoitsu,
    NanikiruTeachingTag.kokushiTendency => l10n.nanikiruSkillKokushi,
    NanikiruTeachingTag.generalTileEfficiency =>
      l10n.nanikiruSkillGeneralEfficiency,
  };
}

List<String> _decisionImpactTexts(WidgetTester tester) {
  return tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(const Key('nanikiru-decision-impact')),
          matching: find.byType(Text),
        ),
      )
      .map((widget) => widget.data)
      .whereType<String>()
      .toList(growable: false);
}

ScrollableState _feedbackScrollable(WidgetTester tester) {
  final finder = find.descendant(
    of: find.byKey(const Key('nanikiru-feedback-scroll')),
    matching: find.byType(Scrollable),
  );
  expect(finder, findsOneWidget);
  return tester.state<ScrollableState>(finder);
}

void _expectNextButtonVisible(WidgetTester tester, Size viewport) {
  final finder = find.byKey(const Key('nanikiru-next-button'));
  expect(finder, findsOneWidget);
  final rect = tester.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(viewport.width));
  expect(rect.bottom, lessThanOrEqualTo(viewport.height));
}

void main() {
  group('NanikiruFeedbackPanel outcomes', () {
    for (final outcome in const [
      NaniKiruOutcome.perfect,
      NaniKiruOutcome.incorrect,
      NaniKiruOutcome.skipped,
      NaniKiruOutcome.timedOut,
    ]) {
      testWidgets('shows localized ${outcome.name} title', (tester) async {
        final selectedId = switch (outcome) {
          NaniKiruOutcome.perfect => 'm1',
          NaniKiruOutcome.incorrect => 'm3',
          NaniKiruOutcome.skipped || NaniKiruOutcome.timedOut => null,
          NaniKiruOutcome.unanswered => null,
        };
        final analysis = _rankedAnalysis(selectedDiscardId: selectedId);

        await _pumpPanel(
          tester,
          state: _feedbackState(
            outcome: outcome,
            analysis: analysis,
            selectedTileId: selectedId,
          ),
        );

        final l10n = _l10n(tester);
        expect(find.text(_outcomeTitle(l10n, outcome)), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('timeout reports the pending choice when one exists',
        (tester) async {
      final analysis = _rankedAnalysis(selectedDiscardId: 'm4');

      await _pumpPanel(
        tester,
        state: _feedbackState(
          outcome: NaniKiruOutcome.timedOut,
          analysis: analysis,
          selectedTileId: 'm4',
        ),
      );

      final l10n = _l10n(tester);
      expect(find.text(l10n.nanikiruTimedOutTitle), findsOneWidget);
      expect(find.text(l10n.nanikiruTimeoutChoice('m4')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('timeout without a pending choice reports no selection',
        (tester) async {
      final analysis = _rankedAnalysis();

      await _pumpPanel(
        tester,
        state: _feedbackState(
          outcome: NaniKiruOutcome.timedOut,
          analysis: analysis,
        ),
      );

      final l10n = _l10n(tester);
      expect(find.text(l10n.nanikiruTimedOutTitle), findsOneWidget);
      expect(find.text(l10n.nanikiruNoSelection), findsOneWidget);
      for (final tileId in analysis.byDiscard.keys) {
        expect(
          find.text(l10n.nanikiruTimeoutChoice(tileId)),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('candidate teaching facts', () {
    testWidgets('renders competition ranks 1, 1, 3 for tied candidates',
        (tester) async {
      final analysis = _rankedAnalysis(selectedDiscardId: 'm3');

      await _pumpPanel(
        tester,
        state: _feedbackState(
          outcome: NaniKiruOutcome.incorrect,
          analysis: analysis,
          selectedTileId: 'm3',
        ),
      );

      final l10n = _l10n(tester);
      expect(find.text(l10n.nanikiruRankLabel(1)), findsNWidgets(2));
      expect(find.text(l10n.nanikiruRankLabel(3)), findsOneWidget);
      expect(find.text(l10n.nanikiruRankLabel(2)), findsNothing);
    });

    testWidgets('keeps a selected candidate visible outside the top three',
        (tester) async {
      final analysis = _rankedAnalysis(selectedDiscardId: 'm4');

      await _pumpPanel(
        tester,
        state: _feedbackState(
          outcome: NaniKiruOutcome.incorrect,
          analysis: analysis,
          selectedTileId: 'm4',
        ),
      );

      final l10n = _l10n(tester);
      expect(
        find.byKey(const ValueKey('nanikiru-candidate-m4')),
        findsOneWidget,
      );
      expect(find.text(l10n.nanikiruRankLabel(4)), findsOneWidget);
      expect(find.text(l10n.nanikiruSelectedBadge), findsOneWidget);
    });

    testWidgets('same-shanten choice displays only ukeire loss',
        (tester) async {
      final analysis = _rankedAnalysis(selectedDiscardId: 'm3');

      await _pumpPanel(
        tester,
        state: _feedbackState(
          outcome: NaniKiruOutcome.incorrect,
          analysis: analysis,
          selectedTileId: 'm3',
        ),
      );

      final l10n = _l10n(tester);
      expect(
        _decisionImpactTexts(tester),
        orderedEquals([
          l10n.nanikiruDecisionLossTitle,
          l10n.nanikiruUkeireLoss(3),
        ]),
      );
    });

    testWidgets('worse-shanten choice displays only shanten loss',
        (tester) async {
      final analysis = _rankedAnalysis(selectedDiscardId: 'm4');

      await _pumpPanel(
        tester,
        state: _feedbackState(
          outcome: NaniKiruOutcome.incorrect,
          analysis: analysis,
          selectedTileId: 'm4',
        ),
      );

      final l10n = _l10n(tester);
      expect(
        _decisionImpactTexts(tester),
        orderedEquals([
          l10n.nanikiruDecisionLossTitle,
          l10n.nanikiruShantenLoss(1),
        ]),
      );
    });

    for (final tag in NanikiruTeachingTag.values) {
      testWidgets('localizes ${tag.name} skill tag', (tester) async {
        final analysis = _singleTagAnalysis(tag);

        await _pumpPanel(
          tester,
          state: _feedbackState(
            outcome: NaniKiruOutcome.perfect,
            analysis: analysis,
            selectedTileId: 's1',
          ),
        );

        final l10n = _l10n(tester);
        expect(
          find.descendant(
            of: find.byKey(const Key('nanikiru-skill-tags')),
            matching: find.text(_skillLabel(l10n, tag)),
          ),
          findsOneWidget,
        );
      });
    }
  });

  group('localization smoke', () {
    for (final locale in const [Locale('en'), Locale('fr'), Locale('de')]) {
      testWidgets('renders ${locale.languageCode}', (tester) async {
        final analysis = _rankedAnalysis(selectedDiscardId: 'm1');

        await _pumpPanel(
          tester,
          locale: locale,
          state: _feedbackState(
            outcome: NaniKiruOutcome.perfect,
            analysis: analysis,
            selectedTileId: 'm1',
          ),
        );

        final l10n = _l10n(tester);
        expect(find.text(l10n.nanikiruPerfect), findsOneWidget);
        expect(find.text(l10n.nanikiruNextPuzzle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('compact production layout', () {
    for (final size in const [Size(320, 568), Size(360, 640)]) {
      testWidgets(
        '${size.width.toInt()}x${size.height.toInt()} keeps footer visible '
        'and body scrollable',
        (tester) async {
          final analysis = _rankedAnalysis(
            selectedDiscardId: 'm4',
            dense: true,
          );

          await _pumpPanel(
            tester,
            size: size,
            state: _feedbackState(
              outcome: NaniKiruOutcome.timedOut,
              analysis: analysis,
              selectedTileId: 'm4',
            ),
          );

          expect(tester.takeException(), isNull);
          _expectNextButtonVisible(tester, size);
          final scrollable = _feedbackScrollable(tester);
          expect(scrollable.position.maxScrollExtent, greaterThan(0));
          final footerBefore = tester.getRect(
            find.byKey(const Key('nanikiru-next-button')),
          );

          await tester.drag(
            find.byKey(const Key('nanikiru-feedback-scroll')),
            const Offset(0, -180),
          );
          await tester.pumpAndSettle();

          expect(scrollable.position.pixels, greaterThan(0));
          _expectNextButtonVisible(tester, size);
          final footerAfter = tester.getRect(
            find.byKey(const Key('nanikiru-next-button')),
          );
          expect(footerAfter.top, closeTo(footerBefore.top, 0.01));
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('large text scale remains scrollable without overflow',
        (tester) async {
      const size = Size(320, 568);
      final analysis = _rankedAnalysis(
        selectedDiscardId: 'm4',
        dense: true,
      );

      await _pumpPanel(
        tester,
        locale: const Locale('fr'),
        size: size,
        textScale: 1.8,
        state: _feedbackState(
          outcome: NaniKiruOutcome.timedOut,
          analysis: analysis,
          selectedTileId: 'm4',
        ),
      );

      final l10n = _l10n(tester);
      expect(find.text(l10n.nanikiruTimedOutTitle), findsOneWidget);
      _expectNextButtonVisible(tester, size);
      expect(
        _feedbackScrollable(tester).position.maxScrollExtent,
        greaterThan(0),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
