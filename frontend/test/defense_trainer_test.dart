import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/defense_trainer/domain/defense_catalog.dart';
import 'package:tilezhan/features/defense_trainer/domain/defense_trainer.dart';

void main() {
  group('fixed defense catalog', () {
    test('keeps every published version available for exact SRS review', () {
      expect(DefenseQuestionCatalog.publishedQuestionIds, hasLength(14));
      expect(
        DefenseQuestionCatalog.byId.keys,
        containsAll(DefenseQuestionCatalog.publishedQuestionIds),
      );
    });

    test('contains fourteen valid four-choice questions across every topic',
        () {
      final questions = DefenseQuestionCatalog.questions;

      expect(DefenseQuestionCatalog.taxonomyVersion, 1);
      expect(questions, hasLength(14));
      expect(questions.map((question) => question.id).toSet(), hasLength(14));
      expect(
        questions.map((question) => question.id),
        everyElement(endsWith('.v1')),
      );
      expect(
        questions.map((question) => question.topic).toSet(),
        DefenseTopic.values.toSet(),
      );
      expect(
        questions,
        everyElement(
          isA<DefenseQuestion>()
              .having((question) => question.choices, 'choices', hasLength(4)),
        ),
      );
      for (final question in questions) {
        expect(
            question.choices.map((choice) => choice.id).toSet(), hasLength(4));
        expect(
          question.choices.map((choice) => choice.tileId).toSet(),
          hasLength(4),
        );
        expect(
          question.choices.where(
            (choice) => choice.id == question.bestChoiceId,
          ),
          hasLength(1),
        );
        expect(
          question.choices.where(
            (choice) =>
                choice.riskLabel.priority <=
                question.bestChoice.riskLabel.priority,
          ),
          hasLength(1),
        );
        expect(
          question.choices,
          everyElement(
            isA<DefenseChoice>().having(
              (choice) => choice.evidenceTags,
              'evidenceTags',
              isNotEmpty,
            ),
          ),
        );
      }

      expect(DefenseQuestionCatalog.validation.isValid, isTrue);
      expect(DefenseQuestionCatalog.validation.issues, isEmpty);
    });

    test('exposes immutable question, river, option, and lookup snapshots', () {
      final question = DefenseQuestionCatalog.questions.first;

      expect(
        () => DefenseQuestionCatalog.questions.add(question),
        throwsUnsupportedError,
      );
      expect(
        () => DefenseQuestionCatalog.byId.remove(question.id),
        throwsUnsupportedError,
      );
      expect(() => question.choices.clear(), throwsUnsupportedError);
      expect(
        () => question.discardsBySeat[question.targetSeat]!.add('z7'),
        throwsUnsupportedError,
      );
      expect(
        () => question.additionalPublicVisibleCounts['z7'] = 1,
        throwsUnsupportedError,
      );
      expect(
        () => question.choices.first.evidenceTags.clear(),
        throwsUnsupportedError,
      );
    });
  });

  group('rule boundaries', () {
    test('absolute labels are target-specific genbutsu only', () {
      final absoluteChoices = <(DefenseQuestion, DefenseChoice)>[];
      for (final question in DefenseQuestionCatalog.questions) {
        for (final choice in question.choices) {
          if (choice.riskLabel == DefenseRiskLabel.absoluteAgainstTarget) {
            absoluteChoices.add((question, choice));
          }
        }
      }

      expect(absoluteChoices, isNotEmpty);
      for (final (question, choice) in absoluteChoices) {
        expect(question.targetDiscards, contains(choice.tileId));
        expect(
          choice.evidenceTags,
          contains(DefenseEvidenceTag.genbutsuAgainstTarget),
        );
      }

      final scopedQuestion =
          DefenseQuestionCatalog.byId['defense.genbutsu.002.v1']!;
      final otherOpponentDiscard = scopedQuestion.choices.singleWhere(
        (choice) => choice.tileId == 'z3',
      );
      expect(
        scopedQuestion.discardsBySeat[DefenseSeat.east],
        contains('z3'),
      );
      expect(scopedQuestion.targetSeat, DefenseSeat.south);
      expect(
        otherOpponentDiscard.riskLabel,
        DefenseRiskLabel.noEstablishedReduction,
      );
      expect(
        otherOpponentDiscard.explanationCode,
        DefenseExplanationCode.otherOpponentDiscardIsNotTargetGenbutsu,
      );
    });

    test('suji and kabe are always explicitly non-absolute', () {
      const relativeTags = {
        DefenseEvidenceTag.sujiAgainstTarget,
        DefenseEvidenceTag.completeKabe,
        DefenseEvidenceTag.incompleteKabe,
      };

      final relativeChoices = DefenseQuestionCatalog.questions
          .expand((question) => question.choices)
          .where((choice) => choice.evidenceTags.any(relativeTags.contains));
      expect(relativeChoices, isNotEmpty);
      for (final choice in relativeChoices) {
        expect(
          choice.riskLabel,
          isNot(DefenseRiskLabel.absoluteAgainstTarget),
        );
      }

      final incompleteWall = DefenseQuestionCatalog
          .byId['defense.kabe.001.v1']!.choices
          .singleWhere(
        (choice) => choice.tileId == 'm9',
      );
      expect(
        incompleteWall.evidenceTags,
        contains(DefenseEvidenceTag.incompleteKabe),
      );
      expect(
        incompleteWall.explanationCode,
        DefenseExplanationCode.incompleteKabeLeavesSequencePossible,
      );
    });

    test('three visible honors preserve the kokushi exception', () {
      final question = DefenseQuestionCatalog.byId['defense.honor.001.v1']!;
      final choice = question.bestChoice;

      expect(question.publicVisibleCount(choice.tileId), 3);
      expect(
        choice.riskLabel,
        DefenseRiskLabel.stronglyReducedNotAbsolute,
      );
      expect(
        choice.evidenceTags,
        containsAll({
          DefenseEvidenceTag.threePublicHonorCopies,
          DefenseEvidenceTag.kokushiExceptionRemains,
        }),
      );
      expect(
        choice.explanationCode,
        DefenseExplanationCode.threeVisibleHonorHasKokushiException,
      );
    });

    test('combined clues outrank one clue without claiming safety', () {
      final question = DefenseQuestionCatalog.byId['defense.combined.001.v1']!;
      final combined = question.bestChoice;
      final sujiOnly = question.choices.singleWhere(
        (choice) => choice.tileId == 'p7',
      );

      expect(
        combined.evidenceTags,
        containsAll({
          DefenseEvidenceTag.sujiAgainstTarget,
          DefenseEvidenceTag.completeKabe,
          DefenseEvidenceTag.combinedIndependentClues,
        }),
      );
      expect(
        combined.riskLabel,
        DefenseRiskLabel.stronglyReducedNotAbsolute,
      );
      expect(
        sujiOnly.riskLabel,
        DefenseRiskLabel.relativelyReducedNotAbsolute,
      );
      expect(
          combined.riskLabel.priority, lessThan(sujiOnly.riskLabel.priority));
    });
  });

  group('answer evaluation', () {
    test('returns structured feedback for correct and incorrect selections',
        () {
      final question = DefenseQuestionCatalog.byId['defense.genbutsu.002.v1']!;

      final correct = DefenseTrainerEvaluator.evaluate(
        question: question,
        selectedChoiceId: question.bestChoiceId,
      );
      expect(correct.isCorrect, isTrue);
      expect(correct.selectedChoice, same(correct.bestChoice));
      expect(
        correct.bestChoice.riskLabel,
        DefenseRiskLabel.absoluteAgainstTarget,
      );

      final incorrect = DefenseTrainerEvaluator.evaluate(
        question: question,
        selectedChoiceId: 'a',
      );
      expect(incorrect.isCorrect, isFalse);
      expect(incorrect.selectedChoice.tileId, 'z3');
      expect(incorrect.bestChoice.tileId, 'p6');
      expect(
        incorrect.selectedChoice.explanationCode,
        DefenseExplanationCode.otherOpponentDiscardIsNotTargetGenbutsu,
      );
    });

    test('rejects a choice that is not part of the question', () {
      expect(
        () => DefenseTrainerEvaluator.evaluate(
          question: DefenseQuestionCatalog.questions.first,
          selectedChoiceId: 'missing',
        ),
        throwsArgumentError,
      );
    });
  });

  group('catalog integrity validator', () {
    test('reports malformed shape, invalid IDs, and dishonest absolute labels',
        () {
      final dishonest = DefenseQuestion(
        id: 'broken',
        topic: DefenseTopic.suji,
        targetSeat: DefenseSeat.east,
        discardsBySeat: const {
          DefenseSeat.east: ['m4'],
        },
        choices: [
          DefenseChoice(
            id: 'a',
            tileId: 'x1',
            riskLabel: DefenseRiskLabel.absoluteAgainstTarget,
            evidenceTags: const {DefenseEvidenceTag.sujiAgainstTarget},
            explanationCode: DefenseExplanationCode.sujiCoversOnlyRyanmen,
          ),
          _testUnknown('b', 'p1'),
          _testUnknown('c', 's1'),
        ],
        bestChoiceId: 'missing',
      );

      final result = DefenseCatalogValidator.validate([dishonest]);
      final codes = result.issues.map((issue) => issue.code).toSet();

      expect(result.isValid, isFalse);
      expect(
        codes,
        containsAll({
          DefenseCatalogIssueCode.catalogTooSmall,
          DefenseCatalogIssueCode.missingTopic,
          DefenseCatalogIssueCode.wrongChoiceCount,
          DefenseCatalogIssueCode.missingBestChoice,
          DefenseCatalogIssueCode.invalidTileId,
          DefenseCatalogIssueCode.absoluteWithoutTargetGenbutsu,
          DefenseCatalogIssueCode.relativeEvidenceMarkedAbsolute,
        }),
      );
    });

    test('detects false evidence tags and a physically impossible fifth copy',
        () {
      final broken = DefenseQuestion(
        id: 'broken-evidence',
        topic: DefenseTopic.combinedEvidence,
        targetSeat: DefenseSeat.east,
        discardsBySeat: const {
          DefenseSeat.east: ['m1', 'm1', 'm1', 'm1'],
        },
        additionalPublicVisibleCounts: const {'z1': 1},
        choices: [
          DefenseChoice(
            id: 'a',
            tileId: 'm1',
            riskLabel: DefenseRiskLabel.absoluteAgainstTarget,
            evidenceTags: const {DefenseEvidenceTag.genbutsuAgainstTarget},
            explanationCode: DefenseExplanationCode.targetOwnDiscardIsGenbutsu,
          ),
          DefenseChoice(
            id: 'b',
            tileId: 'p2',
            riskLabel: DefenseRiskLabel.stronglyReducedNotAbsolute,
            evidenceTags: const {
              DefenseEvidenceTag.sujiAgainstTarget,
              DefenseEvidenceTag.completeKabe,
              DefenseEvidenceTag.combinedIndependentClues,
            },
            explanationCode:
                DefenseExplanationCode.combinedSujiAndKabeStillNotAbsolute,
          ),
          DefenseChoice(
            id: 'c',
            tileId: 'z1',
            riskLabel: DefenseRiskLabel.relativelyReducedNotAbsolute,
            evidenceTags: const {
              DefenseEvidenceTag.threePublicHonorCopies,
            },
            explanationCode:
                DefenseExplanationCode.threeVisibleHonorHasKokushiException,
          ),
          _testUnknown('d', 's5'),
        ],
        bestChoiceId: 'a',
      );

      final result = DefenseCatalogValidator.validate([broken]);
      final codes = result.issues.map((issue) => issue.code).toSet();

      expect(
        codes,
        containsAll({
          DefenseCatalogIssueCode.choiceExceedsPhysicalCopies,
          DefenseCatalogIssueCode.falseSujiTag,
          DefenseCatalogIssueCode.falseCompleteKabeTag,
          DefenseCatalogIssueCode.falseHonorVisibilityTag,
        }),
      );
    });

    test('detects an untagged suji choice labelled as unknown', () {
      final broken = DefenseQuestion(
        id: 'defense.suji.missing-tag.001.v1',
        topic: DefenseTopic.suji,
        targetSeat: DefenseSeat.west,
        discardsBySeat: const {
          DefenseSeat.west: ['s2'],
        },
        choices: [
          _testUnknown('a', 's5'),
          _testUnknown('b', 'm1'),
          _testUnknown('c', 'p1'),
          _testUnknown('d', 'z1'),
        ],
        bestChoiceId: 'a',
      );

      final result = DefenseCatalogValidator.validate([broken]);
      final missingSujiIssues = result.issues.where(
        (issue) => issue.code == DefenseCatalogIssueCode.untaggedSujiEvidence,
      );

      expect(missingSujiIssues, hasLength(1));
      expect(missingSujiIssues.single.questionId, broken.id);
      expect(missingSujiIssues.single.choiceId, 'a');
    });
  });
}

DefenseChoice _testUnknown(String id, String tileId) => DefenseChoice(
      id: id,
      tileId: tileId,
      riskLabel: DefenseRiskLabel.noEstablishedReduction,
      evidenceTags: const {DefenseEvidenceTag.noEstablishedSafetyEvidence},
      explanationCode: DefenseExplanationCode.noEstablishedSafetyEvidence,
    );
