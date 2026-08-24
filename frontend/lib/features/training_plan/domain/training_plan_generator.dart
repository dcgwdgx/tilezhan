import '../../../core/srs/srs_item.dart';
import '../../defense_trainer/domain/defense_progress.dart';
import '../../nanikiru/domain/nanikiru_skill_mastery.dart';
import 'training_plan.dart';
import 'weakness_recommender.dart';

/// Current learning evidence used to choose a new day's fixed tasks.
class TrainingPlanInputs {
  const TrainingPlanInputs({
    required this.srsItems,
    required this.nanikiruMastery,
    required this.defenseProgress,
  });

  final Map<String, SrsItem> srsItems;
  final NanikiruSkillMasteryProfile nanikiruMastery;
  final DefenseProgressProfile defenseProgress;
}

/// Builds the three fixed tasks for a new local training day.
///
/// The caller must reuse a persisted plan whose [DailyTrainingPlan.localDateKey]
/// already matches today. This generator deliberately creates a fresh plan;
/// fixing the selected tasks for the rest of the day is the store's job.
class TrainingPlanGenerator {
  const TrainingPlanGenerator();

  static const starterFlashcardTaskId = 'training.starter.flashcard.v1';
  static const yakuExplorationTaskId = 'training.exploration.yaku.v1';
  static const dueReviewTaskId = 'training.review.due.v1';
  static const defenseExplorationTaskId = 'training.exploration.defense.v1';
  static const dailyNanikiruTaskId = 'training.daily.nanikiru.v1';

  static const maximumDueReviews = 5;

  DailyTrainingPlan generate({
    required DateTime now,
    required TrainingPlanInputs inputs,
    DailyTrainingPlan? previous,
  }) {
    final tasks = isCompletelyNew(inputs)
        ? _newUserTasks()
        : _returningUserTasks(
            now: now,
            inputs: inputs,
          );

    return DailyTrainingPlan.forNewDay(
      localDate: now,
      tasks: tasks,
      previous: previous,
    );
  }

  /// A user is new until none of the three authoritative learning sources
  /// contains evidence of an accepted answer.
  static bool isCompletelyNew(TrainingPlanInputs inputs) {
    if (inputs.srsItems.isNotEmpty) return false;
    if (inputs.nanikiruMastery.skills.values
        .any((stats) => stats.attempts > 0)) {
      return false;
    }
    if (inputs.defenseProgress.skills.values
        .any((stats) => stats.attempts > 0)) {
      return false;
    }
    return true;
  }

  static int countDueSrs({
    required Map<String, SrsItem> srsItems,
    required int nowMilliseconds,
  }) {
    return srsItems.values
        .where((item) => item.nextReviewAt <= nowMilliseconds)
        .length;
  }

  static List<TrainingPlanTask> _newUserTasks() => [
        TrainingPlanTask(
          id: starterFlashcardTaskId,
          kind: TrainingTaskKind.starterLesson,
          module: TrainingModule.flashcard,
          targetAttempts: 3,
        ),
        TrainingPlanTask(
          id: yakuExplorationTaskId,
          kind: TrainingTaskKind.exploration,
          module: TrainingModule.yaku,
          targetAttempts: 3,
        ),
        TrainingPlanTask(
          id: dailyNanikiruTaskId,
          kind: TrainingTaskKind.dailyChallenge,
          module: TrainingModule.nanikiru,
          targetAttempts: 3,
        ),
      ];

  static List<TrainingPlanTask> _returningUserTasks({
    required DateTime now,
    required TrainingPlanInputs inputs,
  }) {
    final dueCount = countDueSrs(
      srsItems: inputs.srsItems,
      nowMilliseconds: now.millisecondsSinceEpoch,
    );
    final weakness = WeaknessRecommender.recommend(
      nanikiruMastery: inputs.nanikiruMastery,
      defenseProgress: inputs.defenseProgress,
    );

    return [
      if (dueCount > 0)
        TrainingPlanTask(
          id: dueReviewTaskId,
          kind: TrainingTaskKind.dueReview,
          module: TrainingModule.review,
          targetAttempts:
              dueCount > maximumDueReviews ? maximumDueReviews : dueCount,
        )
      else
        TrainingPlanTask(
          id: yakuExplorationTaskId,
          kind: TrainingTaskKind.exploration,
          module: TrainingModule.yaku,
          targetAttempts: 3,
        ),
      if (weakness != null)
        TrainingPlanTask(
          id: 'training.weak.${weakness.skillId}.v1',
          kind: TrainingTaskKind.weakSkill,
          module: weakness.module,
          targetAttempts: weakness.module == TrainingModule.defense ? 2 : 3,
          focusSkillId: weakness.skillId,
        )
      else
        TrainingPlanTask(
          id: defenseExplorationTaskId,
          kind: TrainingTaskKind.exploration,
          module: TrainingModule.defense,
          targetAttempts: 3,
        ),
      TrainingPlanTask(
        id: dailyNanikiruTaskId,
        kind: TrainingTaskKind.dailyChallenge,
        module: TrainingModule.nanikiru,
        targetAttempts: 3,
      ),
    ];
  }
}
