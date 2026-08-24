import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/providers/tile_data_provider.dart';
import 'package:tilezhan/features/hand_analyzer/data/hand_analysis_history_store.dart';
import 'package:tilezhan/features/hand_analyzer/presentation/hand_analyzer_screen.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';
import 'package:tilezhan/shared/models/tile_model.dart';

const _thirteenTileHand = [
  'm1',
  'm2',
  'm3',
  'm4',
  'm5',
  'm6',
  's1',
  's2',
  's3',
  'p5',
  'p5',
  's7',
  's7',
];

const _fourteenTileHand = [
  'm1',
  'm2',
  'm3',
  'm4',
  'm5',
  'm6',
  'p5',
  'p6',
  'p7',
  'p8',
  'p9',
  'z1',
  'z1',
  'z2',
];

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

Future<void> _pumpScreen(
  WidgetTester tester, {
  required List<String> initialTileIds,
  required InMemoryHandAnalysisHistoryStore historyStore,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  await tester.pumpWidget(_app(
    locale: locale,
    textScale: textScale,
    child: HandAnalyzerScreen(
      initialTileIds: initialTileIds,
      historyStore: historyStore,
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _analyze(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('hand-analyzer-analyze'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('13 tiles show exact shanten, shape breakdown, and improving draws',
      (tester) async {
    await _pumpScreen(
      tester,
      initialTileIds: _thirteenTileHand,
      historyStore: InMemoryHandAnalysisHistoryStore(),
    );

    await _analyze(tester);

    expect(
      find.byKey(const ValueKey('hand-analyzer-engine-result')),
      findsOneWidget,
    );
    expect(find.text('Current shanten'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    expect(find.text('Seven pairs'), findsOneWidget);
    expect(find.text('Thirteen orphans'), findsOneWidget);
    expect(find.text('2 types · 4 tiles'), findsOneWidget);
    expect(find.text('Tenpai'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('14 tiles show every engine-ranked discard and the best candidate',
      (tester) async {
    await _pumpScreen(
      tester,
      initialTileIds: _fourteenTileHand,
      historyStore: InMemoryHandAnalysisHistoryStore(),
    );

    await _analyze(tester);

    expect(
      find.byKey(const ValueKey('hand-analyzer-candidate-z2')),
      findsOneWidget,
    );
    expect(find.text('BEST'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    for (final tileId in _fourteenTileHand.toSet()) {
      expect(
        find.byKey(ValueKey('hand-analyzer-candidate-$tileId')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving, reopening, and deleting a hand use input-only history',
      (tester) async {
    final store = InMemoryHandAnalysisHistoryStore();
    await _pumpScreen(
      tester,
      initialTileIds: _thirteenTileHand,
      historyStore: store,
    );
    await _analyze(tester);

    final save = find.byKey(const ValueKey('hand-analyzer-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(store.read().records, hasLength(1));
    expect(find.text('Saved to recent analyses.'), findsOneWidget);

    final clear = find.byKey(const ValueKey('hand-analyzer-clear'));
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hand-analyzer-engine-result')),
      findsNothing,
    );

    final open = find.text('Open');
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hand-analyzer-engine-result')),
      findsOneWidget,
    );

    final delete = find.text('Delete');
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(store.read().records, isEmpty);
    expect(find.text('Saved hands will appear here.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a fifth copy is rejected with localized feedback',
      (tester) async {
    await _pumpScreen(
      tester,
      initialTileIds: const ['m1', 'm1', 'm1', 'm1'],
      historyStore: InMemoryHandAnalysisHistoryStore(),
    );

    final picker = find.byKey(const ValueKey('hand-analyzer-picker-m1'));
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pump();

    expect(
      find.text('A tile can appear at most four times.'),
      findsOneWidget,
    );
  });

  testWidgets('small screen and large German text remain scrollable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpScreen(
      tester,
      initialTileIds: _fourteenTileHand,
      historyStore: InMemoryHandAnalysisHistoryStore(),
      locale: const Locale('de'),
      textScale: 1.8,
    );
    await _analyze(tester);

    expect(find.text('Formen im Vergleich'), findsOneWidget);
    final save = find.byKey(const ValueKey('hand-analyzer-save'));
    await tester.ensureVisible(save);
    expect(save, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
