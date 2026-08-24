import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_skill_mastery.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_skill_mastery_provider.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_state.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_teaching_analysis.dart';

void main() {
  group('Nanikiru skill identifiers', () {
    test('are stable and map every teaching tag explicitly', () {
      expect(NanikiruSkillMasteryProfile.schemaVersion, 1);
      expect(NanikiruSkillMasteryProfile.taxonomyVersion, 1);
      expect(NanikiruSkillIds.all, {
        'nanikiru.isolated_tile_handling',
        'nanikiru.taatsu_overload',
        'nanikiru.pair_protection',
        'nanikiru.chiitoitsu_competition',
        'nanikiru.kokushi_tendency',
        'nanikiru.general_tile_efficiency',
      });
      expect(
        NanikiruTeachingTag.values.map((tag) => tag.skillId).toSet(),
        NanikiruSkillIds.all,
      );
    });
  });

  group('NanikiruSkillMastery', () {
    test('uses the required initial value and equal-rating Elo update', () {
      const initial = NanikiruSkillMastery();
      expect(initial.rating, 800);

      final correct = initial.recordAttempt(
        outcome: NaniKiruOutcome.perfect,
        puzzleDifficulty: 800,
        occurredAt: 123,
      );
      expect(correct.rating, 816);
      expect(correct.attempts, 1);
      expect(correct.correct, 1);
      expect(correct.lastAttemptAt, 123);

      final incorrect = initial.recordAttempt(
        outcome: NaniKiruOutcome.incorrect,
        puzzleDifficulty: 800,
        occurredAt: 124,
      );
      expect(incorrect.rating, 784);
      expect(incorrect.incorrect, 1);
    });

    test('applies timeout and skip evidence weights', () {
      const initial = NanikiruSkillMastery();

      final timedOut = initial.recordAttempt(
        outcome: NaniKiruOutcome.timedOut,
        puzzleDifficulty: 800,
        occurredAt: 1,
      );
      final skipped = initial.recordAttempt(
        outcome: NaniKiruOutcome.skipped,
        puzzleDifficulty: 800,
        occurredAt: 1,
      );

      expect(timedOut.rating, 788);
      expect(timedOut.timedOut, 1);
      expect(skipped.rating, 792);
      expect(skipped.skipped, 1);
    });

    test('does not count unanswered attempts', () {
      const initial = NanikiruSkillMastery();
      final result = initial.recordAttempt(
        outcome: NaniKiruOutcome.unanswered,
        puzzleDifficulty: 1600,
        occurredAt: 123,
      );

      expect(identical(result, initial), isTrue);
      expect(result.attempts, 0);
      expect(result.lastAttemptAt, 0);
    });

    test('difficulty changes the Elo gain and loss', () {
      const initial = NanikiruSkillMastery();

      final easyCorrect = initial.recordAttempt(
        outcome: NaniKiruOutcome.perfect,
        puzzleDifficulty: 400,
        occurredAt: 1,
      );
      final hardCorrect = initial.recordAttempt(
        outcome: NaniKiruOutcome.perfect,
        puzzleDifficulty: 1200,
        occurredAt: 1,
      );
      final easyWrong = initial.recordAttempt(
        outcome: NaniKiruOutcome.incorrect,
        puzzleDifficulty: 400,
        occurredAt: 1,
      );
      final hardWrong = initial.recordAttempt(
        outcome: NaniKiruOutcome.incorrect,
        puzzleDifficulty: 1200,
        occurredAt: 1,
      );

      expect(hardCorrect.rating, greaterThan(easyCorrect.rating));
      expect(easyWrong.rating, lessThan(hardWrong.rating));
    });

    test('uses K 32, 24 and 16 at the required attempt boundaries', () {
      NanikiruSkillMastery atAttempts(int attempts) =>
          NanikiruSkillMastery(attempts: attempts);

      expect(
        atAttempts(9)
            .recordAttempt(
              outcome: NaniKiruOutcome.perfect,
              puzzleDifficulty: 800,
              occurredAt: 1,
            )
            .rating,
        816,
      );
      expect(
        atAttempts(10)
            .recordAttempt(
              outcome: NaniKiruOutcome.perfect,
              puzzleDifficulty: 800,
              occurredAt: 1,
            )
            .rating,
        812,
      );
      expect(
        atAttempts(29)
            .recordAttempt(
              outcome: NaniKiruOutcome.perfect,
              puzzleDifficulty: 800,
              occurredAt: 1,
            )
            .rating,
        812,
      );
      expect(
        atAttempts(30)
            .recordAttempt(
              outcome: NaniKiruOutcome.perfect,
              puzzleDifficulty: 800,
              occurredAt: 1,
            )
            .rating,
        808,
      );
    });

    test('clamps ratings to 600 through 1800', () {
      const nearMaximum = NanikiruSkillMastery(rating: 1799);
      const nearMinimum = NanikiruSkillMastery(rating: 601);

      expect(
        nearMaximum
            .recordAttempt(
              outcome: NaniKiruOutcome.perfect,
              puzzleDifficulty: 3000,
              occurredAt: 1,
            )
            .rating,
        1800,
      );
      expect(
        nearMinimum
            .recordAttempt(
              outcome: NaniKiruOutcome.incorrect,
              puzzleDifficulty: 0,
              occurredAt: 1,
            )
            .rating,
        600,
      );
    });

    test('serializes all counters and safely normalizes invalid values', () {
      final parsed = NanikiruSkillMastery.fromJson({
        'rating': 9999,
        'attempts': -2,
        'correct': 3,
        'incorrect': 4,
        'skipped': 5,
        'timedOut': 6,
        'lastAttemptAt': -7,
      });

      expect(parsed.rating, 1800);
      expect(parsed.attempts, 0);
      expect(parsed.correct, 3);
      expect(parsed.incorrect, 4);
      expect(parsed.skipped, 5);
      expect(parsed.timedOut, 6);
      expect(parsed.lastAttemptAt, 0);
      expect(parsed.toJson(), {
        'rating': 1800,
        'attempts': 0,
        'correct': 3,
        'incorrect': 4,
        'skipped': 5,
        'timedOut': 6,
        'lastAttemptAt': 0,
      });
    });
  });

  group('NanikiruSkillMasteryProfile', () {
    test('deduplicates tags and ignores unknown identifiers', () {
      final profile = NanikiruSkillMasteryProfile.empty().recordAttempt(
        skillIds: const [
          NanikiruSkillIds.pairProtection,
          NanikiruSkillIds.pairProtection,
          'nanikiru.future_unknown_skill',
        ],
        outcome: NaniKiruOutcome.perfect,
        puzzleDifficulty: 800,
        occurredAt: 42,
      );

      expect(profile.skills.keys, [NanikiruSkillIds.pairProtection]);
      expect(profile.skill(NanikiruSkillIds.pairProtection)!.attempts, 1);
      expect(profile.updatedAt, 42);
    });

    test('round-trips the versioned schema', () {
      final original = NanikiruSkillMasteryProfile.empty().recordAttempt(
        skillIds: const {
          NanikiruSkillIds.isolatedTileHandling,
          NanikiruSkillIds.generalTileEfficiency,
        },
        outcome: NaniKiruOutcome.timedOut,
        puzzleDifficulty: 1000,
        occurredAt: 987654,
      );
      final json = original.toJson();
      final restored = NanikiruSkillMasteryProfile.fromJson(json);

      expect(json['schemaVersion'], 1);
      expect(json['taxonomyVersion'], 1);
      expect(restored.updatedAt, 987654);
      expect(restored.skills.keys.toSet(), original.skills.keys.toSet());
      for (final skillId in original.skills.keys) {
        expect(restored.skills[skillId]!.toJson(),
            original.skills[skillId]!.toJson());
      }
    });

    test('one malformed skill entry does not discard valid entries', () {
      final profile = NanikiruSkillMasteryProfile.fromJson({
        'schemaVersion': 1,
        'taxonomyVersion': 1,
        'updatedAt': 100,
        'skills': {
          NanikiruSkillIds.taatsuOverload: {
            'rating': 900,
            'attempts': 2,
          },
          NanikiruSkillIds.kokushiTendency: 'broken',
        },
      });

      expect(profile.skills.keys, [NanikiruSkillIds.taatsuOverload]);
      expect(profile.skills[NanikiruSkillIds.taatsuOverload]!.rating, 900);
    });

    test('personalization waits for evidence and returns nearby weak topics',
        () {
      final profile = NanikiruSkillMasteryProfile(
        skills: const {
          NanikiruSkillIds.isolatedTileHandling: NanikiruSkillMastery(
            rating: 650,
            attempts: 2,
          ),
          NanikiruSkillIds.pairProtection: NanikiruSkillMastery(
            rating: 720,
            attempts: 3,
          ),
          NanikiruSkillIds.taatsuOverload: NanikiruSkillMastery(
            rating: 760,
            attempts: 4,
          ),
          NanikiruSkillIds.kokushiTendency: NanikiruSkillMastery(
            rating: 900,
            attempts: 5,
          ),
        },
      );

      expect(profile.weakestTeachingTags(), {
        NanikiruTeachingTag.pairProtection,
        NanikiruTeachingTag.taatsuOverload,
      });
      expect(profile.weakestTeachingTags(maximumSkills: 1), {
        NanikiruTeachingTag.pairProtection,
      });
      expect(
        NanikiruSkillMasteryProfile.empty().weakestTeachingTags(),
        isEmpty,
      );
      expect(
        () => profile.weakestTeachingTags(minimumAttempts: 0),
        throwsRangeError,
      );
    });
  });

  group('NanikiruSkillMasteryNotifier', () {
    test('loads an existing profile from the store', () async {
      final existing = NanikiruSkillMasteryProfile.empty().recordAttempt(
        skillIds: const {NanikiruSkillIds.chiitoitsuCompetition},
        outcome: NaniKiruOutcome.perfect,
        puzzleDifficulty: 800,
        occurredAt: 10,
      );
      final store = _MemoryMasteryStore(existing);
      final container = _containerWith(store);
      addTearDown(container.dispose);

      container.read(nanikiruSkillMasteryProvider);
      await _settleStore(container);

      final state = container.read(nanikiruSkillMasteryProvider);
      expect(
        state.skills[NanikiruSkillIds.chiitoitsuCompetition]!.attempts,
        1,
      );
      expect(store.writes, isEmpty);
    });

    test('replays attempts made before storage is ready onto disk state',
        () async {
      final disk = NanikiruSkillMasteryProfile.empty().recordAttempt(
        skillIds: const {NanikiruSkillIds.generalTileEfficiency},
        outcome: NaniKiruOutcome.perfect,
        puzzleDifficulty: 800,
        occurredAt: 1,
      );
      final store = _MemoryMasteryStore(disk);
      final storeCompleter = Completer<NanikiruSkillMasteryStore>();
      final container = ProviderContainer(overrides: [
        nanikiruSkillMasteryStoreProvider.overrideWith(
          (ref) => storeCompleter.future,
        ),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(nanikiruSkillMasteryProvider.notifier);
      notifier.recordAttempt(
        skillIds: const {NanikiruSkillIds.generalTileEfficiency},
        outcome: NaniKiruOutcome.incorrect,
        puzzleDifficulty: 900,
        occurredAt: 2,
      );
      expect(
        container
            .read(nanikiruSkillMasteryProvider)
            .skills[NanikiruSkillIds.generalTileEfficiency]!
            .attempts,
        1,
      );

      storeCompleter.complete(store);
      await notifier.flush();

      final merged = container.read(nanikiruSkillMasteryProvider);
      expect(
        merged.skills[NanikiruSkillIds.generalTileEfficiency]!.attempts,
        2,
      );
      expect(
        merged.skills[NanikiruSkillIds.generalTileEfficiency]!.correct,
        1,
      );
      expect(
        merged.skills[NanikiruSkillIds.generalTileEfficiency]!.incorrect,
        1,
      );
      expect(store.writes, hasLength(1));
      expect(
        store.writes.single.skills[NanikiruSkillIds.generalTileEfficiency]!
            .attempts,
        2,
      );
    });

    test('serializes rapid writes and persists the newest snapshot last',
        () async {
      final store = _MemoryMasteryStore(
        NanikiruSkillMasteryProfile.empty(),
        writeDelay: const Duration(milliseconds: 1),
      );
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(nanikiruSkillMasteryProvider.notifier);
      await _settleStore(container);

      for (var i = 0; i < 40; i++) {
        notifier.recordAttempt(
          skillIds: const {NanikiruSkillIds.isolatedTileHandling},
          outcome: NaniKiruOutcome.perfect,
          puzzleDifficulty: 1000,
          occurredAt: i + 1,
        );
      }
      await notifier.flush();

      expect(store.maximumConcurrentWrites, 1);
      expect(store.writes.length, lessThan(40));
      expect(
        store.writes.last.skills[NanikiruSkillIds.isolatedTileHandling]!
            .attempts,
        40,
      );
      expect(
        store.persisted.skills[NanikiruSkillIds.isolatedTileHandling]!.attempts,
        40,
      );
    });

    test('flush retries one terminal failure without duplicating an attempt',
        () async {
      final store = _MemoryMasteryStore(
        NanikiruSkillMasteryProfile.empty(),
        failWriteCount: 1,
      );
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(nanikiruSkillMasteryProvider.notifier);
      await _settleStore(container);

      notifier.recordAttempt(
        skillIds: const {NanikiruSkillIds.pairProtection},
        outcome: NaniKiruOutcome.incorrect,
        puzzleDifficulty: 900,
        occurredAt: 1,
      );
      await notifier.flush();

      expect(store.writeAttempts, 2);
      expect(store.writes, hasLength(1));
      expect(
        store.persisted.skills[NanikiruSkillIds.pairProtection]!.attempts,
        1,
      );
    });

    test('persistent failure is explicit and recovery saves latest profile',
        () async {
      final store = _MemoryMasteryStore(
        NanikiruSkillMasteryProfile.empty(),
        failWriteCount: 3,
      );
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(nanikiruSkillMasteryProvider.notifier);
      await _settleStore(container);

      notifier.recordAttempt(
        skillIds: const {NanikiruSkillIds.generalTileEfficiency},
        outcome: NaniKiruOutcome.perfect,
        puzzleDifficulty: 800,
        occurredAt: 1,
      );
      await expectLater(notifier.flush(), throwsStateError);
      expect(store.writeAttempts, 2);
      expect(store.writes, isEmpty);

      notifier.recordAttempt(
        skillIds: const {NanikiruSkillIds.generalTileEfficiency},
        outcome: NaniKiruOutcome.incorrect,
        puzzleDifficulty: 800,
        occurredAt: 2,
      );
      await notifier.flush();

      expect(store.writeAttempts, 4);
      expect(store.writes, hasLength(1));
      final persisted =
          store.persisted.skills[NanikiruSkillIds.generalTileEfficiency]!;
      expect(persisted.attempts, 2);
      expect(persisted.correct, 1);
      expect(persisted.incorrect, 1);
      expect(
        container
            .read(nanikiruSkillMasteryProvider)
            .skills[NanikiruSkillIds.generalTileEfficiency]!
            .attempts,
        2,
      );
    });

    test('does not persist unanswered or unsupported attempts', () async {
      final store = _MemoryMasteryStore(NanikiruSkillMasteryProfile.empty());
      final container = _containerWith(store);
      addTearDown(container.dispose);
      final notifier = container.read(nanikiruSkillMasteryProvider.notifier);
      await _settleStore(container);

      expect(
        notifier.recordAttempt(
          skillIds: const {NanikiruSkillIds.pairProtection},
          outcome: NaniKiruOutcome.unanswered,
          puzzleDifficulty: 800,
        ),
        isFalse,
      );
      expect(
        notifier.recordAttempt(
          skillIds: const {'nanikiru.unknown'},
          outcome: NaniKiruOutcome.perfect,
          puzzleDifficulty: 800,
        ),
        isFalse,
      );
      await notifier.flush();

      expect(container.read(nanikiruSkillMasteryProvider).skills, isEmpty);
      expect(store.writes, isEmpty);
    });
  });
}

ProviderContainer _containerWith(NanikiruSkillMasteryStore store) {
  return ProviderContainer(overrides: [
    nanikiruSkillMasteryStoreProvider.overrideWith((ref) async => store),
  ]);
}

Future<void> _settleStore(ProviderContainer container) async {
  await container.read(nanikiruSkillMasteryStoreProvider.future);
  await Future<void>.delayed(Duration.zero);
}

class _MemoryMasteryStore implements NanikiruSkillMasteryStore {
  _MemoryMasteryStore(
    this.initial, {
    this.writeDelay = Duration.zero,
    int failWriteCount = 0,
  })  : _persisted = initial,
        _remainingWriteFailures = failWriteCount;

  final NanikiruSkillMasteryProfile initial;
  final Duration writeDelay;
  final List<NanikiruSkillMasteryProfile> writes = [];
  NanikiruSkillMasteryProfile _persisted;
  int _remainingWriteFailures;
  int writeAttempts = 0;
  int _concurrentWrites = 0;
  int maximumConcurrentWrites = 0;

  NanikiruSkillMasteryProfile get persisted => _persisted;

  @override
  NanikiruSkillMasteryProfile read() => initial;

  @override
  Future<void> write(NanikiruSkillMasteryProfile profile) async {
    writeAttempts += 1;
    _concurrentWrites += 1;
    if (_concurrentWrites > maximumConcurrentWrites) {
      maximumConcurrentWrites = _concurrentWrites;
    }
    try {
      if (writeDelay > Duration.zero) await Future<void>.delayed(writeDelay);
      if (_remainingWriteFailures > 0) {
        _remainingWriteFailures -= 1;
        throw StateError('simulated write failure');
      }
      writes.add(profile);
      _persisted = profile;
    } finally {
      _concurrentWrites -= 1;
    }
  }
}
