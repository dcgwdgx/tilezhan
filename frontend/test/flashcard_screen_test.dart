import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tilezhan/core/analytics/analytics_service.dart';
import 'package:tilezhan/core/commerce/commerce_availability.dart';
import 'package:tilezhan/core/hearts/heart_provider.dart';
import 'package:tilezhan/core/hearts/heart_service.dart';
import 'package:tilezhan/core/providers/player_name_provider.dart';
import 'package:tilezhan/core/providers/storage_provider.dart';
import 'package:tilezhan/core/providers/tile_data_provider.dart';
import 'package:tilezhan/core/srs/srs_item.dart';
import 'package:tilezhan/core/srs/srs_provider.dart';
import 'package:tilezhan/core/storage/storage_service.dart';
import 'package:tilezhan/core/utils/audio_service.dart';
import 'package:tilezhan/features/flashcard/domain/flashcard_provider.dart';
import 'package:tilezhan/features/flashcard/presentation/flashcard_screen.dart';
import 'package:tilezhan/features/training_plan/data/training_plan_store.dart';
import 'package:tilezhan/features/training_plan/domain/training_plan.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';
import 'package:tilezhan/shared/data/tile_repository.dart';
import 'package:tilezhan/shared/models/tile_model.dart';

class _TileRepo extends TileRepository {
  _TileRepo(this.tiles);

  final List<TileModel> tiles;

  @override
  Future<List<TileModel>> loadAllTiles() async => tiles;

  @override
  TileModel? getById(String id, List<TileModel> allTiles) {
    for (final tile in allTiles) {
      if (tile.id == id) return tile;
    }
    return null;
  }

  @override
  List<TileModel> getDistractors(
    TileModel correct,
    List<TileModel> allTiles,
    int count,
  ) {
    return allTiles.where((tile) => tile.id != correct.id).take(count).toList();
  }
}

class _FakeHeartService extends HeartService {
  @override
  bool get hasHearts => true;

  @override
  int get hearts => 10;

  @override
  Future<void> init() async {}

  @override
  void recordCorrect() {}

  @override
  void recordWrong() {}

  @override
  bool consume() => false;
}

class _FlushControl {
  final List<Future<void> Function()> _responses = [];
  int calls = 0;

  void blockNext(Completer<void> completer) {
    _responses.add(() => completer.future);
  }

  void failNext(Object error) {
    _responses.add(() => Future<void>.error(error));
  }

  Future<void> flush() async {
    calls++;
    if (_responses.isEmpty) return;
    await _responses.removeAt(0)();
  }
}

class _CountingSrsNotifier extends SrsReviewNotifier {
  _CountingSrsNotifier(this.flushControl);

  final _FlushControl flushControl;
  int recordCalls = 0;

  @override
  Map<String, SrsItem> build() => {};

  @override
  void recordReview(
    String itemId,
    String type,
    int quality, {
    Map<String, dynamic>? content,
  }) {
    recordCalls++;
    super.recordReview(
      itemId,
      type,
      quality,
      content: content,
    );
  }

  @override
  Future<void> flush() => flushControl.flush();
}

class _ControlledTrainingPlanNotifier extends DailyTrainingPlanNotifier {
  _ControlledTrainingPlanNotifier(this.flushControl);

  final _FlushControl flushControl;
  int recordCalls = 0;

  @override
  DailyTrainingPlan? build() => null;

  @override
  bool recordAcceptedAttempt(TrainingAttemptEvent event) {
    recordCalls++;
    return true;
  }

  @override
  Future<void> flush() => flushControl.flush();
}

List<TileModel> _tiles() => [
      for (var rank = 1; rank <= 5; rank++)
        TileModel(
          id: 'm$rank',
          suit: TileSuit.man,
          character: '$rank',
          seal: '',
          value: rank,
          label: '$rank Man',
          mnemonic: MnemonicData(
            emoji: '🀇',
            name: 'Tile $rank',
            slogan: 'Remember tile $rank',
            desc: 'Description for tile $rank',
            chinese: '万$rank',
            anchor: 'anchor-$rank',
          ),
          confusedWith: const [],
        ),
    ];

ProviderContainer _createContainer({
  _FlushControl? planFlush,
  _FlushControl? srsFlush,
}) {
  final effectivePlanFlush = planFlush ?? _FlushControl();
  final effectiveSrsFlush = srsFlush ?? _FlushControl();
  final storageNeverCompletes = Completer<StorageService>();
  final container = ProviderContainer(
    overrides: [
      tileRepositoryProvider.overrideWithValue(_TileRepo(_tiles())),
      heartServiceProvider.overrideWith((ref) => _FakeHeartService()),
      srsNotifierProvider.overrideWith(
        () => _CountingSrsNotifier(effectiveSrsFlush),
      ),
      dailyTrainingPlanProvider.overrideWith(
        () => _ControlledTrainingPlanNotifier(effectivePlanFlush),
      ),
      storageServiceProvider.overrideWith(
        (ref) => storageNeverCompletes.future,
      ),
      playerNameProvider.overrideWith((ref) => ''),
      commerceAvailabilityProvider.overrideWithValue(
        const CommerceAvailability(
          platform: TargetPlatform.android,
          salesEnabled: false,
          trainingLimitsEnabled: false,
          restoreEnabled: false,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Widget _localizedApp(ProviderContainer container, Widget home) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
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
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    ),
  );
}

class _ReviewLauncher extends StatelessWidget {
  const _ReviewLauncher(this.result);

  final ValueNotifier<String> result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ValueListenableBuilder<String>(
            valueListenable: result,
            builder: (_, value, __) => Text(
              value,
              key: const ValueKey('review-result'),
            ),
          ),
          ElevatedButton(
            key: const ValueKey('open-review'),
            onPressed: () async {
              final completed = await context.push<bool>('/review');
              result.value = completed == true ? 'completed' : 'cancelled';
            },
            child: const Text('Open review'),
          ),
        ],
      ),
    );
  }
}

GoRouter _pushedReviewRouter(ValueNotifier<String> result) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => _ReviewLauncher(result),
      ),
      GoRoute(
        path: '/review',
        builder: (_, __) => const FlashcardScreen(reviewCardId: 'm1'),
      ),
    ],
  );
}

void _useTallTestSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1200);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _pumpUntilReady(
  WidgetTester tester,
  ProviderContainer container,
) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    await tester.pump();
    if (container.read(flashcardQuizProvider).currentTile != null) return;
  }
  fail('Flashcard quiz did not initialize');
}

Finder _correctOption(ProviderContainer container) {
  final name = container.read(flashcardQuizProvider).currentTile!.mnemonic.name;
  return find.text(name);
}

Finder _wrongOption(ProviderContainer container) {
  final state = container.read(flashcardQuizProvider);
  final wrong = state.options.firstWhere(
    (tile) => tile.id != state.currentTile!.id,
  );
  return find.text(wrong.mnemonic.name);
}

Future<void> _openPushedReview(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.tap(find.byKey(const ValueKey('open-review')));
  await _pumpUntilReady(tester, container);
  await tester.pump(const Duration(milliseconds: 300));
  expect(container.read(flashcardQuizProvider).totalCount, 1);
}

Future<void> _advanceExactReviewToFinished(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.tap(_correctOption(container));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
  await tester.pump();
  expect(container.read(flashcardQuizProvider).isFinished, isTrue);
}

void main() {
  setUp(() {
    AnalyticsService.reset();
    AnalyticsService.disable();
    AudioService.setEnabled(false);
  });

  tearDown(() {
    AnalyticsService.reset();
    AudioService.setEnabled(true);
  });

  testWidgets('manual mnemonic close cancels the correct-answer auto advance',
      (tester) async {
    _useTallTestSurface(tester);
    final container = _createContainer();

    await tester.pumpWidget(
      _localizedApp(container, const FlashcardScreen()),
    );
    await _pumpUntilReady(tester, container);
    final startingIndex = container.read(flashcardQuizProvider).currentIndex;

    await tester.tap(_correctOption(container));
    await tester.pump();
    expect(container.read(flashcardQuizProvider).isAnswering, isTrue);

    container.read(flashcardQuizProvider.notifier).showMnemonic();
    await tester.pump();
    expect(find.text('Got it ✓'), findsOneWidget);

    await tester.tap(find.text('Got it ✓'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 151));
    expect(
      container.read(flashcardQuizProvider).currentIndex,
      startingIndex + 1,
    );

    // Cross both the original 800 ms auto-close deadline and its former
    // 150 ms next-card delay. The same answer must still advance only once.
    await tester.pump(const Duration(seconds: 1));
    expect(
      container.read(flashcardQuizProvider).currentIndex,
      startingIndex + 1,
    );
    expect(container.read(flashcardQuizProvider).isAnswering, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'exact review close waits for plan flush before SRS or navigation',
      (tester) async {
    _useTallTestSurface(tester);
    final pendingPlanFlush = Completer<void>();
    final planFlush = _FlushControl()..blockNext(pendingPlanFlush);
    final container = _createContainer(planFlush: planFlush);
    final result = ValueNotifier<String>('idle');
    final router = _pushedReviewRouter(result);
    addTearDown(result.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(_localizedRouterApp(container, router));
    await _openPushedReview(tester, container);
    await tester.tap(_correctOption(container));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    final srs =
        container.read(srsNotifierProvider.notifier) as _CountingSrsNotifier;
    expect(planFlush.calls, 1);
    expect(srs.recordCalls, 0);
    expect(container.read(srsNotifierProvider), isEmpty);
    expect(router.canPop(), isTrue);
    expect(find.byType(FlashcardScreen), findsOneWidget);
    expect(result.value, 'idle');

    pendingPlanFlush.complete();
    await tester.pumpAndSettle();

    expect(srs.recordCalls, 1);
    expect(container.read(srsNotifierProvider)['m1'], isNotNull);
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(result.value, 'cancelled');
  });

  testWidgets('failed exact-review SRS save retries without double apply',
      (tester) async {
    _useTallTestSurface(tester);
    final srsFlush = _FlushControl()
      ..failNext(StateError('simulated SRS save failure'));
    final container = _createContainer(srsFlush: srsFlush);
    final router = GoRouter(
      initialLocation: '/review',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Home destination')),
        ),
        GoRoute(
          path: '/review',
          builder: (_, __) => const FlashcardScreen(reviewCardId: 'm1'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_localizedRouterApp(container, router));
    await _pumpUntilReady(tester, container);
    await tester.tap(_wrongOption(container));
    await tester.pump();
    expect(find.text('Got it ✓'), findsOneWidget);

    await tester.tap(find.text('Got it ✓'));
    await tester.pump();
    await tester.pump();

    final srs =
        container.read(srsNotifierProvider.notifier) as _CountingSrsNotifier;
    expect(srs.recordCalls, 1);
    expect(srsFlush.calls, 1);
    expect(container.read(flashcardQuizProvider).currentIndex, 0);
    expect(find.text('Got it ✓'), findsOneWidget);
    expect(
      find.text(
        'Your progress could not be saved. Check device storage, then try again.',
      ),
      findsOneWidget,
    );
    expect(router.routeInformationProvider.value.uri.path, '/review');

    await tester.tap(find.text('Got it ✓'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    expect(srsFlush.calls, 2);
    expect(srs.recordCalls, 1);
    expect(container.read(srsNotifierProvider), hasLength(1));
    expect(container.read(srsNotifierProvider)['m1']?.errors, 1);
    expect(container.read(flashcardQuizProvider).isFinished, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('successful pushed exact review returns true to its source',
      (tester) async {
    _useTallTestSurface(tester);
    final container = _createContainer();
    final result = ValueNotifier<String>('idle');
    final router = _pushedReviewRouter(result);
    addTearDown(result.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(_localizedRouterApp(container, router));
    await _openPushedReview(tester, container);
    await _advanceExactReviewToFinished(tester, container);
    expect(find.text('Finish Review'), findsOneWidget);

    await tester.tap(find.text('Finish Review'));
    await tester.pumpAndSettle();

    final srs =
        container.read(srsNotifierProvider.notifier) as _CountingSrsNotifier;
    expect(srs.recordCalls, 1);
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(result.value, 'completed');
    expect(find.byType(FlashcardScreen), findsNothing);
  });

  testWidgets('system back waits on the same exact-review save barrier',
      (tester) async {
    _useTallTestSurface(tester);
    final pendingPlanFlush = Completer<void>();
    final planFlush = _FlushControl()..blockNext(pendingPlanFlush);
    final container = _createContainer(planFlush: planFlush);
    final result = ValueNotifier<String>('idle');
    final router = _pushedReviewRouter(result);
    addTearDown(result.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(_localizedRouterApp(container, router));
    await _openPushedReview(tester, container);
    await tester.tap(_correctOption(container));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    final srs =
        container.read(srsNotifierProvider.notifier) as _CountingSrsNotifier;
    expect(planFlush.calls, 1);
    expect(srs.recordCalls, 0);
    expect(router.canPop(), isTrue);
    expect(find.byType(FlashcardScreen), findsOneWidget);
    expect(result.value, 'idle');

    pendingPlanFlush.complete();
    await tester.pumpAndSettle();

    expect(srs.recordCalls, 1);
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(result.value, 'cancelled');
  });

  testWidgets('root exact review finishes by going home instead of popping',
      (tester) async {
    _useTallTestSurface(tester);
    final container = _createContainer();
    final router = GoRouter(
      initialLocation: '/review',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: Text('Home destination'),
          ),
        ),
        GoRoute(
          path: '/review',
          builder: (_, __) => const FlashcardScreen(reviewCardId: 'm1'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_localizedRouterApp(container, router));
    await _pumpUntilReady(tester, container);
    expect(container.read(flashcardQuizProvider).totalCount, 1);

    await _advanceExactReviewToFinished(tester, container);
    expect(find.text('Finish Review'), findsOneWidget);

    await tester.tap(find.text('Finish Review'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(find.text('Home destination'), findsOneWidget);
    expect(find.byType(FlashcardScreen), findsNothing);
  });
}
