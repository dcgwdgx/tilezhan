import 'dart:math' as math;

import '../../defense_trainer/domain/defense_progress.dart';
import '../../nanikiru/domain/nanikiru_skill_mastery.dart';
import 'training_plan.dart';

/// A reliable, explainable weak-skill signal used by the daily plan.
///
/// [priority] is an internal ordering value. Product copy should present the
/// underlying [correct] and [attempts] evidence instead of implying that the
/// score is a measured probability.
class WeaknessRecommendation {
  const WeaknessRecommendation({
    required this.module,
    required this.skillId,
    required this.attempts,
    required this.correct,
    required this.lastAttemptAt,
  });

  final TrainingModule module;
  final String skillId;
  final int attempts;
  final int correct;
  final int lastAttemptAt;

  double get accuracy =>
      attempts == 0 ? 0 : (correct / attempts).clamp(0.0, 1.0).toDouble();

  double get confidence => math.min(attempts / 10, 1.0);

  double get priority => (1 - accuracy) * confidence;
}

/// Ranks sufficiently observed Nanikiru and defense skills.
abstract final class WeaknessRecommender {
  static const minimumAttempts = 3;

  /// Returns the strongest reliable weakness, or null while there is not
  /// enough evidence to label any topic as weak.
  static WeaknessRecommendation? recommend({
    required NanikiruSkillMasteryProfile nanikiruMastery,
    required DefenseProgressProfile defenseProgress,
  }) {
    final ranked = rank(
      nanikiruMastery: nanikiruMastery,
      defenseProgress: defenseProgress,
    );
    return ranked.isEmpty ? null : ranked.first;
  }

  /// Returns every reliable signal in deterministic recommendation order.
  ///
  /// Ordering is priority descending, attempts descending, recency
  /// descending, then stable skill ID ascending. Unknown taxonomy entries are
  /// ignored so corrupt or future data cannot create an unroutable task.
  static List<WeaknessRecommendation> rank({
    required NanikiruSkillMasteryProfile nanikiruMastery,
    required DefenseProgressProfile defenseProgress,
  }) {
    final candidates = <WeaknessRecommendation>[];

    for (final entry in nanikiruMastery.skills.entries) {
      final skillId = entry.key;
      final stats = entry.value;
      if (!NanikiruSkillIds.all.contains(skillId) ||
          stats.attempts < minimumAttempts) {
        continue;
      }
      _addIfWeak(
        candidates,
        WeaknessRecommendation(
          module: TrainingModule.nanikiru,
          skillId: skillId,
          attempts: stats.attempts,
          correct: stats.correct.clamp(0, stats.attempts).toInt(),
          lastAttemptAt: math.max(0, stats.lastAttemptAt),
        ),
      );
    }

    for (final entry in defenseProgress.skills.entries) {
      final skillId = entry.key;
      final stats = entry.value;
      if (!DefenseSkillIds.all.contains(skillId) ||
          stats.attempts < minimumAttempts) {
        continue;
      }
      _addIfWeak(
        candidates,
        WeaknessRecommendation(
          module: TrainingModule.defense,
          skillId: skillId,
          attempts: stats.attempts,
          correct: stats.correct,
          lastAttemptAt: stats.lastAttemptAt,
        ),
      );
    }

    candidates.sort(_compare);
    return List<WeaknessRecommendation>.unmodifiable(candidates);
  }

  static void _addIfWeak(
    List<WeaknessRecommendation> candidates,
    WeaknessRecommendation candidate,
  ) {
    // Sufficiently observed perfect performance is evidence of strength, not
    // a weak topic. It must leave the plan on the exploration fallback.
    if (candidate.priority > 0) candidates.add(candidate);
  }

  static int _compare(
    WeaknessRecommendation left,
    WeaknessRecommendation right,
  ) {
    final byPriority = right.priority.compareTo(left.priority);
    if (byPriority != 0) return byPriority;

    final byAttempts = right.attempts.compareTo(left.attempts);
    if (byAttempts != 0) return byAttempts;

    final byRecency = right.lastAttemptAt.compareTo(left.lastAttemptAt);
    if (byRecency != 0) return byRecency;

    final bySkillId = left.skillId.compareTo(right.skillId);
    if (bySkillId != 0) return bySkillId;
    return left.module.index.compareTo(right.module.index);
  }
}
