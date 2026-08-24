import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/defense_trainer/data/defense_progress_store.dart';
import 'package:tilezhan/features/defense_trainer/domain/defense_progress.dart';

void main() {
  group('Defense progress taxonomy', () {
    test('uses stable skill identifiers and independent version numbers', () {
      expect(DefenseSkillIds.all, {
        'defense.genbutsu',
        'defense.suji',
        'defense.kabe',
        'defense.honor_visibility',
        'defense.combined',
      });
      expect(DefenseProgressProfile.schemaVersion, 1);
      expect(DefenseProgressProfile.taxonomyVersion, 1);
      expect(DefenseProgressProfile.maximumRecentMistakes, 20);
    });
  });

  group('DefenseSkillStats', () {
    test('tracks outcomes, accuracy, and current/best correct streaks', () {
      var stats = const DefenseSkillStats();
      final outcomes = [
        DefenseAttemptOutcome.correct,
        DefenseAttemptOutcome.correct,
        DefenseAttemptOutcome.incorrect,
        DefenseAttemptOutcome.skipped,
        DefenseAttemptOutcome.timedOut,
        DefenseAttemptOutcome.correct,
      ];
      for (var index = 0; index < outcomes.length; index++) {
        stats = stats.recordAttempt(
          outcome: outcomes[index],
          occurredAt: index + 1,
        );
      }

      expect(stats.correct, 3);
      expect(stats.incorrect, 1);
      expect(stats.skipped, 1);
      expect(stats.timedOut, 1);
      expect(stats.attempts, 6);
      expect(stats.accuracy, 0.5);
      expect(stats.currentCorrectStreak, 1);
      expect(stats.bestCorrectStreak, 2);
      expect(stats.lastAttemptAt, 6);
    });

    test('normalizes damaged counters into possible non-negative state', () {
      final stats = DefenseSkillStats.fromJson({
        'correct': 2,
        'incorrect': -4,
        'skipped': 'bad',
        'timedOut': 1.5,
        'currentCorrectStreak': 9,
        'bestCorrectStreak': -3,
        'lastAttemptAt': -1,
      });

      expect(stats.toJson(), {
        'correct': 2,
        'incorrect': 0,
        'skipped': 0,
        'timedOut': 0,
        'currentCorrectStreak': 2,
        'bestCorrectStreak': 2,
        'lastAttemptAt': 0,
      });
    });
  });

  group('DefenseProgressProfile', () {
    test('round-trips schema one and exposes immutable collections', () {
      final original = DefenseProgressProfile.empty().recordAttempt(
        skillId: DefenseSkillIds.suji,
        questionId: 'defense.suji.001',
        outcome: DefenseAttemptOutcome.incorrect,
        occurredAt: 123,
      );
      final json = original.toJson();
      final restored = DefenseProgressProfile.fromJson(json);

      expect(json['schemaVersion'], 1);
      expect(json['taxonomyVersion'], 1);
      expect(restored.updatedAt, 123);
      expect(restored.skill(DefenseSkillIds.suji)!.incorrect, 1);
      expect(restored.recentMistakes.single.questionId, 'defense.suji.001');
      expect(() => restored.skills.clear(), throwsUnsupportedError);
      expect(() => restored.recentMistakes.clear(), throwsUnsupportedError);
    });

    test('keeps valid siblings while isolating malformed entries', () {
      final profile = DefenseProgressProfile.fromJson({
        'schemaVersion': 1,
        'taxonomyVersion': 1,
        'updatedAt': 500,
        'skills': {
          DefenseSkillIds.genbutsu: {
            'correct': 3,
            'incorrect': 1,
            'currentCorrectStreak': 2,
            'bestCorrectStreak': 2,
          },
          DefenseSkillIds.kabe: 'broken',
          'defense.future_skill': {
            'correct': 4,
          },
        },
        'recentMistakes': [
          {
            'questionId': 'defense.genbutsu.001',
            'occurredAt': 40,
          },
          'broken',
          {
            'questionId': '',
            'occurredAt': 30,
          },
          {
            'questionId': 'defense.suji.001',
            'occurredAt': 'yesterday',
          },
          {
            'questionId': 'defense.honor.001',
            'occurredAt': 20,
          },
        ],
      });

      expect(profile.skills.keys, {
        DefenseSkillIds.genbutsu,
        'defense.future_skill',
      });
      expect(profile.skill(DefenseSkillIds.genbutsu)!.attempts, 4);
      expect(
        profile.recentMistakes.map((mistake) => mistake.questionId),
        ['defense.genbutsu.001', 'defense.honor.001'],
      );
    });

    test('deduplicates recent mistakes by newest occurrence and caps at 20',
        () {
      final rawMistakes = <Map<String, dynamic>>[
        for (var index = 0; index < 25; index++)
          {
            'questionId': 'defense.question.$index',
            'occurredAt': index,
          },
        {
          'questionId': 'defense.question.24',
          'occurredAt': 100,
        },
      ];
      final profile = DefenseProgressProfile.fromJson({
        'schemaVersion': 1,
        'taxonomyVersion': 1,
        'recentMistakes': rawMistakes,
      });

      expect(profile.recentMistakes, hasLength(20));
      expect(profile.recentMistakes.first.questionId, 'defense.question.24');
      expect(profile.recentMistakes.first.occurredAt, 100);
      expect(
        profile.recentMistakes
            .where((mistake) => mistake.questionId == 'defense.question.24'),
        hasLength(1),
      );
    });

    test('moves a repeated mistake to the front and ignores correct answers',
        () {
      var profile = DefenseProgressProfile.empty().recordAttempt(
        skillId: DefenseSkillIds.kabe,
        questionId: 'defense.kabe.001',
        outcome: DefenseAttemptOutcome.incorrect,
        occurredAt: 1,
      );
      profile = profile.recordAttempt(
        skillId: DefenseSkillIds.kabe,
        questionId: 'defense.kabe.002',
        outcome: DefenseAttemptOutcome.timedOut,
        occurredAt: 2,
      );
      profile = profile.recordAttempt(
        skillId: DefenseSkillIds.kabe,
        questionId: 'defense.kabe.001',
        outcome: DefenseAttemptOutcome.skipped,
        occurredAt: 3,
      );
      profile = profile.recordAttempt(
        skillId: DefenseSkillIds.kabe,
        questionId: 'defense.kabe.001',
        outcome: DefenseAttemptOutcome.correct,
        occurredAt: 4,
      );
      profile = profile.recordAttempt(
        skillId: DefenseSkillIds.kabe,
        questionId: 'defense.kabe.001',
        outcome: DefenseAttemptOutcome.incorrect,
        occurredAt: 2,
      );

      expect(
        profile.recentMistakes.map((mistake) => mistake.questionId),
        ['defense.kabe.001', 'defense.kabe.002'],
      );
      expect(profile.recentMistakes.first.occurredAt, 3);
    });

    test('ignores unsupported skill identifiers without changing state', () {
      final profile = DefenseProgressProfile.empty();
      final unchanged = profile.recordAttempt(
        skillId: 'defense.unknown',
        questionId: 'defense.unknown.001',
        outcome: DefenseAttemptOutcome.correct,
        occurredAt: 1,
      );

      expect(identical(unchanged, profile), isTrue);
    });

    test('future schema or taxonomy is read-only and cannot serialize', () {
      for (final json in [
        {
          'schemaVersion': 2,
          'taxonomyVersion': 1,
        },
        {
          'schemaVersion': 1,
          'taxonomyVersion': 2,
        },
      ]) {
        var profile = DefenseProgressProfile.fromJson(json);
        expect(profile.isReadOnly, isTrue);
        profile = profile.recordAttempt(
          skillId: DefenseSkillIds.combined,
          questionId: 'defense.combined.001',
          outcome: DefenseAttemptOutcome.correct,
          occurredAt: 10,
        );
        expect(profile.skill(DefenseSkillIds.combined)!.correct, 1);
        expect(profile.isReadOnly, isTrue);
        expect(profile.toJson, throwsStateError);
      }
    });

    test('missing or malformed root version safely starts clean', () {
      expect(DefenseProgressProfile.fromJson(const {}).skills, isEmpty);
      expect(
        DefenseProgressProfile.fromJson(const {
          'schemaVersion': 'one',
          'skills': {
            DefenseSkillIds.genbutsu: {'correct': 999},
          },
        }).skills,
        isEmpty,
      );
    });
  });

  group('DefenseProgressNotifier', () {
    test('loads an existing profile without writing it back', () async {
      final existing = DefenseProgressProfile.empty().recordAttempt(
        skillId: DefenseSkillIds.honorVisibility,
        questionId: 'defense.honor.001',
        outcome: DefenseAttemptOutcome.correct,
        occurredAt: 1,
      );
      final store = _MemoryStore(existing);
      final container = _containerWith(store);
      addTearDown(container.dispose);

      container.read(defenseProgressProvider);
      await _settleStore(container);

      expect(
        container
            .read(defenseProgressProvider)
            .skill(DefenseSkillIds.honorVisibility)!
            .correct,
        1,
      );
      expect(store.writes, isEmpty);
    });

    test('replays pre-storage events onto disk state before one write',
        () async {
      final disk = DefenseProgressProfile.empty().recordAttempt(
        skillId: DefenseSkillIds.genbutsu,
        questionId: 'defense.genbutsu.001',
        outcome: DefenseAttemptOutcome.correct,
        occurredAt: 1,
      );
      final store = _MemoryStore(disk);
      final completer = Completer<DefenseProgressStore>();
      final container = ProviderContainer(overrides: [
        defenseProgressStoreProvider.overrideWith((ref) => completer.future),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(defenseProgressProvider.notifier);

      notifier.recordAttempt(
        skillId: DefenseSkillIds.genbutsu,
        questionId: 'defense.genbutsu.002',
        outcome: DefenseAttemptOutcome.incorrect,
        occurredAt: 2,
      );
      completer.complete(store);
      await notifier.flush();

      final merged = container.read(defenseProgressProvider);
      expect(merged.skill(DefenseSkillIds.genbutsu)!.attempts, 2);
      expect(merged.skill(DefenseSkillIds.genbutsu)!.correct, 1);
      expect(merged.skill(DefenseSkillIds.genbutsu)!.incorrect, 1);
      expect(store.writes, hasLength(1));
      expect(store.writes.single.skill(DefenseSkillIds.genbutsu)!.attempts, 2);
    });

    test('serializes rapid writes and persists the newest snapshot last',
        () async {
      final store = _MemoryStore(
        DefenseProgressProfile.empty(),
        writeDelay: const Duration(milliseconds: 1),
      );
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(defenseProgressProvider.notifier);
      await _settleStore(container);

      for (var index = 0; index < 40; index++) {
        notifier.recordAttempt(
          skillId: DefenseSkillIds.suji,
          questionId: 'defense.suji.$index',
          outcome: DefenseAttemptOutcome.correct,
          occurredAt: index + 1,
        );
      }
      await notifier.flush();

      expect(store.maximumConcurrentWrites, 1);
      expect(store.writes.length, lessThan(40));
      expect(store.writes.last.skill(DefenseSkillIds.suji)!.attempts, 40);
      expect(store.persisted.skill(DefenseSkillIds.suji)!.attempts, 40);
    });

    test('flush retries a terminal dirty snapshot with no later attempt',
        () async {
      final store = _MemoryStore(
        DefenseProgressProfile.empty(),
        failWriteCount: 1,
      );
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(defenseProgressProvider.notifier);
      await _settleStore(container);

      notifier.recordAttempt(
        skillId: DefenseSkillIds.kabe,
        questionId: 'defense.kabe.001.v1',
        outcome: DefenseAttemptOutcome.incorrect,
        occurredAt: 1,
      );
      await notifier.flush();

      expect(store.writeAttempts, 2);
      expect(store.writes, hasLength(1));
      expect(store.persisted.skill(DefenseSkillIds.kabe)!.incorrect, 1);
    });

    test('persistent failure is explicit and a later flush can recover',
        () async {
      final store = _MemoryStore(
        DefenseProgressProfile.empty(),
        failWriteCount: 2,
      );
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(defenseProgressProvider.notifier);
      await _settleStore(container);

      notifier.recordAttempt(
        skillId: DefenseSkillIds.combined,
        questionId: 'defense.combined.001.v1',
        outcome: DefenseAttemptOutcome.correct,
        occurredAt: 1,
      );

      await expectLater(notifier.flush(), throwsStateError);
      expect(store.writeAttempts, 2);
      expect(store.writes, isEmpty);

      await notifier.flush();
      expect(store.writeAttempts, 3);
      expect(store.persisted.skill(DefenseSkillIds.combined)!.correct, 1);
    });

    test('flush waits for attempts appended while a write is in flight',
        () async {
      final firstWriteGate = Completer<void>();
      final store = _MemoryStore(
        DefenseProgressProfile.empty(),
        firstWriteGate: firstWriteGate,
      );
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(defenseProgressProvider.notifier);
      await _settleStore(container);

      notifier.recordAttempt(
        skillId: DefenseSkillIds.genbutsu,
        questionId: 'defense.genbutsu.001.v1',
        outcome: DefenseAttemptOutcome.correct,
        occurredAt: 1,
      );
      expect(store.writeAttempts, 1);
      var flushCompleted = false;
      final flushFuture = notifier.flush().then((_) => flushCompleted = true);
      notifier.recordAttempt(
        skillId: DefenseSkillIds.genbutsu,
        questionId: 'defense.genbutsu.002.v1',
        outcome: DefenseAttemptOutcome.incorrect,
        occurredAt: 2,
      );
      await Future<void>.delayed(Duration.zero);
      expect(flushCompleted, isFalse);

      firstWriteGate.complete();
      await flushFuture;

      expect(store.writeAttempts, 2);
      expect(store.maximumConcurrentWrites, 1);
      expect(store.persisted.skill(DefenseSkillIds.genbutsu)!.attempts, 2);
    });

    test('future schema remains usable in memory but is never overwritten',
        () async {
      final future = DefenseProgressProfile.fromJson(const {
        'schemaVersion': 2,
        'taxonomyVersion': 1,
      });
      final store = _MemoryStore(future);
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(defenseProgressProvider.notifier);
      await _settleStore(container);

      expect(
        notifier.recordAttempt(
          skillId: DefenseSkillIds.combined,
          questionId: 'defense.combined.001',
          outcome: DefenseAttemptOutcome.correct,
          occurredAt: 1,
        ),
        isTrue,
      );
      await notifier.flush();

      final state = container.read(defenseProgressProvider);
      expect(state.isReadOnly, isTrue);
      expect(state.skill(DefenseSkillIds.combined)!.correct, 1);
      expect(store.writes, isEmpty);
      expect(store.writeAttempts, 0);
    });

    test('unsupported skills do not update or write', () async {
      final store = _MemoryStore(DefenseProgressProfile.empty());
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(defenseProgressProvider.notifier);
      await _settleStore(container);

      expect(
        notifier.recordAttempt(
          skillId: 'defense.unknown',
          questionId: 'defense.unknown.001',
          outcome: DefenseAttemptOutcome.correct,
        ),
        isFalse,
      );
      await notifier.flush();

      expect(container.read(defenseProgressProvider).skills, isEmpty);
      expect(store.writes, isEmpty);
    });
  });

  test('in-memory adapter and storage key are independently versioned',
      () async {
    final store = InMemoryDefenseProgressStore();
    final updated = store.read().recordAttempt(
          skillId: DefenseSkillIds.kabe,
          questionId: 'defense.kabe.001',
          outcome: DefenseAttemptOutcome.correct,
          occurredAt: 1,
        );

    await store.write(updated);

    expect(store.read().skill(DefenseSkillIds.kabe)!.correct, 1);
    expect(
        StorageServiceDefenseProgressStore.storageKey, 'defense_progress_v1');
  });
}

ProviderContainer _containerWith(DefenseProgressStore store) {
  return ProviderContainer(overrides: [
    defenseProgressStoreProvider.overrideWith((ref) async => store),
  ]);
}

Future<void> _settleStore(ProviderContainer container) async {
  await container.read(defenseProgressStoreProvider.future);
  await Future<void>.delayed(Duration.zero);
}

class _MemoryStore implements DefenseProgressStore {
  _MemoryStore(
    DefenseProgressProfile initial, {
    this.writeDelay = Duration.zero,
    this.failWriteCount = 0,
    this.firstWriteGate,
  }) : persisted = initial;

  final Duration writeDelay;
  final int failWriteCount;
  final Completer<void>? firstWriteGate;
  final List<DefenseProgressProfile> writes = [];
  DefenseProgressProfile persisted;
  int writeAttempts = 0;
  int _concurrentWrites = 0;
  int maximumConcurrentWrites = 0;

  @override
  DefenseProgressProfile read() => persisted;

  @override
  Future<void> write(DefenseProgressProfile profile) async {
    writeAttempts += 1;
    _concurrentWrites += 1;
    maximumConcurrentWrites = mathMax(
      maximumConcurrentWrites,
      _concurrentWrites,
    );
    try {
      if (writeAttempts == 1 && firstWriteGate != null) {
        await firstWriteGate!.future;
      }
      if (writeDelay > Duration.zero) await Future<void>.delayed(writeDelay);
      if (writeAttempts <= failWriteCount) {
        throw StateError('simulated write failure');
      }
      writes.add(profile);
      persisted = profile;
    } finally {
      _concurrentWrites -= 1;
    }
  }
}

int mathMax(int left, int right) => left > right ? left : right;
