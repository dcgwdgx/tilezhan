import '../../../shared/engine/shanten_calculator.dart';

/// Seats shown in a four-player riichi-mahjong defense scenario.
enum DefenseSeat { east, south, west, north }

/// Stable lesson taxonomy for adaptive training and catalog coverage checks.
enum DefenseTopic {
  genbutsu,
  suji,
  kabe,
  honorVisibility,
  combinedEvidence,
}

/// Qualitative risk labels; these are deliberately not fake probabilities.
enum DefenseRiskLabel {
  /// The tile is in the target opponent's own river, so that opponent cannot
  /// legally ron it while furiten. It says nothing about the other opponents.
  absoluteAgainstTarget,

  /// Multiple or unusually strong clues reduce risk, but special/pair waits can
  /// remain. This must never be rendered as "safe" without qualification.
  stronglyReducedNotAbsolute,

  /// One recognized heuristic lowers a subset of possible waits only.
  relativelyReducedNotAbsolute,

  /// The scenario establishes no specific reduction for this option.
  noEstablishedReduction,
}

extension DefenseRiskLabelPriority on DefenseRiskLabel {
  int get priority => switch (this) {
        DefenseRiskLabel.absoluteAgainstTarget => 0,
        DefenseRiskLabel.stronglyReducedNotAbsolute => 1,
        DefenseRiskLabel.relativelyReducedNotAbsolute => 2,
        DefenseRiskLabel.noEstablishedReduction => 3,
      };
}

/// Auditable evidence attached to an answer option.
enum DefenseEvidenceTag {
  genbutsuAgainstTarget,
  discardedByDifferentOpponent,
  sujiAgainstTarget,
  completeKabe,
  incompleteKabe,
  threePublicHonorCopies,
  twoPublicHonorCopies,
  combinedIndependentClues,
  kokushiExceptionRemains,
  noEstablishedSafetyEvidence,
}

/// Stable explanation semantics that presentation code can localize.
enum DefenseExplanationCode {
  /// Target's own discard creates furiten for ron on that tile.
  targetOwnDiscardIsGenbutsu,

  /// A discard in somebody else's river is not genbutsu against the target.
  otherOpponentDiscardIsNotTargetGenbutsu,

  /// Suji reduces relevant two-sided waits but not tanki, shanpon, closed,
  /// edge, or special-hand waits.
  sujiCoversOnlyRyanmen,

  /// A complete wall removes the relevant sequence path, but pair and special
  /// waits remain possible.
  completeKabeStillNotAbsolute,

  /// With only three wall tiles visible, the fourth may still be concealed.
  incompleteKabeLeavesSequencePossible,

  /// Three public honor copies plus the candidate leave ordinary pair waits
  /// unavailable to the target, but a kokushi hand missing that honor can ron.
  threeVisibleHonorHasKokushiException,

  /// With two public copies plus the candidate, another copy may still be in
  /// the target's hand, so a single-tile or special wait remains possible.
  twoVisibleHonorStillNotSafe,

  /// Independent suji and complete-wall clues reduce more ordinary sequence
  /// paths than either clue alone, without proving safety.
  combinedSujiAndKabeStillNotAbsolute,

  /// Target-specific genbutsu is conclusive for that target; relative clues are
  /// not a substitute for it.
  targetGenbutsuOutranksRelativeClues,

  /// No rule represented by this scenario establishes a reduction.
  noEstablishedSafetyEvidence,
}

/// One tile offered as an answer to a defense question.
class DefenseChoice {
  factory DefenseChoice({
    required String id,
    required String tileId,
    required DefenseRiskLabel riskLabel,
    required Iterable<DefenseEvidenceTag> evidenceTags,
    required DefenseExplanationCode explanationCode,
  }) =>
      DefenseChoice._(
        id: id,
        tileId: tileId,
        riskLabel: riskLabel,
        evidenceTags: Set<DefenseEvidenceTag>.unmodifiable(evidenceTags),
        explanationCode: explanationCode,
      );

  const DefenseChoice._({
    required this.id,
    required this.tileId,
    required this.riskLabel,
    required this.evidenceTags,
    required this.explanationCode,
  });

  final String id;
  final String tileId;
  final DefenseRiskLabel riskLabel;
  final Set<DefenseEvidenceTag> evidenceTags;
  final DefenseExplanationCode explanationCode;
}

/// Fixed, inspectable information for a single-target riichi defense decision.
class DefenseQuestion {
  factory DefenseQuestion({
    required String id,
    required DefenseTopic topic,
    required DefenseSeat targetSeat,
    required Map<DefenseSeat, List<String>> discardsBySeat,
    Map<String, int> additionalPublicVisibleCounts = const {},
    required List<DefenseChoice> choices,
    required String bestChoiceId,
  }) {
    final discardSnapshot = <DefenseSeat, List<String>>{
      for (final entry in discardsBySeat.entries)
        entry.key: List<String>.unmodifiable(entry.value),
    };
    return DefenseQuestion._(
      id: id,
      topic: topic,
      targetSeat: targetSeat,
      discardsBySeat:
          Map<DefenseSeat, List<String>>.unmodifiable(discardSnapshot),
      additionalPublicVisibleCounts:
          Map<String, int>.unmodifiable(additionalPublicVisibleCounts),
      choices: List<DefenseChoice>.unmodifiable(choices),
      bestChoiceId: bestChoiceId,
    );
  }

  const DefenseQuestion._({
    required this.id,
    required this.topic,
    required this.targetSeat,
    required this.discardsBySeat,
    required this.additionalPublicVisibleCounts,
    required this.choices,
    required this.bestChoiceId,
  });

  final String id;
  final DefenseTopic topic;

  /// The only opponent for whom a genbutsu label is conclusive.
  final DefenseSeat targetSeat;

  /// Public river tiles by opponent. A tile in a different opponent's river is
  /// not genbutsu against [targetSeat].
  final Map<DefenseSeat, List<String>> discardsBySeat;

  /// Publicly visible copies outside [discardsBySeat], such as calls or dora
  /// indicators. The candidate tile in the player's hand is not included.
  final Map<String, int> additionalPublicVisibleCounts;

  final List<DefenseChoice> choices;
  final String bestChoiceId;

  List<String> get targetDiscards =>
      discardsBySeat[targetSeat] ?? const <String>[];

  DefenseChoice get bestChoice =>
      choices.singleWhere((choice) => choice.id == bestChoiceId);

  int publicVisibleCount(String tileId) {
    var count = additionalPublicVisibleCounts[tileId] ?? 0;
    for (final river in discardsBySeat.values) {
      count += river.where((discard) => discard == tileId).length;
    }
    return count;
  }
}

/// Result of choosing one of a question's four offered tiles.
class DefenseAnswerEvaluation {
  const DefenseAnswerEvaluation({
    required this.question,
    required this.selectedChoice,
    required this.bestChoice,
  });

  final DefenseQuestion question;
  final DefenseChoice selectedChoice;
  final DefenseChoice bestChoice;

  bool get isCorrect => selectedChoice.id == bestChoice.id;
}

class DefenseTrainerEvaluator {
  const DefenseTrainerEvaluator._();

  static DefenseAnswerEvaluation evaluate({
    required DefenseQuestion question,
    required String selectedChoiceId,
  }) {
    final matchingChoices =
        question.choices.where((choice) => choice.id == selectedChoiceId);
    if (matchingChoices.length != 1) {
      throw ArgumentError.value(
        selectedChoiceId,
        'selectedChoiceId',
        'Must identify exactly one choice in the question',
      );
    }
    return DefenseAnswerEvaluation(
      question: question,
      selectedChoice: matchingChoices.single,
      bestChoice: question.bestChoice,
    );
  }
}

enum DefenseCatalogIssueCode {
  catalogTooSmall,
  missingTopic,
  duplicateQuestionId,
  missingTargetRiver,
  wrongChoiceCount,
  duplicateChoiceId,
  duplicateChoiceTile,
  missingBestChoice,
  invalidTileId,
  invalidVisibleCount,
  physicalCopyLimitExceeded,
  missingEvidence,
  falseTargetGenbutsuTag,
  untaggedTargetGenbutsu,
  targetGenbutsuNotAbsolute,
  absoluteWithoutTargetGenbutsu,
  relativeEvidenceMarkedAbsolute,
  falseSujiTag,
  untaggedSujiEvidence,
  falseCompleteKabeTag,
  falseIncompleteKabeTag,
  falseHonorVisibilityTag,
  invalidCombinedEvidence,
  choiceExceedsPhysicalCopies,
  bestChoiceNotUniquelyLowestRisk,
}

class DefenseCatalogIssue {
  factory DefenseCatalogIssue({
    required DefenseCatalogIssueCode code,
    String? questionId,
    String? choiceId,
    Map<String, Object?> details = const {},
  }) =>
      DefenseCatalogIssue._(
        code: code,
        questionId: questionId,
        choiceId: choiceId,
        details: Map<String, Object?>.unmodifiable(details),
      );

  const DefenseCatalogIssue._({
    required this.code,
    required this.questionId,
    required this.choiceId,
    required this.details,
  });

  final DefenseCatalogIssueCode code;
  final String? questionId;
  final String? choiceId;
  final Map<String, Object?> details;
}

class DefenseCatalogValidationResult {
  DefenseCatalogValidationResult(Iterable<DefenseCatalogIssue> issues)
      : issues = List<DefenseCatalogIssue>.unmodifiable(issues);

  final List<DefenseCatalogIssue> issues;
  bool get isValid => issues.isEmpty;
}

/// Structural and rule-honesty validation for a fixed defense catalog.
class DefenseCatalogValidator {
  const DefenseCatalogValidator._();

  static const minimumQuestionCount = 12;

  static DefenseCatalogValidationResult validate(
    Iterable<DefenseQuestion> source,
  ) {
    final questions = List<DefenseQuestion>.from(source);
    final issues = <DefenseCatalogIssue>[];
    if (questions.length < minimumQuestionCount) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.catalogTooSmall,
        details: {'actual': questions.length, 'minimum': minimumQuestionCount},
      ));
    }

    final coveredTopics = questions.map((question) => question.topic).toSet();
    for (final topic in DefenseTopic.values) {
      if (!coveredTopics.contains(topic)) {
        issues.add(DefenseCatalogIssue(
          code: DefenseCatalogIssueCode.missingTopic,
          details: {'topic': topic.name},
        ));
      }
    }

    final seenQuestionIds = <String>{};
    for (final question in questions) {
      if (!seenQuestionIds.add(question.id)) {
        issues.add(DefenseCatalogIssue(
          code: DefenseCatalogIssueCode.duplicateQuestionId,
          questionId: question.id,
        ));
      }
      _validateQuestion(question, issues);
    }
    return DefenseCatalogValidationResult(issues);
  }

  static void _validateQuestion(
    DefenseQuestion question,
    List<DefenseCatalogIssue> issues,
  ) {
    if (question.targetDiscards.isEmpty) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.missingTargetRiver,
        questionId: question.id,
      ));
    }

    if (question.choices.length != 4) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.wrongChoiceCount,
        questionId: question.id,
        details: {'actual': question.choices.length},
      ));
    }

    final choiceIds = <String>{};
    final choiceTiles = <String>{};
    for (final choice in question.choices) {
      if (!choiceIds.add(choice.id)) {
        issues.add(DefenseCatalogIssue(
          code: DefenseCatalogIssueCode.duplicateChoiceId,
          questionId: question.id,
          choiceId: choice.id,
        ));
      }
      if (!choiceTiles.add(choice.tileId)) {
        issues.add(DefenseCatalogIssue(
          code: DefenseCatalogIssueCode.duplicateChoiceTile,
          questionId: question.id,
          choiceId: choice.id,
          details: {'tileId': choice.tileId},
        ));
      }
      _validateChoice(question, choice, issues);
    }

    final matchingBest = question.choices
        .where((choice) => choice.id == question.bestChoiceId)
        .toList();
    if (matchingBest.length != 1) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.missingBestChoice,
        questionId: question.id,
        details: {'bestChoiceId': question.bestChoiceId},
      ));
    } else {
      final best = matchingBest.single;
      final equallyOrMoreSafeAlternatives = question.choices.where(
        (choice) =>
            choice.id != best.id &&
            choice.riskLabel.priority <= best.riskLabel.priority,
      );
      if (equallyOrMoreSafeAlternatives.isNotEmpty) {
        issues.add(DefenseCatalogIssue(
          code: DefenseCatalogIssueCode.bestChoiceNotUniquelyLowestRisk,
          questionId: question.id,
          choiceId: best.id,
        ));
      }
    }

    final totalPublicCounts = <String, int>{};
    for (final river in question.discardsBySeat.values) {
      for (final tileId in river) {
        _validateTileId(question.id, tileId, issues);
        totalPublicCounts[tileId] = (totalPublicCounts[tileId] ?? 0) + 1;
      }
    }
    for (final entry in question.additionalPublicVisibleCounts.entries) {
      _validateTileId(question.id, entry.key, issues);
      if (entry.value < 0 || entry.value > 4) {
        issues.add(DefenseCatalogIssue(
          code: DefenseCatalogIssueCode.invalidVisibleCount,
          questionId: question.id,
          details: {'tileId': entry.key, 'count': entry.value},
        ));
      }
      totalPublicCounts[entry.key] =
          (totalPublicCounts[entry.key] ?? 0) + entry.value;
    }
    for (final entry in totalPublicCounts.entries) {
      if (entry.value > 4) {
        issues.add(DefenseCatalogIssue(
          code: DefenseCatalogIssueCode.physicalCopyLimitExceeded,
          questionId: question.id,
          details: {'tileId': entry.key, 'count': entry.value},
        ));
      }
    }
    for (final choice in question.choices) {
      if ((totalPublicCounts[choice.tileId] ?? 0) >= 4) {
        issues.add(DefenseCatalogIssue(
          code: DefenseCatalogIssueCode.choiceExceedsPhysicalCopies,
          questionId: question.id,
          choiceId: choice.id,
          details: {
            'tileId': choice.tileId,
            'publicCount': totalPublicCounts[choice.tileId] ?? 0,
          },
        ));
      }
    }
  }

  static void _validateChoice(
    DefenseQuestion question,
    DefenseChoice choice,
    List<DefenseCatalogIssue> issues,
  ) {
    final hasValidTileId = _validateTileId(
      question.id,
      choice.tileId,
      issues,
      choiceId: choice.id,
    );
    if (choice.evidenceTags.isEmpty) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.missingEvidence,
        questionId: question.id,
        choiceId: choice.id,
      ));
    }

    final isInTargetRiver = question.targetDiscards.contains(choice.tileId);
    final taggedGenbutsu =
        choice.evidenceTags.contains(DefenseEvidenceTag.genbutsuAgainstTarget);
    if (taggedGenbutsu && !isInTargetRiver) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.falseTargetGenbutsuTag,
        questionId: question.id,
        choiceId: choice.id,
      ));
    }
    if (isInTargetRiver && !taggedGenbutsu) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.untaggedTargetGenbutsu,
        questionId: question.id,
        choiceId: choice.id,
      ));
    }
    if (taggedGenbutsu &&
        choice.riskLabel != DefenseRiskLabel.absoluteAgainstTarget) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.targetGenbutsuNotAbsolute,
        questionId: question.id,
        choiceId: choice.id,
      ));
    }
    if (choice.riskLabel == DefenseRiskLabel.absoluteAgainstTarget &&
        (!isInTargetRiver || !taggedGenbutsu)) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.absoluteWithoutTargetGenbutsu,
        questionId: question.id,
        choiceId: choice.id,
      ));
    }

    const relativeOnlyEvidence = {
      DefenseEvidenceTag.sujiAgainstTarget,
      DefenseEvidenceTag.completeKabe,
      DefenseEvidenceTag.incompleteKabe,
      DefenseEvidenceTag.threePublicHonorCopies,
      DefenseEvidenceTag.twoPublicHonorCopies,
      DefenseEvidenceTag.combinedIndependentClues,
      DefenseEvidenceTag.kokushiExceptionRemains,
    };
    if (choice.riskLabel == DefenseRiskLabel.absoluteAgainstTarget &&
        choice.evidenceTags.any(relativeOnlyEvidence.contains)) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.relativeEvidenceMarkedAbsolute,
        questionId: question.id,
        choiceId: choice.id,
      ));
    }

    if (!hasValidTileId) return;

    final isSujiAgainstTarget = _isSujiAgainstTarget(question, choice.tileId);
    final taggedSuji =
        choice.evidenceTags.contains(DefenseEvidenceTag.sujiAgainstTarget);
    if (taggedSuji && !isSujiAgainstTarget) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.falseSujiTag,
        questionId: question.id,
        choiceId: choice.id,
      ));
    }
    if (isSujiAgainstTarget && !taggedSuji && !taggedGenbutsu) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.untaggedSujiEvidence,
        questionId: question.id,
        choiceId: choice.id,
      ));
    }
    if (choice.evidenceTags.contains(DefenseEvidenceTag.completeKabe) &&
        !_hasTerminalKabe(question, choice.tileId, visibleCount: 4)) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.falseCompleteKabeTag,
        questionId: question.id,
        choiceId: choice.id,
      ));
    }
    if (choice.evidenceTags.contains(DefenseEvidenceTag.incompleteKabe) &&
        !_hasTerminalKabe(question, choice.tileId, visibleCount: 3)) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.falseIncompleteKabeTag,
        questionId: question.id,
        choiceId: choice.id,
      ));
    }
    final tagsThreeVisible =
        choice.evidenceTags.contains(DefenseEvidenceTag.threePublicHonorCopies);
    final tagsTwoVisible =
        choice.evidenceTags.contains(DefenseEvidenceTag.twoPublicHonorCopies);
    if ((tagsThreeVisible &&
            (choice.tileId[0] != 'z' ||
                question.publicVisibleCount(choice.tileId) != 3)) ||
        (tagsTwoVisible &&
            (choice.tileId[0] != 'z' ||
                question.publicVisibleCount(choice.tileId) != 2))) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.falseHonorVisibilityTag,
        questionId: question.id,
        choiceId: choice.id,
      ));
    }
    if (choice.evidenceTags
            .contains(DefenseEvidenceTag.combinedIndependentClues) &&
        !(choice.evidenceTags.contains(DefenseEvidenceTag.sujiAgainstTarget) &&
            choice.evidenceTags.contains(DefenseEvidenceTag.completeKabe))) {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.invalidCombinedEvidence,
        questionId: question.id,
        choiceId: choice.id,
      ));
    }
  }

  static bool _isSujiAgainstTarget(
    DefenseQuestion question,
    String tileId,
  ) {
    if (tileId[0] == 'z') return false;
    final rank = int.parse(tileId[1]);
    return question.targetDiscards.any((discard) =>
        _isValidTileId(discard) &&
        discard[0] == tileId[0] &&
        discard[0] != 'z' &&
        (int.parse(discard[1]) - rank).abs() == 3);
  }

  /// MVP kabe questions intentionally use only the unambiguous terminal case:
  /// a 1 needs both 2 and 3 for any sequence; a 9 needs both 7 and 8.
  static bool _hasTerminalKabe(
    DefenseQuestion question,
    String tileId, {
    required int visibleCount,
  }) {
    if (tileId[0] == 'z') return false;
    final rank = int.parse(tileId[1]);
    final wallRanks = switch (rank) {
      1 => const [2, 3],
      9 => const [7, 8],
      _ => const <int>[],
    };
    return wallRanks.any(
      (wallRank) =>
          question.publicVisibleCount('${tileId[0]}$wallRank') == visibleCount,
    );
  }

  static bool _validateTileId(
    String questionId,
    String tileId,
    List<DefenseCatalogIssue> issues, {
    String? choiceId,
  }) {
    try {
      // Reuse the engine's authoritative m1..z7 parser instead of maintaining
      // a second regex or tile catalog in this feature.
      ShantenCalculator.fromIds([tileId]);
      return true;
    } on ArgumentError {
      issues.add(DefenseCatalogIssue(
        code: DefenseCatalogIssueCode.invalidTileId,
        questionId: questionId,
        choiceId: choiceId,
        details: {'tileId': tileId},
      ));
      return false;
    }
  }

  static bool _isValidTileId(String tileId) {
    try {
      ShantenCalculator.fromIds([tileId]);
      return true;
    } on ArgumentError {
      return false;
    }
  }
}
