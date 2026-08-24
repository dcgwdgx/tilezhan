import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tilezhan/features/defense_trainer/data/defense_progress_store.dart';
import 'package:tilezhan/features/defense_trainer/domain/defense_progress.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_skill_mastery.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_skill_mastery_provider.dart';
import 'package:tilezhan/features/training_plan/data/training_plan_store.dart';
import 'package:tilezhan/features/training_plan/domain/training_plan.dart';
import 'package:tilezhan/features/training_plan/presentation/today_training_card.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';

class _FixedPlanNotifier extends DailyTrainingPlanNotifier {
  _FixedPlanNotifier(this.plan);

  final DailyTrainingPlan plan;

  @override
  DailyTrainingPlan? build() => plan;
}

class _RolloverPlanNotifier extends DailyTrainingPlanNotifier {
  _RolloverPlanNotifier(this.beforeMidnight, this.afterMidnight);

  final DailyTrainingPlan beforeMidnight;
  final DailyTrainingPlan afterMidnight;

  @override
  DailyTrainingPlan? build() => beforeMidnight;

  @override
  bool refreshForToday() {
    state = afterMidnight;
    return true;
  }
}

class _CountingPendingPlanNotifier extends DailyTrainingPlanNotifier {
  int buildCalls = 0;

  @override
  DailyTrainingPlan? build() {
    buildCalls += 1;
    return null;
  }
}

class _EmptyNanikiruMasteryNotifier extends NanikiruSkillMasteryNotifier {
  @override
  NanikiruSkillMasteryProfile build() => NanikiruSkillMasteryProfile.empty();
}

class _EmptyDefenseProgressNotifier extends DefenseProgressNotifier {
  @override
  DefenseProgressProfile build() => DefenseProgressProfile.empty();
}

DailyTrainingPlan _planWith(TrainingPlanTask task) => DailyTrainingPlan(
      localDate: DateTime(2026, 8, 24),
      tasks: [task],
    );

Widget _app(
  DailyTrainingPlan plan, {
  DailyTrainingPlanNotifier Function()? planNotifier,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: TodayTrainingCard()),
      ),
      for (final path in const [
        '/flashcard',
        '/nanikiru',
        '/defense-training',
        '/yaku-quiz',
        '/graveyard',
      ])
        GoRoute(
          path: path,
          builder: (_, state) => Scaffold(
            body: Text(
              state.uri.toString(),
              key: const ValueKey('destination-uri'),
            ),
          ),
        ),
    ],
  );
  addTearDown(router.dispose);
  return ProviderScope(
    overrides: [
      dailyTrainingPlanProvider.overrideWith(
        planNotifier ?? () => _FixedPlanNotifier(plan),
      ),
      nanikiruSkillMasteryProvider.overrideWith(
        _EmptyNanikiruMasteryNotifier.new,
      ),
      defenseProgressProvider.overrideWith(
        _EmptyDefenseProgressNotifier.new,
      ),
    ],
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

Future<void> _openNextTask(
  WidgetTester tester,
  DailyTrainingPlan plan,
) async {
  await tester.pumpWidget(_app(plan));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('training-plan-cta')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('flashcard CTA carries only the remaining plan attempts',
      (tester) async {
    await _openNextTask(
      tester,
      _planWith(
        TrainingPlanTask(
          id: 'starter:flashcard',
          kind: TrainingTaskKind.starterLesson,
          module: TrainingModule.flashcard,
          targetAttempts: 3,
          completedAttempts: 1,
        ),
      ),
    );

    expect(
      find.text('/flashcard?source=today-plan&target=2'),
      findsOneWidget,
    );
  });

  testWidgets('Nanikiru weak CTA carries focus and remaining target',
      (tester) async {
    await _openNextTask(
      tester,
      _planWith(
        TrainingPlanTask(
          id: 'weak:nanikiru:isolated_tile_handling',
          kind: TrainingTaskKind.weakSkill,
          module: TrainingModule.nanikiru,
          targetAttempts: 3,
          completedAttempts: 2,
          focusSkillId: NanikiruSkillIds.isolatedTileHandling,
        ),
      ),
    );

    expect(
      find.text(
        '/nanikiru?source=today-plan&target=1&focusSkillId='
        '${NanikiruSkillIds.isolatedTileHandling}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('defense weak CTA carries focus and remaining target',
      (tester) async {
    await _openNextTask(
      tester,
      _planWith(
        TrainingPlanTask(
          id: 'weak:defense:suji',
          kind: TrainingTaskKind.weakSkill,
          module: TrainingModule.defense,
          targetAttempts: 2,
          completedAttempts: 1,
          focusSkillId: DefenseSkillIds.suji,
        ),
      ),
    );

    expect(
      find.text(
        '/defense-training?source=today-plan&target=1&focusSkillId='
        '${DefenseSkillIds.suji}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('yaku exploration CTA carries its full target', (tester) async {
    await _openNextTask(
      tester,
      _planWith(
        TrainingPlanTask(
          id: 'explore:yaku',
          kind: TrainingTaskKind.exploration,
          module: TrainingModule.yaku,
          targetAttempts: 3,
        ),
      ),
    );

    expect(
      find.text('/yaku-quiz?source=today-plan&target=3'),
      findsOneWidget,
    );
  });

  testWidgets('daily challenge keeps its dedicated three-attempt mode',
      (tester) async {
    await _openNextTask(
      tester,
      _planWith(
        TrainingPlanTask(
          id: 'daily:nanikiru',
          kind: TrainingTaskKind.dailyChallenge,
          module: TrainingModule.nanikiru,
          targetAttempts: 3,
        ),
      ),
    );

    expect(
      find.text('/nanikiru?mode=daily&source=today-plan&target=3'),
      findsOneWidget,
    );
  });

  testWidgets('due review CTA carries only the remaining review count',
      (tester) async {
    await _openNextTask(
      tester,
      _planWith(
        TrainingPlanTask(
          id: 'review:due',
          kind: TrainingTaskKind.dueReview,
          module: TrainingModule.review,
          targetAttempts: 5,
          completedAttempts: 3,
        ),
      ),
    );

    expect(
      find.text('/graveyard?source=today-plan&target=2'),
      findsOneWidget,
    );
  });

  testWidgets('CTA refreshes an always-open Home before routing after midnight',
      (tester) async {
    final yesterday = _planWith(
      TrainingPlanTask(
        id: 'yesterday:flashcard',
        kind: TrainingTaskKind.starterLesson,
        module: TrainingModule.flashcard,
        targetAttempts: 3,
      ),
    );
    final today = DailyTrainingPlan(
      localDate: DateTime(2026, 8, 25),
      tasks: [
        TrainingPlanTask(
          id: 'today:defense',
          kind: TrainingTaskKind.exploration,
          module: TrainingModule.defense,
          targetAttempts: 2,
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        yesterday,
        planNotifier: () => _RolloverPlanNotifier(yesterday, today),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Learn the core tiles'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('training-plan-cta')));
    await tester.pumpAndSettle();

    expect(
      find.text('/defense-training?source=today-plan&target=2'),
      findsOneWidget,
    );
  });

  testWidgets('load retry preserves the notifier holding pre-bootstrap events',
      (tester) async {
    final notifier = _CountingPendingPlanNotifier();
    final container = ProviderContainer(
      overrides: [
        dailyTrainingPlanProvider.overrideWith(() => notifier),
        trainingPlanBootstrapProvider.overrideWith(
          (ref) async => throw StateError('test bootstrap failure'),
        ),
      ],
    );
    addTearDown(container.dispose);

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
          home: Scaffold(body: TodayTrainingCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    container.read(dailyTrainingPlanProvider.notifier).recordAcceptedAttempt(
          TrainingAttemptEvent(
            eventId: 'pending-before-bootstrap',
            module: TrainingModule.flashcard,
            occurredAt: DateTime(2026, 8, 24).millisecondsSinceEpoch,
          ),
        );
    expect(notifier.buildCalls, 1);

    await tester.tap(find.text('RETRY PLAN'));
    await tester.pump();
    await tester.pump();

    expect(notifier.buildCalls, 1);
  });
}
