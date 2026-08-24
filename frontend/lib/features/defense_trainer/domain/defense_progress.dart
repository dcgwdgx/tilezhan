import 'dart:math' as math;

/// Stable persistence identifiers for defense-training concepts.
///
/// These strings are part of the on-disk taxonomy. They must not be replaced
/// by enum indexes or renamed without an explicit migration.
abstract final class DefenseSkillIds {
  static const genbutsu = 'defense.genbutsu';
  static const suji = 'defense.suji';
  static const kabe = 'defense.kabe';
  static const honorVisibility = 'defense.honor_visibility';
  static const combined = 'defense.combined';

  static const all = <String>{
    genbutsu,
    suji,
    kabe,
    honorVisibility,
    combined,
  };
}

/// Outcome evidence retained by the aggregate defense progress profile.
///
/// Question-level scheduling, EF, repetitions, and review intervals belong to
/// the shared SRS layer and are deliberately not duplicated here.
enum DefenseAttemptOutcome { correct, incorrect, skipped, timedOut }

/// Aggregate performance for one stable defense skill.
class DefenseSkillStats {
  const DefenseSkillStats({
    this.correct = 0,
    this.incorrect = 0,
    this.skipped = 0,
    this.timedOut = 0,
    this.currentCorrectStreak = 0,
    this.bestCorrectStreak = 0,
    this.lastAttemptAt = 0,
  });

  final int correct;
  final int incorrect;
  final int skipped;
  final int timedOut;
  final int currentCorrectStreak;
  final int bestCorrectStreak;
  final int lastAttemptAt;

  int get attempts => correct + incorrect + skipped + timedOut;

  /// Correct answers divided by every completed attempt.
  ///
  /// Skips and timeouts count as evidence that the skill was not demonstrated.
  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  DefenseSkillStats recordAttempt({
    required DefenseAttemptOutcome outcome,
    required int occurredAt,
  }) {
    if (occurredAt < 0) {
      throw ArgumentError.value(occurredAt, 'occurredAt');
    }

    final nextStreak =
        outcome == DefenseAttemptOutcome.correct ? currentCorrectStreak + 1 : 0;
    return DefenseSkillStats(
      correct: correct + (outcome == DefenseAttemptOutcome.correct ? 1 : 0),
      incorrect:
          incorrect + (outcome == DefenseAttemptOutcome.incorrect ? 1 : 0),
      skipped: skipped + (outcome == DefenseAttemptOutcome.skipped ? 1 : 0),
      timedOut: timedOut + (outcome == DefenseAttemptOutcome.timedOut ? 1 : 0),
      currentCorrectStreak: nextStreak,
      bestCorrectStreak: math.max(bestCorrectStreak, nextStreak),
      lastAttemptAt: math.max(lastAttemptAt, occurredAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'correct': correct,
        'incorrect': incorrect,
        'skipped': skipped,
        'timedOut': timedOut,
        'currentCorrectStreak': currentCorrectStreak,
        'bestCorrectStreak': bestCorrectStreak,
        'lastAttemptAt': lastAttemptAt,
      };

  factory DefenseSkillStats.fromJson(Map<String, dynamic> json) {
    final correct = _nonNegativeInt(json['correct']);
    final current = math.min(
      correct,
      _nonNegativeInt(json['currentCorrectStreak']),
    );
    final best = math.max(
      current,
      math.min(correct, _nonNegativeInt(json['bestCorrectStreak'])),
    );
    return DefenseSkillStats(
      correct: correct,
      incorrect: _nonNegativeInt(json['incorrect']),
      skipped: _nonNegativeInt(json['skipped']),
      timedOut: _nonNegativeInt(json['timedOut']),
      currentCorrectStreak: current,
      bestCorrectStreak: best,
      lastAttemptAt: _nonNegativeInt(json['lastAttemptAt']),
    );
  }
}

/// One recent failed, skipped, or timed-out defense question.
class DefenseMistakeRef {
  DefenseMistakeRef({
    required String questionId,
    required int occurredAt,
  })  : questionId = _validateQuestionId(questionId),
        occurredAt = _validateOccurredAt(occurredAt);

  final String questionId;
  final int occurredAt;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'occurredAt': occurredAt,
      };

  static DefenseMistakeRef? tryFromJson(Object? value) {
    if (value is! Map) return null;
    try {
      final json = Map<String, dynamic>.from(value);
      final questionId = json['questionId'];
      final occurredAt = _exactInt(json['occurredAt']);
      if (questionId is! String || occurredAt == null) return null;
      return DefenseMistakeRef(
        questionId: questionId,
        occurredAt: occurredAt,
      );
    } on Object {
      return null;
    }
  }

  static String _validateQuestionId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 160) {
      throw ArgumentError.value(
        value,
        'questionId',
        'Expected 1 to 160 characters',
      );
    }
    return normalized;
  }

  static int _validateOccurredAt(int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'occurredAt');
    }
    return value;
  }
}

/// Versioned, offline-first aggregate progress for defense training.
class DefenseProgressProfile {
  DefenseProgressProfile({
    Map<String, DefenseSkillStats> skills = const {},
    List<DefenseMistakeRef> recentMistakes = const [],
    int updatedAt = 0,
  }) : this._(
          skills: skills,
          recentMistakes: recentMistakes,
          updatedAt: math.max(0, updatedAt),
          sourceSchemaVersion: schemaVersion,
          sourceTaxonomyVersion: taxonomyVersion,
          isReadOnly: false,
        );

  DefenseProgressProfile._({
    required Map<String, DefenseSkillStats> skills,
    required List<DefenseMistakeRef> recentMistakes,
    required this.updatedAt,
    required this.sourceSchemaVersion,
    required this.sourceTaxonomyVersion,
    required this.isReadOnly,
  })  : skills = Map<String, DefenseSkillStats>.unmodifiable(skills),
        recentMistakes = List<DefenseMistakeRef>.unmodifiable(
          _normalizeMistakes(recentMistakes),
        );

  static const schemaVersion = 1;
  static const taxonomyVersion = 1;
  static const maximumRecentMistakes = 20;

  factory DefenseProgressProfile.empty() => DefenseProgressProfile();

  final Map<String, DefenseSkillStats> skills;
  final List<DefenseMistakeRef> recentMistakes;
  final int updatedAt;

  /// Versions observed on disk. Future versions make this profile read-only.
  final int sourceSchemaVersion;
  final int sourceTaxonomyVersion;
  final bool isReadOnly;

  DefenseSkillStats? skill(String skillId) => skills[skillId];

  /// Applies one completed attempt to one supported stable skill.
  ///
  /// A profile loaded from a future schema can still update for the current
  /// in-memory session, but [isReadOnly] remains true so it cannot overwrite
  /// data written by the newer app.
  DefenseProgressProfile recordAttempt({
    required String skillId,
    required String questionId,
    required DefenseAttemptOutcome outcome,
    required int occurredAt,
  }) {
    if (!DefenseSkillIds.all.contains(skillId)) return this;
    final normalizedQuestionId = DefenseMistakeRef._validateQuestionId(
      questionId,
    );
    if (occurredAt < 0) {
      throw ArgumentError.value(occurredAt, 'occurredAt');
    }

    final nextSkills = Map<String, DefenseSkillStats>.from(skills);
    nextSkills[skillId] = (nextSkills[skillId] ?? const DefenseSkillStats())
        .recordAttempt(outcome: outcome, occurredAt: occurredAt);

    final nextMistakes = List<DefenseMistakeRef>.from(recentMistakes);
    if (outcome != DefenseAttemptOutcome.correct) {
      nextMistakes.insert(
        0,
        DefenseMistakeRef(
          questionId: normalizedQuestionId,
          occurredAt: occurredAt,
        ),
      );
    }

    return DefenseProgressProfile._(
      skills: nextSkills,
      recentMistakes: nextMistakes,
      updatedAt: math.max(updatedAt, occurredAt),
      sourceSchemaVersion: sourceSchemaVersion,
      sourceTaxonomyVersion: sourceTaxonomyVersion,
      isReadOnly: isReadOnly,
    );
  }

  Map<String, dynamic> toJson() {
    if (isReadOnly) {
      throw StateError(
        'A future defense progress schema must not be overwritten',
      );
    }
    return {
      'schemaVersion': schemaVersion,
      'taxonomyVersion': taxonomyVersion,
      'updatedAt': updatedAt,
      'skills': skills.map(
        (skillId, stats) => MapEntry(skillId, stats.toJson()),
      ),
      'recentMistakes': recentMistakes
          .map((mistake) => mistake.toJson())
          .toList(growable: false),
    };
  }

  factory DefenseProgressProfile.fromJson(Map<String, dynamic> json) {
    final rawSchemaVersion = _exactInt(json['schemaVersion']);
    final rawTaxonomyVersion = _exactInt(json['taxonomyVersion']);

    if ((rawSchemaVersion ?? 0) > schemaVersion ||
        (rawTaxonomyVersion ?? 0) > taxonomyVersion) {
      return DefenseProgressProfile._(
        skills: const {},
        recentMistakes: const [],
        updatedAt: 0,
        sourceSchemaVersion: rawSchemaVersion ?? schemaVersion,
        sourceTaxonomyVersion: rawTaxonomyVersion ?? taxonomyVersion,
        isReadOnly: true,
      );
    }

    return switch (rawSchemaVersion) {
      schemaVersion => _fromVersionOne(
          json,
          sourceTaxonomyVersion: rawTaxonomyVersion ?? taxonomyVersion,
        ),
      // There is no pre-release persisted schema to migrate. Missing,
      // malformed, zero, or negative versions are treated as a clean profile.
      _ => DefenseProgressProfile.empty(),
    };
  }

  static DefenseProgressProfile _fromVersionOne(
    Map<String, dynamic> json, {
    required int sourceTaxonomyVersion,
  }) {
    final parsedSkills = <String, DefenseSkillStats>{};
    final rawSkills = json['skills'];
    if (rawSkills is Map) {
      for (final entry in rawSkills.entries) {
        final skillId = entry.key;
        final rawStats = entry.value;
        if (skillId is! String ||
            skillId.trim().isEmpty ||
            skillId.length > 160 ||
            rawStats is! Map) {
          continue;
        }
        try {
          parsedSkills[skillId] = DefenseSkillStats.fromJson(
            Map<String, dynamic>.from(rawStats),
          );
        } on Object {
          // One malformed skill must not discard valid siblings.
        }
      }
    }

    final parsedMistakes = <DefenseMistakeRef>[];
    final rawMistakes = json['recentMistakes'];
    if (rawMistakes is List) {
      for (final rawMistake in rawMistakes) {
        final mistake = DefenseMistakeRef.tryFromJson(rawMistake);
        if (mistake != null) parsedMistakes.add(mistake);
      }
    }

    return DefenseProgressProfile._(
      skills: parsedSkills,
      recentMistakes: parsedMistakes,
      updatedAt: _nonNegativeInt(json['updatedAt']),
      sourceSchemaVersion: schemaVersion,
      sourceTaxonomyVersion: sourceTaxonomyVersion,
      isReadOnly: false,
    );
  }

  static List<DefenseMistakeRef> _normalizeMistakes(
    Iterable<DefenseMistakeRef> source,
  ) {
    final sorted = List<DefenseMistakeRef>.from(source)
      ..sort((left, right) {
        final byTime = right.occurredAt.compareTo(left.occurredAt);
        if (byTime != 0) return byTime;
        return left.questionId.compareTo(right.questionId);
      });
    final seen = <String>{};
    return sorted
        .where((mistake) => seen.add(mistake.questionId))
        .take(maximumRecentMistakes)
        .toList(growable: false);
  }
}

int _nonNegativeInt(Object? value) {
  final parsed = _exactInt(value);
  return parsed == null ? 0 : math.max(0, parsed);
}

int? _exactInt(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.toInt()) {
    return value.toInt();
  }
  return null;
}
