import 'dart:math' as math;

import 'nanikiru_state.dart';
import 'nanikiru_teaching_analysis.dart';

/// Stable persistence identifiers for the concepts trained by Nanikiru.
///
/// These values are part of the on-disk schema. They must not be replaced by
/// enum indexes or renamed without a taxonomy migration.
abstract final class NanikiruSkillIds {
  static const isolatedTileHandling = 'nanikiru.isolated_tile_handling';
  static const taatsuOverload = 'nanikiru.taatsu_overload';
  static const pairProtection = 'nanikiru.pair_protection';
  static const chiitoitsuCompetition = 'nanikiru.chiitoitsu_competition';
  static const kokushiTendency = 'nanikiru.kokushi_tendency';
  static const generalTileEfficiency = 'nanikiru.general_tile_efficiency';

  static const all = <String>{
    isolatedTileHandling,
    taatsuOverload,
    pairProtection,
    chiitoitsuCompetition,
    kokushiTendency,
    generalTileEfficiency,
  };

  /// Resolves an on-disk identifier back to the current teaching taxonomy.
  static NanikiruTeachingTag? teachingTagFor(String skillId) =>
      switch (skillId) {
        isolatedTileHandling => NanikiruTeachingTag.isolatedTileHandling,
        taatsuOverload => NanikiruTeachingTag.taatsuOverload,
        pairProtection => NanikiruTeachingTag.pairProtection,
        chiitoitsuCompetition => NanikiruTeachingTag.chiitoitsuCompetition,
        kokushiTendency => NanikiruTeachingTag.kokushiTendency,
        generalTileEfficiency => NanikiruTeachingTag.generalTileEfficiency,
        _ => null,
      };
}

/// Maps the teaching taxonomy to its stable persistence identifier.
extension NanikiruTeachingTagSkillId on NanikiruTeachingTag {
  String get skillId => switch (this) {
        NanikiruTeachingTag.isolatedTileHandling =>
          NanikiruSkillIds.isolatedTileHandling,
        NanikiruTeachingTag.taatsuOverload => NanikiruSkillIds.taatsuOverload,
        NanikiruTeachingTag.pairProtection => NanikiruSkillIds.pairProtection,
        NanikiruTeachingTag.chiitoitsuCompetition =>
          NanikiruSkillIds.chiitoitsuCompetition,
        NanikiruTeachingTag.kokushiTendency => NanikiruSkillIds.kokushiTendency,
        NanikiruTeachingTag.generalTileEfficiency =>
          NanikiruSkillIds.generalTileEfficiency,
      };
}

/// Persisted mastery estimate for one Nanikiru skill.
class NanikiruSkillMastery {
  const NanikiruSkillMastery({
    this.rating = initialRating,
    this.attempts = 0,
    this.correct = 0,
    this.incorrect = 0,
    this.skipped = 0,
    this.timedOut = 0,
    this.lastAttemptAt = 0,
  });

  static const initialRating = 800;
  static const minimumRating = 600;
  static const maximumRating = 1800;

  final int rating;
  final int attempts;
  final int correct;
  final int incorrect;
  final int skipped;
  final int timedOut;
  final int lastAttemptAt;

  /// Returns a new mastery estimate after one completed attempt.
  ///
  /// [NaniKiruOutcome.unanswered] is deliberately ignored and returns this
  /// instance unchanged.
  NanikiruSkillMastery recordAttempt({
    required NaniKiruOutcome outcome,
    required int puzzleDifficulty,
    required int occurredAt,
  }) {
    if (outcome == NaniKiruOutcome.unanswered) return this;

    final expected = 1.0 /
        (1.0 +
            math.pow(
              10.0,
              (puzzleDifficulty - rating) / 400.0,
            ));
    final actual = outcome == NaniKiruOutcome.perfect ? 1.0 : 0.0;
    final weight = switch (outcome) {
      NaniKiruOutcome.perfect || NaniKiruOutcome.incorrect => 1.0,
      NaniKiruOutcome.timedOut => 0.75,
      NaniKiruOutcome.skipped => 0.5,
      NaniKiruOutcome.unanswered => 0.0,
    };
    final k = attempts < 10
        ? 32
        : attempts < 30
            ? 24
            : 16;
    final delta = (k * weight * (actual - expected)).round();
    final nextRating =
        (rating + delta).clamp(minimumRating, maximumRating).toInt();

    return NanikiruSkillMastery(
      rating: nextRating,
      attempts: attempts + 1,
      correct: correct + (outcome == NaniKiruOutcome.perfect ? 1 : 0),
      incorrect: incorrect + (outcome == NaniKiruOutcome.incorrect ? 1 : 0),
      skipped: skipped + (outcome == NaniKiruOutcome.skipped ? 1 : 0),
      timedOut: timedOut + (outcome == NaniKiruOutcome.timedOut ? 1 : 0),
      lastAttemptAt: occurredAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'rating': rating,
        'attempts': attempts,
        'correct': correct,
        'incorrect': incorrect,
        'skipped': skipped,
        'timedOut': timedOut,
        'lastAttemptAt': lastAttemptAt,
      };

  factory NanikiruSkillMastery.fromJson(Map<String, dynamic> json) {
    return NanikiruSkillMastery(
      rating: _readInt(json['rating'], initialRating)
          .clamp(minimumRating, maximumRating)
          .toInt(),
      attempts: math.max(0, _readInt(json['attempts'], 0)),
      correct: math.max(0, _readInt(json['correct'], 0)),
      incorrect: math.max(0, _readInt(json['incorrect'], 0)),
      skipped: math.max(0, _readInt(json['skipped'], 0)),
      timedOut: math.max(0, _readInt(json['timedOut'], 0)),
      lastAttemptAt: math.max(0, _readInt(json['lastAttemptAt'], 0)),
    );
  }

  static int _readInt(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num && value.isFinite) return value.toInt();
    return fallback;
  }
}

/// Versioned, offline-first collection of all Nanikiru skill estimates.
class NanikiruSkillMasteryProfile {
  NanikiruSkillMasteryProfile({
    Map<String, NanikiruSkillMastery> skills = const {},
    this.updatedAt = 0,
  }) : skills = Map.unmodifiable(skills);

  static const schemaVersion = 1;
  static const taxonomyVersion = 1;

  factory NanikiruSkillMasteryProfile.empty() => NanikiruSkillMasteryProfile();

  final Map<String, NanikiruSkillMastery> skills;
  final int updatedAt;

  NanikiruSkillMastery? skill(String skillId) => skills[skillId];

  /// Returns up to [maximumSkills] sufficiently observed weak topics.
  ///
  /// Personalization remains disabled until a topic has at least
  /// [minimumAttempts] answers. This avoids treating a single early miss as a
  /// stable weakness. Topics within 50 rating points of the weakest one are
  /// considered together so training does not tunnel into one concept.
  Set<NanikiruTeachingTag> weakestTeachingTags({
    int minimumAttempts = 3,
    int maximumSkills = 2,
  }) {
    if (minimumAttempts < 1) {
      throw RangeError.value(minimumAttempts, 'minimumAttempts');
    }
    if (maximumSkills < 1) {
      throw RangeError.value(maximumSkills, 'maximumSkills');
    }

    final observed = skills.entries
        .where((entry) =>
            entry.value.attempts >= minimumAttempts &&
            NanikiruSkillIds.teachingTagFor(entry.key) != null)
        .toList()
      ..sort((left, right) {
        final byRating = left.value.rating.compareTo(right.value.rating);
        if (byRating != 0) return byRating;
        return left.key.compareTo(right.key);
      });
    if (observed.isEmpty) return const <NanikiruTeachingTag>{};

    final weakestRating = observed.first.value.rating;
    return Set<NanikiruTeachingTag>.unmodifiable(
      observed
          .where((entry) => entry.value.rating <= weakestRating + 50)
          .take(maximumSkills)
          .map((entry) => NanikiruSkillIds.teachingTagFor(entry.key)!),
    );
  }

  /// Applies one completed puzzle to every supported skill in [skillIds].
  ///
  /// Duplicate and unknown identifiers are ignored. An unanswered attempt or
  /// an empty supported identifier set leaves the profile unchanged.
  NanikiruSkillMasteryProfile recordAttempt({
    required Iterable<String> skillIds,
    required NaniKiruOutcome outcome,
    required int puzzleDifficulty,
    required int occurredAt,
  }) {
    if (outcome == NaniKiruOutcome.unanswered) return this;

    final supportedIds = skillIds.where(NanikiruSkillIds.all.contains).toSet();
    if (supportedIds.isEmpty) return this;

    final nextSkills = Map<String, NanikiruSkillMastery>.from(skills);
    for (final skillId in supportedIds) {
      nextSkills[skillId] =
          (nextSkills[skillId] ?? const NanikiruSkillMastery()).recordAttempt(
        outcome: outcome,
        puzzleDifficulty: puzzleDifficulty,
        occurredAt: occurredAt,
      );
    }
    return NanikiruSkillMasteryProfile(
      skills: nextSkills,
      updatedAt: math.max(0, occurredAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'taxonomyVersion': taxonomyVersion,
        'updatedAt': updatedAt,
        'skills': skills.map(
          (skillId, mastery) => MapEntry(skillId, mastery.toJson()),
        ),
      };

  factory NanikiruSkillMasteryProfile.fromJson(Map<String, dynamic> json) {
    final parsedSkills = <String, NanikiruSkillMastery>{};
    final rawSkills = json['skills'];
    if (rawSkills is Map) {
      for (final entry in rawSkills.entries) {
        final skillId = entry.key;
        final rawMastery = entry.value;
        if (skillId is! String || rawMastery is! Map) continue;
        try {
          parsedSkills[skillId] = NanikiruSkillMastery.fromJson(
            Map<String, dynamic>.from(rawMastery),
          );
        } on Object {
          // A malformed entry must not discard the rest of the profile.
        }
      }
    }

    return NanikiruSkillMasteryProfile(
      skills: parsedSkills,
      updatedAt: math.max(
        0,
        NanikiruSkillMastery._readInt(json['updatedAt'], 0),
      ),
    );
  }
}
