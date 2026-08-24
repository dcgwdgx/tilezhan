import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tilezhan/core/analytics/analytics_service.dart';
import 'package:tilezhan/core/hearts/heart_provider.dart';
import 'package:tilezhan/core/hearts/heart_service.dart';
import 'package:tilezhan/core/iap/iap_provider.dart';
import 'package:tilezhan/core/srs/srs_item.dart';
import 'package:tilezhan/core/srs/srs_provider.dart';
import 'package:tilezhan/core/utils/audio_service.dart';
import 'package:tilezhan/features/training_plan/data/training_plan_store.dart';
import 'package:tilezhan/features/training_plan/domain/training_plan.dart';
import 'package:tilezhan/features/yaku_quiz/domain/yaku_quiz_provider.dart';
import 'package:tilezhan/features/yaku_quiz/domain/yaku_quiz_question.dart';
import 'package:tilezhan/features/yaku_quiz/domain/yaku_quiz_repository.dart';
import 'package:tilezhan/features/yaku_quiz/domain/yaku_quiz_state.dart';
import 'package:tilezhan/features/yaku_quiz/presentation/yaku_quiz_screen.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';

const _questionId = 'test.yaku.rule.dora_is_yaku.v1';

class _SingleQuestionRepository implements YakuQuizRepository {
  static const question = YakuQuizQuestion(
    id: _questionId,
    kind: YakuQuizQuestionKind.ruleJudgement,
    promptKey: YakuQuizCopyKey.promptDoraIsYaku,
    explanationKey: YakuQuizCopyKey.explanationDoraIsYaku,
    correctAnswer: YakuQuizAnswer.boolean(false),
    options: [
      YakuQuizAnswer.boolean(true),
      YakuQuizAnswer.boolean(false),
    ],
  );

  @override
  List<YakuQuizQuestion> get questions => const [question];

  @override
  YakuQuizQuestion? findById(String id) => id == _questionId ? question : null;
}

class _FakeHeartService extends HeartService {
  @override
  bool get hasHearts => true;

  @override
  Future<void> init() async {}

  @override
  void recordCorrect() {}

  @override
  void recordWrong() {}

  @override
  bool consume() => false;
}

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

ProviderContainer _createContainer({
  _RecordingSrsNotifier? srsNotifier,
  _ControlledPlanNotifier? planNotifier,
}) {
  final effectivePlanNotifier =
      planNotifier ?? (_ControlledPlanNotifier(<String>[])..failFlush = false);
  final container = ProviderContainer(
    overrides: [
      yakuQuizRepositoryProvider.overrideWithValue(
        _SingleQuestionRepository(),
      ),
      heartServiceProvider.overrideWith((ref) => _FakeHeartService()),
      isPremiumProvider.overrideWithValue(true),
      srsNotifierProvider.overrideWith(
        srsNotifier == null ? _MemorySrsNotifier.new : () => srsNotifier,
      ),
      dailyTrainingPlanProvider.overrideWith(() => effectivePlanNotifier),
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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  setUp(() {
    AnalyticsService.reset();
    AudioService.setEnabled(false);
  });

  tearDown(() {
    AnalyticsService.reset();
    AudioService.setEnabled(true);
  });

  testWidgets('renders and starts the first yaku question', (tester) async {
    final container = _createContainer();

    await tester.pumpWidget(
      _localizedApp(container, const YakuQuizScreen(seed: 7)),
    );
    await tester.pump();

    expect(find.byType(YakuQuizScreen), findsOneWidget);
    expect(find.text('Yaku Dojo'), findsOneWidget);
    expect(
      find.text('Can dora alone satisfy the yaku requirement for winning?'),
      findsOneWidget,
    );
    expect(find.text('True'), findsOneWidget);
    expect(find.text('False'), findsOneWidget);
    expect(container.read(yakuQuizProvider).phase, YakuQuizPhase.answering);
    expect(container.read(yakuQuizProvider).currentQuestion?.id, _questionId);
  });

  testWidgets('submitting an answer reveals feedback and records SRS review',
      (tester) async {
    final container = _createContainer();

    await tester.pumpWidget(
      _localizedApp(container, const YakuQuizScreen(seed: 7)),
    );
    await tester.pump();
    await tester.tap(find.text('False'));
    await tester.pump();

    expect(find.text('Correct!'), findsOneWidget);
    expect(find.text('Explanation'), findsOneWidget);
    expect(
      find.text(
        'Dora add han but are not yaku. The hand still needs at least one '
        'valid yaku to win.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    final review = container.read(srsNotifierProvider)[_questionId];
    expect(review, isNotNull);
    expect(review!.type, 'yaku');
    expect(review.content?['questionId'], _questionId);
    expect(review.content?['correctAnswer'], false);
  });

  testWidgets('exact review finishes and returns to its source route',
      (tester) async {
    final container = _createContainer();
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
          builder: (context, state) => const YakuQuizScreen(
            reviewQuestionId: _questionId,
            seed: 7,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_localizedRouterApp(container, router));
    router.push<void>('/review');
    await tester.pumpAndSettle();

    expect(container.read(yakuQuizProvider).totalCount, 1);
    expect(container.read(yakuQuizProvider).currentQuestion?.id, _questionId);

    await tester.tap(find.text('False'));
    await tester.pumpAndSettle();
    expect(find.text('Finish Review'), findsOneWidget);

    await tester.tap(find.text('Finish Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review source'), findsOneWidget);
    expect(find.byType(YakuQuizScreen), findsNothing);
  });

  testWidgets(
      'exact review system back saves plan before one SRS mutation and retries',
      (tester) async {
    final events = <String>[];
    final srsNotifier = _RecordingSrsNotifier(events);
    final planNotifier = _ControlledPlanNotifier(events);
    final container = _createContainer(
      srsNotifier: srsNotifier,
      planNotifier: planNotifier,
    );
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
          builder: (context, state) => const YakuQuizScreen(
            reviewQuestionId: _questionId,
            seed: 7,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_localizedRouterApp(container, router));
    router.push<void>('/review');
    await tester.pumpAndSettle();
    await tester.tap(find.text('False'));
    await tester.pumpAndSettle();

    expect(planNotifier.attempts, hasLength(1));
    expect(srsNotifier.recordCalls, 0);
    expect(container.read(srsNotifierProvider)[_questionId], isNull);
    expect(events, ['plan.record']);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(YakuQuizScreen), findsOneWidget);
    expect(find.text('Review source'), findsNothing);
    expect(srsNotifier.recordCalls, 0);
    expect(events, ['plan.record', 'plan.flush.1']);

    planNotifier.failFlush = false;
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Review source'), findsOneWidget);
    expect(find.byType(YakuQuizScreen), findsNothing);
    expect(srsNotifier.recordCalls, 1);
    expect(container.read(srsNotifierProvider)[_questionId], isNotNull);
    expect(events, [
      'plan.record',
      'plan.flush.1',
      'plan.flush.2',
      'srs.record',
      'plan.flush.3',
      'srs.flush',
    ]);
  });

  testWidgets('today-plan target returns after the requested answer count',
      (tester) async {
    final container = _createContainer();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Text('Plan source'),
          ),
        ),
        GoRoute(
          path: '/lesson',
          builder: (context, state) => const YakuQuizScreen(
            seed: 7,
            planTarget: 1,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_localizedRouterApp(container, router));
    router.push<void>('/lesson');
    await tester.pumpAndSettle();

    await tester.tap(find.text('False'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('Plan source'), findsOneWidget);
    expect(find.byType(YakuQuizScreen), findsNothing);
  });
}
