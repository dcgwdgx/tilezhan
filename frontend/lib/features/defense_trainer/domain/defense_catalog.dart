import 'defense_trainer.dart';

/// Versioned, hand-reviewed defense questions for the first commercial MVP.
///
/// These scenarios intentionally cover only a single declared-riichi target.
/// They teach evidence ordering, not exact deal-in percentages or full push/fold
/// strategy. Every relative clue remains explicitly non-absolute.
class DefenseQuestionCatalog {
  const DefenseQuestionCatalog._();

  static const taxonomyVersion = 1;

  /// Exact-review compatibility contract for every question published in v1.
  ///
  /// Published IDs are append-only: a later catalog may add a new version, but
  /// it must not remove these entries while an SRS record can still reference
  /// them. Keep this list separate from [questions] so tests catch removals.
  static const Set<String> publishedQuestionIds = {
    'defense.genbutsu.001.v1',
    'defense.genbutsu.002.v1',
    'defense.genbutsu.003.v1',
    'defense.suji.001.v1',
    'defense.suji.002.v1',
    'defense.suji.003.v1',
    'defense.kabe.001.v1',
    'defense.kabe.002.v1',
    'defense.kabe.003.v1',
    'defense.honor.001.v1',
    'defense.honor.002.v1',
    'defense.combined.001.v1',
    'defense.combined.002.v1',
    'defense.combined.003.v1',
  };

  static final List<DefenseQuestion> questions =
      List<DefenseQuestion>.unmodifiable([
    DefenseQuestion(
      id: 'defense.genbutsu.001.v1',
      topic: DefenseTopic.genbutsu,
      targetSeat: DefenseSeat.east,
      discardsBySeat: const {
        DefenseSeat.east: ['m4', 'p9'],
      },
      choices: [
        _genbutsu('a', 'm4'),
        _suji('b', 'm1'),
        _unknown('c', 'p5'),
        _unknown('d', 'z2'),
      ],
      bestChoiceId: 'a',
    ),
    DefenseQuestion(
      id: 'defense.genbutsu.002.v1',
      topic: DefenseTopic.genbutsu,
      targetSeat: DefenseSeat.south,
      discardsBySeat: const {
        DefenseSeat.east: ['z3'],
        DefenseSeat.south: ['p6', 'm9'],
      },
      choices: [
        _otherOpponentDiscard('a', 'z3'),
        _genbutsu('b', 'p6'),
        _suji('c', 'p3'),
        _unknown('d', 's5'),
      ],
      bestChoiceId: 'b',
    ),
    DefenseQuestion(
      id: 'defense.genbutsu.003.v1',
      topic: DefenseTopic.genbutsu,
      targetSeat: DefenseSeat.west,
      discardsBySeat: const {
        DefenseSeat.west: ['s2', 'z5'],
      },
      choices: [
        _unknown('a', 'm6'),
        _unknown('b', 'p4'),
        _genbutsu('c', 'z5'),
        _unknown('d', 's7'),
      ],
      bestChoiceId: 'c',
    ),
    DefenseQuestion(
      id: 'defense.suji.001.v1',
      topic: DefenseTopic.suji,
      targetSeat: DefenseSeat.east,
      discardsBySeat: const {
        DefenseSeat.east: ['m4', 'z1'],
      },
      choices: [
        _unknown('a', 'p5'),
        _unknown('b', 's6'),
        _unknown('c', 'z2'),
        _suji('d', 'm7'),
      ],
      bestChoiceId: 'd',
    ),
    DefenseQuestion(
      id: 'defense.suji.002.v1',
      topic: DefenseTopic.suji,
      targetSeat: DefenseSeat.south,
      discardsBySeat: const {
        DefenseSeat.south: ['p5', 'z7'],
      },
      choices: [
        _unknown('a', 'm2'),
        _suji('b', 'p8'),
        _unknown('c', 's4'),
        _unknown('d', 'z3'),
      ],
      bestChoiceId: 'b',
    ),
    DefenseQuestion(
      id: 'defense.suji.003.v1',
      topic: DefenseTopic.suji,
      targetSeat: DefenseSeat.north,
      discardsBySeat: const {
        DefenseSeat.north: ['s6', 'm1'],
      },
      choices: [
        _unknown('a', 'm5'),
        _unknown('b', 'p7'),
        _suji('c', 's3'),
        _unknown('d', 'z2'),
      ],
      bestChoiceId: 'c',
    ),
    DefenseQuestion(
      id: 'defense.kabe.001.v1',
      topic: DefenseTopic.kabe,
      targetSeat: DefenseSeat.east,
      discardsBySeat: const {
        DefenseSeat.east: ['z1'],
      },
      additionalPublicVisibleCounts: const {'m2': 4, 'm8': 3},
      choices: [
        _completeKabe('a', 'm1'),
        _incompleteKabe('b', 'm9'),
        _unknown('c', 'p5'),
        _unknown('d', 'z2'),
      ],
      bestChoiceId: 'a',
    ),
    DefenseQuestion(
      id: 'defense.kabe.002.v1',
      topic: DefenseTopic.kabe,
      targetSeat: DefenseSeat.south,
      discardsBySeat: const {
        DefenseSeat.south: ['z2'],
      },
      additionalPublicVisibleCounts: const {'p8': 4},
      choices: [
        _unknown('a', 'm5'),
        _unknown('b', 's4'),
        _unknown('c', 'z6'),
        _completeKabe('d', 'p9'),
      ],
      bestChoiceId: 'd',
    ),
    DefenseQuestion(
      id: 'defense.kabe.003.v1',
      topic: DefenseTopic.kabe,
      targetSeat: DefenseSeat.west,
      discardsBySeat: const {
        DefenseSeat.west: ['z3'],
      },
      additionalPublicVisibleCounts: const {'s3': 4},
      choices: [
        _unknown('a', 'm7'),
        _completeKabe('b', 's1'),
        _unknown('c', 'p4'),
        _unknown('d', 'z4'),
      ],
      bestChoiceId: 'b',
    ),
    DefenseQuestion(
      id: 'defense.honor.001.v1',
      topic: DefenseTopic.honorVisibility,
      targetSeat: DefenseSeat.north,
      discardsBySeat: const {
        DefenseSeat.north: ['m5'],
      },
      additionalPublicVisibleCounts: const {'z5': 3},
      choices: [
        _unknown('a', 'z1'),
        _unknown('b', 'z2'),
        _threeVisibleHonor('c', 'z5'),
        _unknown('d', 'z6'),
      ],
      bestChoiceId: 'c',
    ),
    DefenseQuestion(
      id: 'defense.honor.002.v1',
      topic: DefenseTopic.honorVisibility,
      targetSeat: DefenseSeat.east,
      discardsBySeat: const {
        DefenseSeat.east: ['p4'],
      },
      additionalPublicVisibleCounts: const {'z1': 2},
      choices: [
        _twoVisibleHonor('a', 'z1'),
        _unknown('b', 'm5'),
        _unknown('c', 's7'),
        _unknown('d', 'z2'),
      ],
      bestChoiceId: 'a',
    ),
    DefenseQuestion(
      id: 'defense.combined.001.v1',
      topic: DefenseTopic.combinedEvidence,
      targetSeat: DefenseSeat.south,
      discardsBySeat: const {
        DefenseSeat.south: ['p4', 'z7'],
      },
      additionalPublicVisibleCounts: const {'p2': 4},
      choices: [
        _unknown('a', 's5'),
        _suji('b', 'p7'),
        _unknown('c', 'z2'),
        _combinedSujiKabe('d', 'p1'),
      ],
      bestChoiceId: 'd',
    ),
    DefenseQuestion(
      id: 'defense.combined.002.v1',
      topic: DefenseTopic.combinedEvidence,
      targetSeat: DefenseSeat.west,
      discardsBySeat: const {
        DefenseSeat.west: ['m6', 'z2'],
      },
      additionalPublicVisibleCounts: const {'m8': 4},
      choices: [
        _suji('a', 'm3'),
        _combinedSujiKabe('b', 'm9'),
        _unknown('c', 'p4'),
        _unknown('d', 'z4'),
      ],
      bestChoiceId: 'b',
    ),
    DefenseQuestion(
      id: 'defense.combined.003.v1',
      topic: DefenseTopic.combinedEvidence,
      targetSeat: DefenseSeat.north,
      discardsBySeat: const {
        DefenseSeat.north: ['s8', 'p1'],
      },
      additionalPublicVisibleCounts: const {'m2': 4, 'z5': 3},
      choices: [
        _completeKabe('a', 'm1'),
        _threeVisibleHonor('b', 'z5'),
        _genbutsu(
          'c',
          's8',
          explanationCode:
              DefenseExplanationCode.targetGenbutsuOutranksRelativeClues,
        ),
        _unknown('d', 'p6'),
      ],
      bestChoiceId: 'c',
    ),
  ]);

  static final Map<String, DefenseQuestion> byId =
      Map<String, DefenseQuestion>.unmodifiable({
    for (final question in questions) question.id: question,
  });

  static final DefenseCatalogValidationResult validation =
      DefenseCatalogValidator.validate(questions);
}

DefenseChoice _genbutsu(
  String id,
  String tileId, {
  DefenseExplanationCode explanationCode =
      DefenseExplanationCode.targetOwnDiscardIsGenbutsu,
}) =>
    DefenseChoice(
      id: id,
      tileId: tileId,
      riskLabel: DefenseRiskLabel.absoluteAgainstTarget,
      evidenceTags: const {DefenseEvidenceTag.genbutsuAgainstTarget},
      explanationCode: explanationCode,
    );

DefenseChoice _otherOpponentDiscard(String id, String tileId) => DefenseChoice(
      id: id,
      tileId: tileId,
      riskLabel: DefenseRiskLabel.noEstablishedReduction,
      evidenceTags: const {DefenseEvidenceTag.discardedByDifferentOpponent},
      explanationCode:
          DefenseExplanationCode.otherOpponentDiscardIsNotTargetGenbutsu,
    );

DefenseChoice _suji(String id, String tileId) => DefenseChoice(
      id: id,
      tileId: tileId,
      riskLabel: DefenseRiskLabel.relativelyReducedNotAbsolute,
      evidenceTags: const {DefenseEvidenceTag.sujiAgainstTarget},
      explanationCode: DefenseExplanationCode.sujiCoversOnlyRyanmen,
    );

DefenseChoice _completeKabe(String id, String tileId) => DefenseChoice(
      id: id,
      tileId: tileId,
      riskLabel: DefenseRiskLabel.stronglyReducedNotAbsolute,
      evidenceTags: const {DefenseEvidenceTag.completeKabe},
      explanationCode: DefenseExplanationCode.completeKabeStillNotAbsolute,
    );

DefenseChoice _incompleteKabe(String id, String tileId) => DefenseChoice(
      id: id,
      tileId: tileId,
      riskLabel: DefenseRiskLabel.relativelyReducedNotAbsolute,
      evidenceTags: const {DefenseEvidenceTag.incompleteKabe},
      explanationCode:
          DefenseExplanationCode.incompleteKabeLeavesSequencePossible,
    );

DefenseChoice _threeVisibleHonor(String id, String tileId) => DefenseChoice(
      id: id,
      tileId: tileId,
      riskLabel: DefenseRiskLabel.stronglyReducedNotAbsolute,
      evidenceTags: const {
        DefenseEvidenceTag.threePublicHonorCopies,
        DefenseEvidenceTag.kokushiExceptionRemains,
      },
      explanationCode:
          DefenseExplanationCode.threeVisibleHonorHasKokushiException,
    );

DefenseChoice _twoVisibleHonor(String id, String tileId) => DefenseChoice(
      id: id,
      tileId: tileId,
      riskLabel: DefenseRiskLabel.relativelyReducedNotAbsolute,
      evidenceTags: const {DefenseEvidenceTag.twoPublicHonorCopies},
      explanationCode: DefenseExplanationCode.twoVisibleHonorStillNotSafe,
    );

DefenseChoice _combinedSujiKabe(String id, String tileId) => DefenseChoice(
      id: id,
      tileId: tileId,
      riskLabel: DefenseRiskLabel.stronglyReducedNotAbsolute,
      evidenceTags: const {
        DefenseEvidenceTag.sujiAgainstTarget,
        DefenseEvidenceTag.completeKabe,
        DefenseEvidenceTag.combinedIndependentClues,
      },
      explanationCode:
          DefenseExplanationCode.combinedSujiAndKabeStillNotAbsolute,
    );

DefenseChoice _unknown(String id, String tileId) => DefenseChoice(
      id: id,
      tileId: tileId,
      riskLabel: DefenseRiskLabel.noEstablishedReduction,
      evidenceTags: const {DefenseEvidenceTag.noEstablishedSafetyEvidence},
      explanationCode: DefenseExplanationCode.noEstablishedSafetyEvidence,
    );
