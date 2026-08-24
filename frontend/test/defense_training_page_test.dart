import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tilezhan/core/providers/tile_data_provider.dart';
import 'package:tilezhan/core/srs/srs_item.dart';
import 'package:tilezhan/core/srs/srs_provider.dart';
import 'package:tilezhan/core/utils/audio_service.dart';
import 'package:tilezhan/features/defense_trainer/data/defense_progress_store.dart';
import 'package:tilezhan/features/defense_trainer/domain/defense_catalog.dart';
import 'package:tilezhan/features/defense_trainer/domain/defense_progress.dart';
import 'package:tilezhan/features/defense_trainer/domain/defense_trainer.dart';
import 'package:tilezhan/features/defense_trainer/domain/defense_training_state.dart';
import 'package:tilezhan/features/defense_trainer/presentation/defense_training_page.dart';
import 'package:tilezhan/features/training_plan/data/training_plan_store.dart';
import 'package:tilezhan/features/training_plan/domain/training_plan.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';
import 'package:tilezhan/shared/models/tile_model.dart';

class _MemorySrsNotifier extends SrsReviewNotifier {
  @override
  Map<String, SrsItem> build() => {};
}

class _RecordingSrsNotifier extends SrsReviewNotifier {
  _RecordingSrsNotifier(this.events);

  final List<String> events;
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
    recordCalls += 1;
    events.add('srs.record');
    super.recordReview(
      itemId,
      type,
      quality,
      content: content,
    );
  }

  @override
  Future<void> flush() async {
    events.add('srs.flush');
  }
}

class _ControlledPlanNotifier extends DailyTrainingPlanNotifier {
  _ControlledPlanNotifier(this.events);

  final List<String> events;
  final List<TrainingAttemptEvent> attempts = [];
  bool failFlush = true;
  int flushCalls = 0;

  @override
  DailyTrainingPlan? build() => DailyTrainingPlan(
        localDate: DateTime.now(),
        tasks: [
          TrainingPlanTask(
            id: 'test.review',
            kind: TrainingTaskKind.dueReview,
            module: TrainingModule.review,
            targetAttempts: 1,
          ),
        ],
      );

  @override
  bool recordAcceptedAttempt(TrainingAttemptEvent event) {
    attempts.add(event);
    events.add('plan.record');
    return true;
  }

  @override
  Future<void> flush() async {
    flushCalls += 1;
    events.add('plan.flush.$flushCalls');
    if (failFlush) throw StateError('simulated plan failure');
  }
}

class _ReviewLauncher extends StatelessWidget {
  const _ReviewLauncher({
    required this.questionId,
    required this.result,
  });

  final String questionId;
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
              final completed = await context.push<bool>(
                Uri(
                  path: '/defense-training',
                  queryParameters: {'contentId': questionId},
                ).toString(),
              );
              result.value = completed == true ? 'completed' : 'cancelled';
            },
            child: const Text('Open review'),
          ),
        ],
      ),
    );
  }
}

Widget _reviewApp({
  required ProviderContainer container,
  required String questionId,
  required ValueNotifier<String> result,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => _ReviewLauncher(
          questionId: questionId,
          result: result,
        ),
      ),
      GoRoute(
        path: '/defense-training',
        builder: (_, state) => DefenseTrainingPage(
          reviewQuestionId: state.uri.queryParameters['contentId'],
          seed: 9,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
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

ProviderContainer _reviewContainer({
  _RecordingSrsNotifier? srsNotifier,
  _ControlledPlanNotifier? planNotifier,
}) {
  final progressStore = InMemoryDefenseProgressStore();
  final effectivePlanNotifier =
      planNotifier ?? (_ControlledPlanNotifier(<String>[])..failFlush = false);
  return ProviderContainer(
    overrides: [
      tileDataProvider.overrideWith((ref) async => _tiles()),
      srsNotifierProvider.overrideWith(
        srsNotifier == null ? _MemorySrsNotifier.new : () => srsNotifier,
      ),
      defenseProgressStoreProvider.overrideWith((ref) async => progressStore),
      dailyTrainingPlanProvider.overrideWith(() => effectivePlanNotifier),
    ],
  );
}

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

void main() {
  test('defense SRS snapshot is versioned and language neutral', () {
    final question = DefenseQuestionCatalog.questions.first;
    final evaluation = DefenseTrainerEvaluator.evaluate(
      question: question,
      selectedChoiceId: question.bestChoiceId,
    );
    final answer = DefenseTrainingAnswer.fromEvaluation(evaluation);

    final snapshot = buildDefenseSrsSnapshot(answer);

    expect(snapshot['schemaVersion'], 1);
    expect(snapshot['rulesetVersion'], 'yonma_riichi_defense_v1');
    expect(snapshot['questionId'], question.id);
    expect(snapshot['topic'], question.topic.name);
    expect(snapshot['targetSeat'], question.targetSeat.name);
    expect(snapshot['bestChoiceId'], question.bestChoiceId);
    expect(snapshot['lastSelectedChoiceId'], question.bestChoiceId);
    expect(snapshot['lastOutcome'], 'correct');
    expect(snapshot['choices'], hasLength(4));
    expect(
      snapshot.toString(),
      isNot(contains('Good decision')),
    );
  });

  testWidgets(
      'accepted exact answer defers SRS and updates aggregate progress once',
      (tester) async {
    const questionId = 'defense.genbutsu.002.v1';
    final question = DefenseQuestionCatalog.byId[questionId]!;
    final progressStore = InMemoryDefenseProgressStore();
    final planNotifier = _ControlledPlanNotifier(<String>[])..failFlush = false;
    final container = ProviderContainer(
      overrides: [
        tileDataProvider.overrideWith((ref) async => _tiles()),
        srsNotifierProvider.overrideWith(_MemorySrsNotifier.new),
        defenseProgressStoreProvider.overrideWith(
          (ref) async => progressStore,
        ),
        dailyTrainingPlanProvider.overrideWith(() => planNotifier),
      ],
    );
    addTearDown(container.dispose);
    final previousAudioSetting = AudioService.isEnabled;
    AudioService.setEnabled(false);
    addTearDown(() => AudioService.setEnabled(previousAudioSetting));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: DefenseTrainingPage(
            reviewQuestionId: questionId,
            seed: 9,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final choice = find.byKey(
      ValueKey('defense-choice-${question.bestChoiceId}'),
    );
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();

    // Exact review SRS removal must wait until its plan event is durable.
    expect(container.read(srsNotifierProvider)[questionId], isNull);

    final stats =
        container.read(defenseProgressProvider).skill(DefenseSkillIds.genbutsu);
    expect(stats?.attempts, 1);
    expect(stats?.correct, 1);

    // The revealed choice is disabled, so a second tap cannot record again.
    await tester.tap(choice, warnIfMissed: false);
    await tester.pump();
    expect(
      container
          .read(defenseProgressProvider)
          .skill(DefenseSkillIds.genbutsu)
          ?.attempts,
      1,
    );
  });

  testWidgets('closing an exact review returns cancellation', (tester) async {
    const questionId = 'defense.genbutsu.002.v1';
    final container = _reviewContainer();
    final result = ValueNotifier<String>('idle');
    addTearDown(container.dispose);
    addTearDown(result.dispose);

    await tester.pumpWidget(_reviewApp(
      container: container,
      questionId: questionId,
      result: result,
    ));
    await tester.tap(find.byKey(const ValueKey('open-review')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('cancelled'), findsOneWidget);
    expect(container.read(srsNotifierProvider)[questionId], isNull);
  });

  testWidgets('an unavailable exact review exits as cancellation',
      (tester) async {
    final container = _reviewContainer();
    final result = ValueNotifier<String>('idle');
    addTearDown(container.dispose);
    addTearDown(result.dispose);

    await tester.pumpWidget(_reviewApp(
      container: container,
      questionId: 'defense.removed.999.v1',
      result: result,
    ));
    await tester.tap(find.byKey(const ValueKey('open-review')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('defense-error-done')));
    await tester.pumpAndSettle();

    expect(find.text('cancelled'), findsOneWidget);
  });

  testWidgets('finishing an answered exact review returns completion',
      (tester) async {
    const questionId = 'defense.genbutsu.002.v1';
    final question = DefenseQuestionCatalog.byId[questionId]!;
    final container = _reviewContainer();
    final result = ValueNotifier<String>('idle');
    addTearDown(container.dispose);
    addTearDown(result.dispose);

    await tester.pumpWidget(_reviewApp(
      container: container,
      questionId: questionId,
      result: result,
    ));
    await tester.tap(find.byKey(const ValueKey('open-review')));
    await tester.pumpAndSettle();

    final choice = find.byKey(
      ValueKey('defense-choice-${question.bestChoiceId}'),
    );
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('defense-next')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('defense-next')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('defense-review-done')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('defense-review-done')));
    await tester.pumpAndSettle();

    expect(find.text('completed'), findsOneWidget);
    final srsItem = container.read(srsNotifierProvider)[questionId];
    expect(srsItem, isNotNull);
    expect(srsItem!.type, 'defense');
    expect(srsItem.reps, 1);
    expect(srsItem.errors, 0);
    expect(srsItem.content?['questionId'], questionId);
    expect(srsItem.content?['lastOutcome'], 'correct');
  });

  testWidgets(
      'exact review system back saves plan before one SRS mutation and retries',
      (tester) async {
    const questionId = 'defense.genbutsu.002.v1';
    final question = DefenseQuestionCatalog.byId[questionId]!;
    final events = <String>[];
    final srsNotifier = _RecordingSrsNotifier(events);
    final planNotifier = _ControlledPlanNotifier(events);
    final container = _reviewContainer(
      srsNotifier: srsNotifier,
      planNotifier: planNotifier,
    );
    final result = ValueNotifier<String>('idle');
    addTearDown(container.dispose);
    addTearDown(result.dispose);
    final previousAudioSetting = AudioService.isEnabled;
    AudioService.setEnabled(false);
    addTearDown(() => AudioService.setEnabled(previousAudioSetting));

    await tester.pumpWidget(_reviewApp(
      container: container,
      questionId: questionId,
      result: result,
    ));
    await tester.tap(find.byKey(const ValueKey('open-review')));
    await tester.pumpAndSettle();

    final choice = find.byKey(
      ValueKey('defense-choice-${question.bestChoiceId}'),
    );
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();

    expect(planNotifier.attempts, hasLength(1));
    expect(srsNotifier.recordCalls, 0);
    expect(container.read(srsNotifierProvider)[questionId], isNull);
    expect(events, ['plan.record']);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(DefenseTrainingPage), findsOneWidget);
    expect(srsNotifier.recordCalls, 0);
    expect(events, ['plan.record', 'plan.flush.1']);

    planNotifier.failFlush = false;
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('cancelled'), findsOneWidget);
    expect(find.byType(DefenseTrainingPage), findsNothing);
    expect(srsNotifier.recordCalls, 1);
    expect(container.read(srsNotifierProvider)[questionId], isNotNull);
    expect(events, [
      'plan.record',
      'plan.flush.1',
      'plan.flush.2',
      'srs.record',
      'plan.flush.3',
      'srs.flush',
    ]);
  });
}
