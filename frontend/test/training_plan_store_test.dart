import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/defense_trainer/domain/defense_progress.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_skill_mastery.dart';
import 'package:tilezhan/features/training_plan/data/training_plan_store.dart';
import 'package:tilezhan/features/training_plan/domain/training_plan.dart';
import 'package:tilezhan/features/training_plan/domain/training_plan_generator.dart';

void main() {
  final now = DateTime(2026, 8, 24, 10);

  group('DailyTrainingPlanNotifier', () {
    test('generates and persists one fixed plan when storage is empty',
        () async {
      final store = _MemoryStore();
      final container = _container(now: now, store: store);
      addTearDown(container.dispose);

      expect(container.read(dailyTrainingPlanProvider), isNull);
      final notifier = container.read(dailyTrainingPlanProvider.notifier);
      await notifier.flush();

      final plan = container.read(dailyTrainingPlanProvider)!;
      expect(plan.localDateKey, '2026-08-24');
      expect(plan.tasks, hasLength(3));
      expect(store.writes, hasLength(1));
      expect(store.persisted!.tasks.map((task) => task.id),
          plan.tasks.map((task) => task.id));
    });

    test('loads today fixed plan without regenerating or writing', () async {
      final existing = const TrainingPlanGenerator().generate(
        now: now,
        inputs: _emptyInputs(),
      );
      final store = _MemoryStore(initial: existing);
      final container = _container(now: now, store: store);
      addTearDown(container.dispose);

      final notifier = container.read(dailyTrainingPlanProvider.notifier);
      await notifier.flush();

      expect(
        container.read(dailyTrainingPlanProvider)!.tasks.map((task) => task.id),
        existing.tasks.map((task) => task.id),
      );
      expect(store.writes, isEmpty);
    });

    test('replays accepted answers that arrive before bootstrap', () async {
      final store = _MemoryStore();
      final bootstrap = Completer<TrainingPlanBootstrap>();
      final container = ProviderContainer(overrides: [
        trainingPlanClockProvider.overrideWithValue(() => now),
        trainingPlanBootstrapProvider.overrideWith((ref) => bootstrap.future),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(dailyTrainingPlanProvider.notifier);

      notifier.recordAcceptedAttempt(
        TrainingAttemptEvent(
          eventId: 'flashcard-before-storage',
          module: TrainingModule.flashcard,
          occurredAt: now.millisecondsSinceEpoch,
        ),
      );
      bootstrap.complete(
        TrainingPlanBootstrap(store: store, inputs: _emptyInputs()),
      );
      await notifier.flush();

      final plan = container.read(dailyTrainingPlanProvider)!;
      expect(plan.tasks.first.completedAttempts, 1);
      expect(plan.acceptedEventIds, ['flashcard-before-storage']);
      expect(store.persisted!.tasks.first.completedAttempts, 1);
      expect(store.writes, hasLength(1));
    });

    test('serializes rapid progress and persists the newest snapshot',
        () async {
      final existing = const TrainingPlanGenerator().generate(
        now: now,
        inputs: _emptyInputs(),
      );
      final store = _MemoryStore(
        initial: existing,
        writeDelay: const Duration(milliseconds: 1),
      );
      final container = _container(now: now, store: store);
      addTearDown(container.dispose);
      final notifier = container.read(dailyTrainingPlanProvider.notifier);
      await notifier.flush();

      for (var index = 0; index < 3; index++) {
        expect(
          notifier.recordAcceptedAttempt(
            TrainingAttemptEvent(
              eventId: 'flashcard-$index',
              module: TrainingModule.flashcard,
              occurredAt: now.millisecondsSinceEpoch + index,
            ),
          ),
          isTrue,
        );
      }
      await notifier.flush();

      expect(store.maximumConcurrentWrites, 1);
      expect(store.writes.length, lessThanOrEqualTo(3));
      expect(store.persisted!.tasks.first.completedAttempts, 3);
      expect(store.persisted!.acceptedEventIds, hasLength(3));
    });

    test('flush retries a terminal dirty snapshot', () async {
      final existing = const TrainingPlanGenerator().generate(
        now: now,
        inputs: _emptyInputs(),
      );
      final store = _MemoryStore(initial: existing, failWriteCount: 1);
      final container = _container(now: now, store: store);
      addTearDown(container.dispose);
      final notifier = container.read(dailyTrainingPlanProvider.notifier);
      await notifier.flush();

      notifier.recordAcceptedAttempt(
        TrainingAttemptEvent(
          eventId: 'retry-me',
          module: TrainingModule.flashcard,
          occurredAt: now.millisecondsSinceEpoch,
        ),
      );
      await notifier.flush();

      expect(store.writeAttempts, 2);
      expect(store.persisted!.tasks.first.completedAttempts, 1);
    });

    test('persistent failure is explicit and a later flush can recover',
        () async {
      final existing = const TrainingPlanGenerator().generate(
        now: now,
        inputs: _emptyInputs(),
      );
      final store = _MemoryStore(initial: existing, failWriteCount: 2);
      final container = _container(now: now, store: store);
      addTearDown(container.dispose);
      final notifier = container.read(dailyTrainingPlanProvider.notifier);
      await notifier.flush();

      notifier.recordAcceptedAttempt(
        TrainingAttemptEvent(
          eventId: 'recover-me',
          module: TrainingModule.flashcard,
          occurredAt: now.millisecondsSinceEpoch,
        ),
      );
      await expectLater(notifier.flush(), throwsStateError);
      expect(store.writeAttempts, 2);

      await notifier.flush();
      expect(store.writeAttempts, 3);
      expect(store.persisted!.tasks.first.completedAttempts, 1);
    });

    test('future schema gets a usable session plan but is never overwritten',
        () async {
      final future = DailyTrainingPlan.tryFromJson({
        'schemaVersion': 2,
        'planVersion': 1,
        'localDate': '2026-08-24',
        'currentStreak': 2,
        'bestStreak': 5,
      })!;
      final store = _MemoryStore(initial: future);
      final container = _container(now: now, store: store);
      addTearDown(container.dispose);
      final notifier = container.read(dailyTrainingPlanProvider.notifier);
      await notifier.flush();

      final plan = container.read(dailyTrainingPlanProvider)!;
      expect(plan.isReadOnly, isTrue);
      expect(plan.tasks, hasLength(3));
      notifier.recordAcceptedAttempt(
        TrainingAttemptEvent(
          eventId: 'session-only',
          module: TrainingModule.flashcard,
          occurredAt: now.millisecondsSinceEpoch,
        ),
      );
      await notifier.flush();

      expect(
          container
              .read(dailyTrainingPlanProvider)!
              .tasks
              .first
              .completedAttempts,
          1);
      expect(store.writes, isEmpty);
      expect(store.writeAttempts, 0);
    });

    test('an old event cannot roll a newer stored plan backwards', () async {
      final existing = const TrainingPlanGenerator().generate(
        now: now,
        inputs: _emptyInputs(),
      );
      final store = _MemoryStore(initial: existing);
      final container = _container(now: now, store: store);
      addTearDown(container.dispose);
      final notifier = container.read(dailyTrainingPlanProvider.notifier);
      await notifier.flush();

      final accepted = notifier.recordAcceptedAttempt(
        TrainingAttemptEvent(
          eventId: 'yesterday',
          module: TrainingModule.flashcard,
          occurredAt: DateTime(2026, 8, 23).millisecondsSinceEpoch,
        ),
      );
      await notifier.flush();

      expect(accepted, isFalse);
      expect(container.read(dailyTrainingPlanProvider)!.localDateKey,
          '2026-08-24');
      expect(store.writes, isEmpty);
    });

    test('refreshes yesterday plan before Home shows its task targets',
        () async {
      var clock = now;
      final existing = const TrainingPlanGenerator().generate(
        now: clock,
        inputs: _emptyInputs(),
      );
      final store = _MemoryStore(initial: existing);
      final container = ProviderContainer(overrides: [
        trainingPlanClockProvider.overrideWithValue(() => clock),
        trainingPlanBootstrapProvider.overrideWith(
          (ref) async =>
              TrainingPlanBootstrap(store: store, inputs: _emptyInputs()),
        ),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(dailyTrainingPlanProvider.notifier);
      await notifier.flush();

      clock = DateTime(2026, 8, 25, 8);
      expect(notifier.refreshForToday(), isTrue);
      await notifier.flush();

      expect(
        container.read(dailyTrainingPlanProvider)!.localDateKey,
        '2026-08-25',
      );
      expect(store.persisted!.localDateKey, '2026-08-25');
      expect(notifier.refreshForToday(), isFalse);
    });
  });

  test('in-memory store respects the future-schema read-only contract',
      () async {
    final future = DailyTrainingPlan.tryFromJson({
      'schemaVersion': 2,
      'planVersion': 1,
      'localDate': '2026-08-24',
    })!;
    final store = InMemoryTrainingPlanStore();
    await store.write(future);
    expect(store.read(), isNull);
    expect(StorageServiceTrainingPlanStore, isNotNull);
  });
}

TrainingPlanInputs _emptyInputs() => TrainingPlanInputs(
      srsItems: const {},
      nanikiruMastery: NanikiruSkillMasteryProfile.empty(),
      defenseProgress: DefenseProgressProfile.empty(),
    );

ProviderContainer _container({
  required DateTime now,
  required TrainingPlanStore store,
}) {
  return ProviderContainer(overrides: [
    trainingPlanClockProvider.overrideWithValue(() => now),
    trainingPlanBootstrapProvider.overrideWith(
      (ref) async =>
          TrainingPlanBootstrap(store: store, inputs: _emptyInputs()),
    ),
  ]);
}

class _MemoryStore implements TrainingPlanStore {
  _MemoryStore({
    DailyTrainingPlan? initial,
    this.writeDelay = Duration.zero,
    this.failWriteCount = 0,
  }) : persisted = initial;

  final Duration writeDelay;
  final int failWriteCount;
  final List<DailyTrainingPlan> writes = [];
  DailyTrainingPlan? persisted;
  int writeAttempts = 0;
  int _concurrentWrites = 0;
  int maximumConcurrentWrites = 0;

  @override
  DailyTrainingPlan? read() => persisted;

  @override
  Future<void> write(DailyTrainingPlan plan) async {
    writeAttempts += 1;
    _concurrentWrites += 1;
    maximumConcurrentWrites = _concurrentWrites > maximumConcurrentWrites
        ? _concurrentWrites
        : maximumConcurrentWrites;
    try {
      if (writeDelay > Duration.zero) await Future<void>.delayed(writeDelay);
      if (writeAttempts <= failWriteCount) {
        throw StateError('simulated write failure');
      }
      writes.add(plan);
      persisted = plan;
    } finally {
      _concurrentWrites -= 1;
    }
  }
}
