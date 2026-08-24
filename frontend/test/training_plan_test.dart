import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/training_plan/domain/training_plan.dart';

void main() {
  group('TrainingPlanTask', () {
    test('uses stable storage identifiers and caps completed attempts', () {
      final task = TrainingPlanTask(
        id: 'starter:flashcard',
        kind: TrainingTaskKind.starterLesson,
        module: TrainingModule.flashcard,
        targetAttempts: 3,
        completedAttempts: 99,
      );

      expect(task.completedAttempts, 3);
      expect(task.isComplete, isTrue);
      expect(task.toJson(), {
        'id': 'starter:flashcard',
        'kind': 'starter_lesson',
        'module': 'flashcard',
        'targetAttempts': 3,
        'completedAttempts': 3,
      });
    });

    test('isolates malformed persisted tasks', () {
      expect(TrainingPlanTask.tryFromJson('broken'), isNull);
      expect(
        TrainingPlanTask.tryFromJson({
          'id': 'bad-target',
          'kind': 'exploration',
          'module': 'yaku',
          'targetAttempts': 0,
        }),
        isNull,
      );
      expect(
        TrainingPlanTask.tryFromJson({
          'id': 'valid',
          'kind': 'exploration',
          'module': 'yaku',
          'targetAttempts': 3,
          'completedAttempts': -4,
        })!
            .completedAttempts,
        0,
      );
    });
  });

  group('DailyTrainingPlan', () {
    final day = DateTime(2026, 8, 24, 10);

    DailyTrainingPlan threeTaskPlan({DailyTrainingPlan? previous}) {
      return DailyTrainingPlan.forNewDay(
        localDate: day,
        previous: previous,
        tasks: [
          TrainingPlanTask(
            id: 'due-review',
            kind: TrainingTaskKind.dueReview,
            module: TrainingModule.review,
            targetAttempts: 1,
          ),
          TrainingPlanTask(
            id: 'weak:defense.suji',
            kind: TrainingTaskKind.weakSkill,
            module: TrainingModule.defense,
            targetAttempts: 1,
            focusSkillId: 'defense.suji',
          ),
          TrainingPlanTask(
            id: 'daily:nanikiru',
            kind: TrainingTaskKind.dailyChallenge,
            module: TrainingModule.nanikiru,
            targetAttempts: 1,
          ),
        ],
      );
    }

    test(
        'one event advances at most one matching task and duplicate is ignored',
        () {
      var plan = threeTaskPlan();
      final review = TrainingAttemptEvent(
        eventId: 'review-1',
        module: TrainingModule.yaku,
        occurredAt: day.millisecondsSinceEpoch,
        isReview: true,
      );

      plan = plan.recordAcceptedAttempt(review);
      final duplicate = plan.recordAcceptedAttempt(review);

      expect(plan.tasks[0].completedAttempts, 1);
      expect(plan.tasks[1].completedAttempts, 0);
      expect(plan.acceptedEventIds, ['review-1']);
      expect(identical(duplicate, plan), isTrue);
    });

    test('weak task requires the matching evidence skill', () {
      var plan = threeTaskPlan();
      final unrelated = TrainingAttemptEvent(
        eventId: 'defense-1',
        module: TrainingModule.defense,
        occurredAt: day.millisecondsSinceEpoch,
        skillIds: const ['defense.kabe'],
      );
      expect(
        identical(plan.recordAcceptedAttempt(unrelated), plan),
        isTrue,
      );

      plan = plan.recordAcceptedAttempt(
        TrainingAttemptEvent(
          eventId: 'defense-2',
          module: TrainingModule.defense,
          occurredAt: day.millisecondsSinceEpoch + 1,
          skillIds: const ['defense.suji'],
        ),
      );
      expect(plan.tasks[1].completedAttempts, 1);
    });

    test('review and daily modes cannot accidentally advance ordinary tasks',
        () {
      final plan = DailyTrainingPlan(
        localDate: day,
        tasks: [
          TrainingPlanTask(
            id: 'explore:yaku',
            kind: TrainingTaskKind.exploration,
            module: TrainingModule.yaku,
            targetAttempts: 2,
          ),
        ],
      );

      final review = plan.recordAcceptedAttempt(
        TrainingAttemptEvent(
          eventId: 'review',
          module: TrainingModule.yaku,
          occurredAt: day.millisecondsSinceEpoch,
          isReview: true,
        ),
      );
      final daily = plan.recordAcceptedAttempt(
        TrainingAttemptEvent(
          eventId: 'daily',
          module: TrainingModule.nanikiru,
          occurredAt: day.millisecondsSinceEpoch,
          isDailyChallenge: true,
        ),
      );

      expect(identical(review, plan), isTrue);
      expect(identical(daily, plan), isTrue);
    });

    test('completion increments learning streak only once per local day', () {
      var plan = threeTaskPlan();
      final events = [
        TrainingAttemptEvent(
          eventId: 'review',
          module: TrainingModule.flashcard,
          occurredAt: day.millisecondsSinceEpoch,
          isReview: true,
        ),
        TrainingAttemptEvent(
          eventId: 'defense',
          module: TrainingModule.defense,
          occurredAt: day.millisecondsSinceEpoch + 1,
          skillIds: const ['defense.suji'],
        ),
        TrainingAttemptEvent(
          eventId: 'daily',
          module: TrainingModule.nanikiru,
          occurredAt: day.millisecondsSinceEpoch + 2,
          isDailyChallenge: true,
        ),
      ];
      for (final event in events) {
        plan = plan.recordAcceptedAttempt(event);
      }

      expect(plan.isComplete, isTrue);
      expect(plan.currentStreak, 1);
      expect(plan.bestStreak, 1);
      expect(plan.lastCompletedDate, '2026-08-24');

      final ignored = plan.recordAcceptedAttempt(
        TrainingAttemptEvent(
          eventId: 'extra',
          module: TrainingModule.nanikiru,
          occurredAt: day.millisecondsSinceEpoch + 3,
          isDailyChallenge: true,
        ),
      );
      expect(identical(ignored, plan), isTrue);
      expect(ignored.currentStreak, 1);
    });

    test('consecutive day advances streak and missed day resets current only',
        () {
      final completedDayOne = DailyTrainingPlan(
        localDate: DateTime(2026, 1, 31),
        tasks: [
          TrainingPlanTask(
            id: 'one',
            kind: TrainingTaskKind.exploration,
            module: TrainingModule.yaku,
            targetAttempts: 1,
          ),
        ],
      ).recordAcceptedAttempt(
        TrainingAttemptEvent(
          eventId: 'one',
          module: TrainingModule.yaku,
          occurredAt: DateTime(2026, 1, 31, 12).millisecondsSinceEpoch,
        ),
      );

      var dayTwo = DailyTrainingPlan.forNewDay(
        localDate: DateTime(2026, 2, 1),
        previous: completedDayOne,
        tasks: [
          TrainingPlanTask(
            id: 'two',
            kind: TrainingTaskKind.exploration,
            module: TrainingModule.yaku,
            targetAttempts: 1,
          ),
        ],
      );
      expect(dayTwo.currentStreak, 1);
      dayTwo = dayTwo.recordAcceptedAttempt(
        TrainingAttemptEvent(
          eventId: 'two',
          module: TrainingModule.yaku,
          occurredAt: DateTime(2026, 2, 1, 12).millisecondsSinceEpoch,
        ),
      );
      expect(dayTwo.currentStreak, 2);
      expect(dayTwo.bestStreak, 2);

      final afterGap = DailyTrainingPlan.forNewDay(
        localDate: DateTime(2026, 2, 3),
        previous: dayTwo,
        tasks: [
          TrainingPlanTask(
            id: 'three',
            kind: TrainingTaskKind.exploration,
            module: TrainingModule.yaku,
            targetAttempts: 1,
          ),
        ],
      );
      expect(afterGap.currentStreak, 0);
      expect(afterGap.bestStreak, 2);
    });

    test('round-trips a fixed plan and isolates damaged sibling tasks', () {
      var plan = threeTaskPlan();
      plan = plan.recordAcceptedAttempt(
        TrainingAttemptEvent(
          eventId: 'review',
          module: TrainingModule.flashcard,
          occurredAt: day.millisecondsSinceEpoch,
          isReview: true,
        ),
      );
      final json = plan.toJson();
      final persistedTasks = <Object?>[...(json['tasks'] as List)];
      persistedTasks.insert(1, 'damaged');
      json['tasks'] = persistedTasks;
      final restored = DailyTrainingPlan.tryFromJson(json)!;

      expect(restored.tasks, hasLength(3));
      expect(restored.tasks.first.completedAttempts, 1);
      expect(restored.acceptedEventIds, ['review']);
      expect(restored.toJson()['schemaVersion'], 1);
      expect(restored.toJson()['planVersion'], 1);
    });

    test('future schema remains read-only and cannot serialize', () {
      final future = DailyTrainingPlan.tryFromJson({
        'schemaVersion': 2,
        'planVersion': 1,
        'localDate': '2026-08-24',
        'currentStreak': 4,
        'bestStreak': 7,
      })!;

      expect(future.isReadOnly, isTrue);
      expect(future.currentStreak, 4);
      expect(future.bestStreak, 7);
      expect(future.toJson, throwsStateError);

      final sessionPlan = DailyTrainingPlan.forNewDay(
        localDate: day,
        previous: future,
        tasks: [
          TrainingPlanTask(
            id: 'session-only',
            kind: TrainingTaskKind.exploration,
            module: TrainingModule.yaku,
            targetAttempts: 1,
          ),
        ],
      );
      expect(sessionPlan.isReadOnly, isTrue);
      expect(sessionPlan.tasks, hasLength(1));
      expect(sessionPlan.toJson, throwsStateError);
    });

    test('events from another local day are ignored', () {
      final plan = threeTaskPlan();
      final event = TrainingAttemptEvent(
        eventId: 'tomorrow',
        module: TrainingModule.flashcard,
        occurredAt: DateTime(2026, 8, 25).millisecondsSinceEpoch,
        isReview: true,
      );
      expect(identical(plan.recordAcceptedAttempt(event), plan), isTrue);
    });
  });

  test('date helpers handle month and year boundaries in local time', () {
    expect(trainingDateKey(DateTime(2026, 1, 2)), '2026-01-02');
    expect(previousDateKey(DateTime(2026, 3, 1)), '2026-02-28');
    expect(previousDateKey(DateTime(2027, 1, 1)), '2026-12-31');
  });
}
