import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/srs/srs_item.dart';
import 'package:tilezhan/features/defense_trainer/domain/defense_progress.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_skill_mastery.dart';
import 'package:tilezhan/features/training_plan/domain/training_plan.dart';
import 'package:tilezhan/features/training_plan/domain/training_plan_generator.dart';
import 'package:tilezhan/features/training_plan/domain/weakness_recommender.dart';

void main() {
  group('WeaknessRecommender', () {
    test('requires three attempts and ignores unknown taxonomy entries', () {
      final recommendation = WeaknessRecommender.recommend(
        nanikiruMastery: NanikiruSkillMasteryProfile(
          skills: {
            NanikiruSkillIds.generalTileEfficiency:
                const NanikiruSkillMastery(attempts: 2, correct: 0),
            'nanikiru.future_skill':
                const NanikiruSkillMastery(attempts: 99, correct: 0),
          },
        ),
        defenseProgress: DefenseProgressProfile(
          skills: {
            DefenseSkillIds.suji: const DefenseSkillStats(incorrect: 2),
            'defense.future_skill': const DefenseSkillStats(incorrect: 99),
          },
        ),
      );

      expect(recommendation, isNull);
    });

    test('does not label sufficiently observed perfect performance as weak',
        () {
      final recommendation = WeaknessRecommender.recommend(
        nanikiruMastery: NanikiruSkillMasteryProfile(
          skills: {
            NanikiruSkillIds.generalTileEfficiency:
                const NanikiruSkillMastery(attempts: 3, correct: 3),
          },
        ),
        defenseProgress: DefenseProgressProfile(
          skills: {
            DefenseSkillIds.suji: const DefenseSkillStats(correct: 3),
          },
        ),
      );

      expect(recommendation, isNull);
    });

    test('uses the required accuracy and confidence priority formula', () {
      final recommendation = WeaknessRecommender.recommend(
        nanikiruMastery: NanikiruSkillMasteryProfile(
          skills: {
            NanikiruSkillIds.pairProtection: const NanikiruSkillMastery(
              attempts: 5,
              correct: 2,
              incorrect: 3,
              lastAttemptAt: 50,
            ),
          },
        ),
        defenseProgress: DefenseProgressProfile.empty(),
      )!;

      expect(recommendation.accuracy, closeTo(0.4, 1e-12));
      expect(recommendation.confidence, closeTo(0.5, 1e-12));
      expect(recommendation.priority, closeTo(0.3, 1e-12));
      expect(recommendation.module, TrainingModule.nanikiru);
      expect(recommendation.skillId, NanikiruSkillIds.pairProtection);
    });

    test('breaks equal priority by more attempts', () {
      final recommendation = WeaknessRecommender.recommend(
        nanikiruMastery: NanikiruSkillMasteryProfile(
          skills: {
            NanikiruSkillIds.isolatedTileHandling: const NanikiruSkillMastery(
              attempts: 8,
              correct: 4,
              incorrect: 4,
              lastAttemptAt: 100,
            ),
          },
        ),
        defenseProgress: DefenseProgressProfile(
          skills: {
            DefenseSkillIds.suji: const DefenseSkillStats(
              incorrect: 4,
              lastAttemptAt: 200,
            ),
          },
        ),
      )!;

      // Both priorities are 0.4. Eight observations win over four.
      expect(recommendation.skillId, NanikiruSkillIds.isolatedTileHandling);
    });

    test('then breaks ties by recency and stable skill ID', () {
      final rankedByRecency = WeaknessRecommender.rank(
        nanikiruMastery: NanikiruSkillMasteryProfile.empty(),
        defenseProgress: DefenseProgressProfile(
          skills: {
            DefenseSkillIds.genbutsu: const DefenseSkillStats(
              correct: 1,
              incorrect: 3,
              lastAttemptAt: 100,
            ),
            DefenseSkillIds.kabe: const DefenseSkillStats(
              correct: 1,
              incorrect: 3,
              lastAttemptAt: 200,
            ),
          },
        ),
      );
      expect(rankedByRecency.first.skillId, DefenseSkillIds.kabe);

      final rankedById = WeaknessRecommender.rank(
        nanikiruMastery: NanikiruSkillMasteryProfile.empty(),
        defenseProgress: DefenseProgressProfile(
          skills: {
            DefenseSkillIds.genbutsu: const DefenseSkillStats(
              correct: 1,
              incorrect: 3,
              lastAttemptAt: 200,
            ),
            DefenseSkillIds.kabe: const DefenseSkillStats(
              correct: 1,
              incorrect: 3,
              lastAttemptAt: 200,
            ),
          },
        ),
      );
      expect(
        rankedById.map((item) => item.skillId),
        [DefenseSkillIds.genbutsu, DefenseSkillIds.kabe],
      );
    });
  });

  group('TrainingPlanGenerator', () {
    const generator = TrainingPlanGenerator();
    final now = DateTime(2026, 8, 24, 12);

    test('new user receives the fixed three-task starter plan', () {
      final plan = generator.generate(
        now: now,
        inputs: TrainingPlanInputs(
          srsItems: const {},
          nanikiruMastery: NanikiruSkillMasteryProfile.empty(),
          defenseProgress: DefenseProgressProfile.empty(),
        ),
      );

      expect(plan.localDateKey, '2026-08-24');
      expect(plan.tasks, hasLength(3));
      expect(
        plan.tasks.map((task) => task.id),
        [
          TrainingPlanGenerator.starterFlashcardTaskId,
          TrainingPlanGenerator.yakuExplorationTaskId,
          TrainingPlanGenerator.dailyNanikiruTaskId,
        ],
      );
      expect(
        plan.tasks.map((task) => task.kind),
        [
          TrainingTaskKind.starterLesson,
          TrainingTaskKind.exploration,
          TrainingTaskKind.dailyChallenge,
        ],
      );
      expect(
        plan.tasks.map((task) => task.module),
        [
          TrainingModule.flashcard,
          TrainingModule.yaku,
          TrainingModule.nanikiru,
        ],
      );
      expect(plan.tasks.map((task) => task.targetAttempts), [3, 3, 3]);
      expect(plan.tasks.every((task) => task.focusSkillId == null), isTrue);
    });

    test('zero-attempt profile entries are still no learning evidence', () {
      expect(
        TrainingPlanGenerator.isCompletelyNew(
          TrainingPlanInputs(
            srsItems: const {},
            nanikiruMastery: NanikiruSkillMasteryProfile(
              skills: {
                NanikiruSkillIds.generalTileEfficiency:
                    const NanikiruSkillMastery(),
              },
            ),
            defenseProgress: DefenseProgressProfile(
              skills: {
                DefenseSkillIds.suji: const DefenseSkillStats(),
              },
            ),
          ),
        ),
        isTrue,
      );
    });

    test('returning user without due items or weakness gets explorations', () {
      final plan = generator.generate(
        now: now,
        inputs: TrainingPlanInputs(
          srsItems: {
            'future': SrsItem(
              itemId: 'future',
              type: 'flashcard',
              nextReviewAt: now.millisecondsSinceEpoch + 1,
            ),
          },
          nanikiruMastery: NanikiruSkillMasteryProfile.empty(),
          defenseProgress: DefenseProgressProfile.empty(),
        ),
      );

      expect(
        plan.tasks.map((task) => task.id),
        [
          TrainingPlanGenerator.yakuExplorationTaskId,
          TrainingPlanGenerator.defenseExplorationTaskId,
          TrainingPlanGenerator.dailyNanikiruTaskId,
        ],
      );
      expect(plan.tasks.map((task) => task.targetAttempts), [3, 3, 3]);
    });

    test('due SRS includes equality and caps the first slot at five', () {
      final items = <String, SrsItem>{
        for (var index = 0; index < 6; index++)
          'due-$index': SrsItem(
            itemId: 'due-$index',
            type: 'flashcard',
            nextReviewAt: now.millisecondsSinceEpoch - index,
          ),
        'future': SrsItem(
          itemId: 'future',
          type: 'flashcard',
          nextReviewAt: now.millisecondsSinceEpoch + 1,
        ),
      };

      expect(
        TrainingPlanGenerator.countDueSrs(
          srsItems: items,
          nowMilliseconds: now.millisecondsSinceEpoch,
        ),
        6,
      );
      final plan = generator.generate(
        now: now,
        inputs: TrainingPlanInputs(
          srsItems: items,
          nanikiruMastery: NanikiruSkillMasteryProfile.empty(),
          defenseProgress: DefenseProgressProfile.empty(),
        ),
      );

      expect(plan.tasks.first.kind, TrainingTaskKind.dueReview);
      expect(plan.tasks.first.module, TrainingModule.review);
      expect(plan.tasks.first.targetAttempts, 5);
    });

    test('creates a three-attempt focused Nanikiru weak-skill slot', () {
      final plan = generator.generate(
        now: now,
        inputs: TrainingPlanInputs(
          srsItems: _returningEvidence(now),
          nanikiruMastery: NanikiruSkillMasteryProfile(
            skills: {
              NanikiruSkillIds.taatsuOverload: const NanikiruSkillMastery(
                attempts: 3,
                incorrect: 3,
                lastAttemptAt: 300,
              ),
            },
          ),
          defenseProgress: DefenseProgressProfile(
            skills: {
              DefenseSkillIds.suji: const DefenseSkillStats(
                correct: 9,
                incorrect: 1,
                lastAttemptAt: 400,
              ),
            },
          ),
        ),
      );

      final task = plan.tasks[1];
      expect(task.kind, TrainingTaskKind.weakSkill);
      expect(task.module, TrainingModule.nanikiru);
      expect(task.targetAttempts, 3);
      expect(task.focusSkillId, NanikiruSkillIds.taatsuOverload);
    });

    test('creates a two-attempt focused defense weak-skill slot', () {
      final plan = generator.generate(
        now: now,
        inputs: TrainingPlanInputs(
          srsItems: _returningEvidence(now),
          nanikiruMastery: NanikiruSkillMasteryProfile(
            skills: {
              NanikiruSkillIds.pairProtection: const NanikiruSkillMastery(
                attempts: 10,
                correct: 9,
                incorrect: 1,
                lastAttemptAt: 400,
              ),
            },
          ),
          defenseProgress: DefenseProgressProfile(
            skills: {
              DefenseSkillIds.kabe: const DefenseSkillStats(
                incorrect: 3,
                lastAttemptAt: 300,
              ),
            },
          ),
        ),
      );

      final task = plan.tasks[1];
      expect(task.kind, TrainingTaskKind.weakSkill);
      expect(task.module, TrainingModule.defense);
      expect(task.targetAttempts, 2);
      expect(task.focusSkillId, DefenseSkillIds.kabe);
    });

    test('uses forNewDay and carries a consecutive completed streak', () {
      final previous = DailyTrainingPlan(
        localDate: DateTime(2026, 8, 23),
        tasks: [
          TrainingPlanTask(
            id: 'previous-task',
            kind: TrainingTaskKind.exploration,
            module: TrainingModule.yaku,
            targetAttempts: 1,
            completedAttempts: 1,
          ),
        ],
        currentStreak: 4,
        bestStreak: 6,
        lastCompletedDate: '2026-08-23',
        completedAt: DateTime(2026, 8, 23, 12).millisecondsSinceEpoch,
      );

      final plan = generator.generate(
        now: now,
        inputs: TrainingPlanInputs(
          srsItems: _returningEvidence(now),
          nanikiruMastery: NanikiruSkillMasteryProfile.empty(),
          defenseProgress: DefenseProgressProfile.empty(),
        ),
        previous: previous,
      );

      expect(plan.currentStreak, 4);
      expect(plan.bestStreak, 6);
      expect(plan.lastCompletedDate, '2026-08-23');
      expect(plan.completedAt, 0);
      expect(plan.acceptedEventIds, isEmpty);
      expect(plan.tasks.every((task) => task.completedAttempts == 0), isTrue);
    });
  });
}

Map<String, SrsItem> _returningEvidence(DateTime now) => {
      'future': SrsItem(
        itemId: 'future',
        type: 'flashcard',
        nextReviewAt: now.millisecondsSinceEpoch + 1,
      ),
    };
