import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tilezhan/core/providers/storage_provider.dart';
import 'package:tilezhan/core/providers/tile_data_provider.dart';
import 'package:tilezhan/core/router/app_router.dart';
import 'package:tilezhan/core/srs/srs_item.dart';
import 'package:tilezhan/core/srs/srs_provider.dart';
import 'package:tilezhan/core/storage/storage_service.dart';
import 'package:tilezhan/features/graveyard/domain/graveyard_provider.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_provider.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_snapshot.dart';
import 'package:tilezhan/features/nanikiru/presentation/nanikiru_screen.dart';
import 'package:tilezhan/features/training_plan/data/training_plan_store.dart';
import 'package:tilezhan/features/training_plan/domain/training_plan.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';
import 'package:tilezhan/shared/data/tile_repository.dart';
import 'package:tilezhan/shared/models/tile_model.dart';

import 'test_utils.dart';

const _reviewItemId = 'nanikiru-original-due-key';
const _snapshotPuzzleId = 'snapshot-content-id-that-must-not-win';

const _emptySuitRates = <String, double>{
  'man': 0,
  'pin': 0,
  'sou': 0,
  'wind': 0,
  'dragon': 0,
};

class _StubTileRepository extends TileRepository {
  _StubTileRepository(this.tiles);

  final List<TileModel> tiles;

  @override
  Future<List<TileModel>> loadAllTiles() async => tiles;

  @override
  TileModel? getById(String id, List<TileModel> tiles) {
    try {
      return tiles.firstWhere((tile) => tile.id == id);
    } on StateError {
      return null;
    }
  }
}

class _RecordingSrsNotifier extends SrsReviewNotifier {
  _RecordingSrsNotifier([this.initialItems = const {}]);

  final Map<String, SrsItem> initialItems;
  int recordReviewCalls = 0;
  int replaceContentCalls = 0;
  int discardCalls = 0;
  int flushCalls = 0;

  int get writeCalls =>
      recordReviewCalls + replaceContentCalls + discardCalls + flushCalls;

  @override
  Map<String, SrsItem> build() => {...initialItems};

  @override
  void recordReview(
    String itemId,
    String type,
    int quality, {
    Map<String, dynamic>? content,
  }) {
    recordReviewCalls += 1;
  }

  @override
  void replaceContentPreservingSchedule(
    SrsItem fallbackItem,
    Map<String, dynamic> content,
  ) {
    replaceContentCalls += 1;
  }

  @override
  void discardUnrecoverableItem(String itemId) {
    discardCalls += 1;
  }

  @override
  Future<void> flush() async {
    flushCalls += 1;
  }
}

class _RecordingPlanNotifier extends DailyTrainingPlanNotifier {
  int recordCalls = 0;
  int flushCalls = 0;

  int get writeCalls => recordCalls + flushCalls;

  @override
  DailyTrainingPlan? build() => null;

  @override
  bool recordAcceptedAttempt(TrainingAttemptEvent event) {
    recordCalls += 1;
    return true;
  }

  @override
  Future<void> flush() async {
    flushCalls += 1;
  }
}

class _ProbeNanikiruNotifier extends NanikiruNotifier {
  _ProbeNanikiruNotifier(TileRepository repository, Ref ref)
      : super(repository, ref);

  int initCalls = 0;
  final List<String?> requestedReviewIds = [];

  @override
  Future<void> initPuzzle({
    String? reviewItemId,
    String? preferredSkillId,
  }) async {
    initCalls += 1;
    requestedReviewIds.add(reviewItemId);
  }
}

class _NanikiruProbeBox {
  _ProbeNanikiruNotifier? notifier;
}

class _Harness {
  _Harness({
    Map<String, SrsItem> srsItems = const {},
    bool probeNanikiru = false,
  })  : srs = _RecordingSrsNotifier(srsItems),
        plan = _RecordingPlanNotifier(),
        probe = _NanikiruProbeBox(),
        tiles = _allTiles() {
    final pendingStorage = Completer<StorageService>();
    container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWith((ref) => pendingStorage.future),
        tileRepositoryProvider.overrideWithValue(_StubTileRepository(tiles)),
        tileDataProvider.overrideWith((ref) async => tiles),
        srsNotifierProvider.overrideWith(() => srs),
        dailyTrainingPlanProvider.overrideWith(() => plan),
        graveyardDueProvider.overrideWithValue(const []),
        suitErrorRatesProvider.overrideWithValue(_emptySuitRates),
        if (probeNanikiru)
          nanikiruProvider.overrideWith((ref) {
            final notifier = _ProbeNanikiruNotifier(
              _StubTileRepository(tiles),
              ref,
            );
            probe.notifier = notifier;
            return notifier;
          }),
      ],
    );
  }

  final _RecordingSrsNotifier srs;
  final _RecordingPlanNotifier plan;
  final _NanikiruProbeBox probe;
  final List<TileModel> tiles;
  late final ProviderContainer container;

  void dispose() => container.dispose();
}

List<TileModel> _allTiles() {
  final tiles = <TileModel>[];
  for (final suit in const ['m', 'p', 's']) {
    final tileSuit = switch (suit) {
      'm' => TileSuit.man,
      'p' => TileSuit.pin,
      _ => TileSuit.sou,
    };
    for (var rank = 1; rank <= 9; rank++) {
      tiles.add(makeTile('$suit$rank', tileSuit, '$suit$rank'));
    }
  }
  for (var rank = 1; rank <= 7; rank++) {
    tiles.add(makeTile(
      'z$rank',
      rank <= 4 ? TileSuit.wind : TileSuit.dragon,
      'z$rank',
    ));
  }
  return tiles;
}

SrsItem _reviewItem() {
  const hand13 = [
    'z1',
    'p9',
    'm6',
    'p8',
    'm1',
    'p7',
    'm5',
    'z1',
    'p6',
    'm4',
    'p5',
    'm3',
    'm2',
  ];
  return SrsItem(
    itemId: _reviewItemId,
    type: 'nanikiru',
    content: buildNanikiruSnapshotContent(
      puzzleId: _snapshotPuzzleId,
      hand13Ids: hand13,
      drawnTileId: 'z2',
      correctDiscardId: 'z2',
      ukeireCount: 7,
      ukeireTypes: 2,
      ukeireTileIds: const ['p4', 'p7'],
      difficulty: 900,
    ),
  );
}

Widget _localizedRouterApp(
  ProviderContainer container,
  GoRouter router,
) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

Future<void> _pumpAppRoute(
  WidgetTester tester,
  ProviderContainer container,
  String location, {
  bool settles = false,
}) async {
  appRouter.go(location);
  await tester.pumpWidget(_localizedRouterApp(container, appRouter));
  if (settles) {
    await tester.pumpAndSettle();
    return;
  }
  await tester.pump();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _detachAppRouter(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  appRouter.go('/splash');
}

void _expectNoProgressWrites(_Harness harness) {
  expect(harness.plan.writeCalls, 0);
  expect(harness.srs.writeCalls, 0);
}

void main() {
  for (final testCase in const {
    'missing': '/nanikiru?mode=review',
    'empty': '/nanikiru?mode=review&contentId=',
  }.entries) {
    testWidgets(
        'router redirects ${testCase.key} review contentId without side effects',
        (tester) async {
      final harness = _Harness(probeNanikiru: true);
      addTearDown(harness.dispose);

      await _pumpAppRoute(
        tester,
        harness.container,
        testCase.value,
        settles: true,
      );

      expect(appRouter.routeInformationProvider.value.uri.path, '/graveyard');
      expect(find.byType(NanikiruScreen), findsNothing);
      expect(harness.probe.notifier, isNull);
      _expectNoProgressWrites(harness);
      expect(tester.takeException(), isNull);

      await _detachAppRouter(tester);
    });
  }

  for (final mode in const ['daily', 'practice']) {
    testWidgets('contentId forces $mode route into exact review identity',
        (tester) async {
      final item = _reviewItem();
      final harness = _Harness(srsItems: {_reviewItemId: item});
      addTearDown(harness.dispose);
      final location = Uri(
        path: '/nanikiru',
        queryParameters: {
          'mode': mode,
          'contentId': _reviewItemId,
        },
      ).toString();

      await _pumpAppRoute(tester, harness.container, location);

      final screen = tester.widget<NanikiruScreen>(
        find.byType(NanikiruScreen),
      );
      expect(screen.mode, NanikiruMode.review);
      expect(screen.reviewItemId, _reviewItemId);
      expect(harness.container.read(nanikiruProvider).puzzleId, _reviewItemId);
      expect(
        harness.container.read(nanikiruProvider).puzzleId,
        isNot(_snapshotPuzzleId),
      );
      _expectNoProgressWrites(harness);
      expect(tester.takeException(), isNull);

      await _detachAppRouter(tester);
    });
  }

  for (final testCase in const <String, String?>{
    'null': null,
    'whitespace': '  \t ',
  }.entries) {
    testWidgets(
        'direct review widget with ${testCase.key} ID leaves without writes',
        (tester) async {
      final harness = _Harness(probeNanikiru: true);
      addTearDown(harness.dispose);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Text('Review source'),
            ),
          ),
          GoRoute(
            path: '/review',
            builder: (context, state) => NanikiruScreen(
              mode: NanikiruMode.review,
              reviewItemId: testCase.value,
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        _localizedRouterApp(harness.container, router),
      );
      router.push<void>('/review');
      await tester.pumpAndSettle();

      expect(find.text('Review source'), findsOneWidget);
      expect(find.byType(NanikiruScreen), findsNothing);
      expect(router.canPop(), isFalse);
      expect(harness.probe.notifier, isNotNull);
      expect(harness.probe.notifier!.initCalls, 0);
      expect(harness.probe.notifier!.requestedReviewIds, isEmpty);
      _expectNoProgressWrites(harness);
      expect(tester.takeException(), isNull);
    });
  }
}
