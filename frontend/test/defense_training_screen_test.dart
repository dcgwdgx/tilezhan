import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/providers/tile_data_provider.dart';
import 'package:tilezhan/features/defense_trainer/domain/defense_training_state.dart';
import 'package:tilezhan/features/defense_trainer/presentation/defense_training_screen.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';
import 'package:tilezhan/shared/models/tile_model.dart';

List<TileModel> _tiles() {
  const mnemonic = MnemonicData(
    emoji: '',
    name: '',
    slogan: '',
    desc: '',
    chinese: '',
    anchor: '',
  );
  return [
    for (final suit in const ['m', 'p', 's'])
      for (var rank = 1; rank <= 9; rank++)
        TileModel(
          id: '$suit$rank',
          suit: switch (suit) {
            'm' => TileSuit.man,
            'p' => TileSuit.pin,
            _ => TileSuit.sou,
          },
          character: '$rank',
          seal: '',
          value: rank,
          label: '$suit$rank',
          mnemonic: mnemonic,
          confusedWith: const [],
        ),
    for (var rank = 1; rank <= 7; rank++)
      TileModel(
        id: 'z$rank',
        suit: rank <= 4 ? TileSuit.wind : TileSuit.dragon,
        character: '$rank',
        seal: '',
        value: rank,
        label: 'z$rank',
        mnemonic: mnemonic,
        confusedWith: const [],
      ),
  ];
}

Widget _app({
  required Widget child,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) {
  return ProviderScope(
    overrides: [
      tileDataProvider.overrideWith((ref) async => _tiles()),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('de')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child,
        ),
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  String? reviewQuestionId,
  int seed = 17,
  Locale locale = const Locale('en'),
  double textScale = 1,
  DefenseAnswerRecorded? onAnswerRecorded,
  VoidCallback? onCancel,
  VoidCallback? onDone,
}) async {
  await tester.pumpWidget(_app(
    locale: locale,
    textScale: textScale,
    child: DefenseTrainingScreen(
      reviewQuestionId: reviewQuestionId,
      seed: seed,
      onAnswerRecorded: onAnswerRecorded,
      onCancel: onCancel,
      onDone: onDone,
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _ensureFinderVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      220,
      maxScrolls: 30,
    );
  } else {
    await tester.ensureVisible(finder);
  }
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await _ensureFinderVisible(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('normal mode starts with the localized ten-question intro',
      (tester) async {
    await _pump(tester);

    expect(
      find.byKey(const ValueKey('defense-intro-scroll')),
      findsOneWidget,
    );
    expect(find.text('10-question session'), findsOneWidget);
    expect(find.text('Genbutsu'), findsOneWidget);
    expect(find.text('Visible honors'), findsOneWidget);

    await _tapVisible(tester, find.byKey(const ValueKey('defense-start')));

    expect(
      find.byKey(const ValueKey('defense-question-scroll')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('defense-choices')), findsOneWidget);
    for (final choiceId in const ['a', 'b', 'c', 'd']) {
      expect(
        find.byKey(ValueKey('defense-choice-$choiceId')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('review opens one exact question with all public information',
      (tester) async {
    await _pump(
      tester,
      reviewQuestionId: 'defense.genbutsu.002.v1',
      seed: 3,
    );

    expect(
      find.byKey(const ValueKey('defense-intro-scroll')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('defense-target-river')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('defense-other-river-east')),
      findsOneWidget,
    );
    for (final choiceId in const ['a', 'b', 'c', 'd']) {
      expect(
        find.byKey(ValueKey('defense-choice-$choiceId')),
        findsOneWidget,
      );
    }

    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Choose 6 of circles'), findsOneWidget);
    final choiceSize = tester.getSize(
      find.byKey(const ValueKey('defense-choice-b')),
    );
    expect(choiceSize.width, greaterThanOrEqualTo(48));
    expect(choiceSize.height, greaterThanOrEqualTo(48));
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('honor tiles use localized names in accessibility labels',
      (tester) async {
    await _pump(
      tester,
      reviewQuestionId: 'defense.honor.001.v1',
      seed: 5,
    );

    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Choose Red Dragon'), findsOneWidget);
    final visibleHonorSemantics = tester.widget<Semantics>(
      find.byKey(const ValueKey('defense-visible-z5')),
    );
    expect(
      visibleHonorSemantics.properties.label,
      'Red Dragon, 3 visible copies',
    );
    expect(find.bySemanticsLabel(RegExp(r'\bz[1-7]\b')), findsNothing);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown review ID shows an exit-able error without fallback',
      (tester) async {
    var cancelCalls = 0;
    await _pump(
      tester,
      reviewQuestionId: 'defense.removed.999.v1',
      onCancel: () => cancelCalls += 1,
    );

    expect(
      find.byKey(const ValueKey('defense-load-error-scroll')),
      findsOneWidget,
    );
    expect(
        find.text('The defense lesson could not be loaded.'), findsOneWidget);
    expect(find.byKey(const ValueKey('defense-retry')), findsOneWidget);
    expect(find.byKey(const ValueKey('defense-error-done')), findsOneWidget);
    expect(find.byKey(const ValueKey('defense-question-scroll')), findsNothing);
    expect(find.byKey(const ValueKey('defense-intro-scroll')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('defense-error-done')));
    await tester.pump();
    expect(cancelCalls, 1);
  });

  testWidgets('additional visible copies are shown with semantic counts',
      (tester) async {
    await _pump(
      tester,
      reviewQuestionId: 'defense.kabe.001.v1',
      seed: 4,
    );

    expect(
      find.byKey(const ValueKey('defense-additional-visible')),
      findsOneWidget,
    );
    expect(find.text('4 visible'), findsOneWidget);
    expect(find.text('3 visible'), findsOneWidget);

    final semantics = tester.widget<Semantics>(
      find.byKey(const ValueKey('defense-visible-m2')),
    );
    expect(semantics.properties.label, '2 of characters, 4 visible copies');
  });

  testWidgets('one tap records once and shows honest target-specific feedback',
      (tester) async {
    final recorded = <DefenseTrainingAnswer>[];
    await _pump(
      tester,
      reviewQuestionId: 'defense.genbutsu.002.v1',
      seed: 3,
      onAnswerRecorded: recorded.add,
    );

    final best = find.byKey(const ValueKey('defense-choice-b'));
    await _tapVisible(tester, best);

    expect(recorded, hasLength(1));
    expect(find.text('Good decision'), findsOneWidget);
    expect(find.text('Safe against target · genbutsu'), findsOneWidget);
    expect(
      find.textContaining('it says nothing about the other players'),
      findsOneWidget,
    );

    await tester.tap(best, warnIfMissed: false);
    await tester.pump();
    expect(recorded, hasLength(1));

    await _tapVisible(tester, find.byKey(const ValueKey('defense-next')));
    expect(
      find.byKey(const ValueKey('defense-summary-scroll')),
      findsOneWidget,
    );
    expect(find.text('1 of 1 decisions matched the lesson.'), findsOneWidget);
  });

  testWidgets('incorrect relative choice shows selected and recommended facts',
      (tester) async {
    await _pump(
      tester,
      reviewQuestionId: 'defense.kabe.001.v1',
      seed: 4,
    );

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('defense-choice-b')),
    );

    expect(find.text('Review this choice'), findsOneWidget);
    expect(find.text('Your choice'), findsOneWidget);
    expect(find.text('Recommended choice'), findsOneWidget);
    expect(
      find.text('Lower-risk clue · not guaranteed safe'),
      findsOneWidget,
    );
    expect(
      find.text('Strongly reduced risk · not guaranteed safe'),
      findsOneWidget,
    );
    expect(
        find.textContaining('fourth may still be concealed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ten answered questions end with all five topic summaries',
      (tester) async {
    const seed = 29;
    var expected = DefenseTrainingState.standard(seed: seed);
    await _pump(tester, seed: seed);
    await _tapVisible(tester, find.byKey(const ValueKey('defense-start')));
    expected = expected.begin();

    while (expected.phase != DefenseTrainingPhase.completed) {
      final bestChoiceId = expected.currentQuestion!.bestChoiceId;
      await _tapVisible(
        tester,
        find.byKey(ValueKey('defense-choice-$bestChoiceId')),
      );
      expected = expected.submit(bestChoiceId);
      await _tapVisible(tester, find.byKey(const ValueKey('defense-next')));
      expected = expected.next();
    }

    expect(
      find.byKey(const ValueKey('defense-summary-scroll')),
      findsOneWidget,
    );
    expect(find.text('10 of 10 decisions matched the lesson.'), findsOneWidget);
    for (final topic in const [
      'genbutsu',
      'suji',
      'kabe',
      'honorVisibility',
      'combinedEvidence',
    ]) {
      expect(
        find.byKey(ValueKey('defense-summary-topic-$topic')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('320x568 German at 1.8x remains scrollable through feedback',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(
      tester,
      reviewQuestionId: 'defense.combined.001.v1',
      seed: 8,
      locale: const Locale('de'),
      textScale: 1.8,
    );

    final choice = find.byKey(const ValueKey('defense-choice-d'));
    await _ensureFinderVisible(tester, choice);
    expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('1 Kreise wählen'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'\b[mpsz][1-9]\b')), findsNothing);
    semantics.dispose();
    await tester.tap(choice);
    await tester.pumpAndSettle();

    final next = find.byKey(const ValueKey('defense-next'));
    await _ensureFinderVisible(tester, next);
    expect(next, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
