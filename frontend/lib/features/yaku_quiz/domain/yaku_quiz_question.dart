/// The supported question families in the yaku dojo.
enum YakuQuizQuestionKind {
  definitionRecognition,
  closedOpenHan,
  ruleJudgement,
}

/// Stable localization keys for question prompts and explanations.
///
/// UI code can map these enum values to ARB entries later. Domain/data files
/// deliberately contain no user-facing sentences.
enum YakuQuizCopyKey {
  promptRiichiDefinition,
  explanationRiichiDefinition,
  promptTanyaoDefinition,
  explanationTanyaoDefinition,
  promptPinfuDefinition,
  explanationPinfuDefinition,
  promptYakuhaiDefinition,
  explanationYakuhaiDefinition,
  promptIipeikouDefinition,
  explanationIipeikouDefinition,
  promptChitoitsuDefinition,
  explanationChitoitsuDefinition,
  promptToitoiDefinition,
  explanationToitoiDefinition,
  promptSanshokuDefinition,
  explanationSanshokuDefinition,
  promptIkkitsukanDefinition,
  explanationIkkitsukanDefinition,
  promptHonitsuDefinition,
  explanationHonitsuDefinition,
  promptChinitsuDefinition,
  explanationChinitsuDefinition,
  promptHonitsuOpenHan,
  explanationHonitsuOpenHan,
  promptChinitsuOpenHan,
  explanationChinitsuOpenHan,
  promptSanshokuOpenHan,
  explanationSanshokuOpenHan,
  promptJunchanClosedHan,
  explanationJunchanClosedHan,
  promptDoraIsYaku,
  explanationDoraIsYaku,
  promptPinfuClosedOnly,
  explanationPinfuClosedOnly,
  promptTanyaoAllowsHonors,
  explanationTanyaoAllowsHonors,
}

enum YakuQuizAnswerKind { yakuId, han, boolean }

/// A typed answer. Exactly one value is populated according to [kind].
class YakuQuizAnswer {
  final YakuQuizAnswerKind kind;
  final String? yakuId;
  final int? han;
  final bool? booleanValue;

  const YakuQuizAnswer.yakuId(String value)
      : kind = YakuQuizAnswerKind.yakuId,
        yakuId = value,
        han = null,
        booleanValue = null;

  const YakuQuizAnswer.han(int value)
      : kind = YakuQuizAnswerKind.han,
        yakuId = null,
        han = value,
        booleanValue = null;

  const YakuQuizAnswer.boolean(bool value)
      : kind = YakuQuizAnswerKind.boolean,
        yakuId = null,
        han = null,
        booleanValue = value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YakuQuizAnswer &&
          kind == other.kind &&
          yakuId == other.yakuId &&
          han == other.han &&
          booleanValue == other.booleanValue;

  @override
  int get hashCode => Object.hash(kind, yakuId, han, booleanValue);
}

class YakuQuizQuestion {
  final String id;
  final YakuQuizQuestionKind kind;
  final YakuQuizCopyKey promptKey;
  final YakuQuizCopyKey explanationKey;
  final YakuQuizAnswer correctAnswer;
  final List<YakuQuizAnswer> options;

  const YakuQuizQuestion({
    required this.id,
    required this.kind,
    required this.promptKey,
    required this.explanationKey,
    required this.correctAnswer,
    required this.options,
  });
}

enum YakuQuizValidationIssueKind {
  emptyId,
  duplicateId,
  tooFewOptions,
  duplicateOption,
  missingCorrectAnswer,
  answerKindMismatch,
}

class YakuQuizValidationIssue {
  final YakuQuizValidationIssueKind kind;
  final String questionId;

  const YakuQuizValidationIssue(this.kind, this.questionId);
}

/// Validates structural catalog invariants without relying on debug asserts.
List<YakuQuizValidationIssue> validateYakuQuizCatalog(
  Iterable<YakuQuizQuestion> questions,
) {
  final issues = <YakuQuizValidationIssue>[];
  final ids = <String>{};

  for (final question in questions) {
    final expectedAnswerKind = switch (question.kind) {
      YakuQuizQuestionKind.definitionRecognition => YakuQuizAnswerKind.yakuId,
      YakuQuizQuestionKind.closedOpenHan => YakuQuizAnswerKind.han,
      YakuQuizQuestionKind.ruleJudgement => YakuQuizAnswerKind.boolean,
    };

    if (question.id.isEmpty) {
      issues.add(const YakuQuizValidationIssue(
        YakuQuizValidationIssueKind.emptyId,
        '',
      ));
    } else if (!ids.add(question.id)) {
      issues.add(YakuQuizValidationIssue(
        YakuQuizValidationIssueKind.duplicateId,
        question.id,
      ));
    }

    if (question.options.length < 2) {
      issues.add(YakuQuizValidationIssue(
        YakuQuizValidationIssueKind.tooFewOptions,
        question.id,
      ));
    }

    if (question.correctAnswer.kind != expectedAnswerKind) {
      issues.add(YakuQuizValidationIssue(
        YakuQuizValidationIssueKind.answerKindMismatch,
        question.id,
      ));
    }

    final optionSet = <YakuQuizAnswer>{};
    for (final option in question.options) {
      if (!optionSet.add(option)) {
        issues.add(YakuQuizValidationIssue(
          YakuQuizValidationIssueKind.duplicateOption,
          question.id,
        ));
      }
      if (option.kind != question.correctAnswer.kind) {
        issues.add(YakuQuizValidationIssue(
          YakuQuizValidationIssueKind.answerKindMismatch,
          question.id,
        ));
      }
    }

    if (!optionSet.contains(question.correctAnswer)) {
      issues.add(YakuQuizValidationIssue(
        YakuQuizValidationIssueKind.missingCorrectAnswer,
        question.id,
      ));
    }
  }

  return issues;
}
