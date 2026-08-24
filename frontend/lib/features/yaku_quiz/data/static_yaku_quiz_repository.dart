import '../domain/yaku_quiz_question.dart';
import '../domain/yaku_quiz_repository.dart';

const staticYakuQuizQuestions = <YakuQuizQuestion>[
  YakuQuizQuestion(
    id: 'yaku.definition.riichi.v1',
    kind: YakuQuizQuestionKind.definitionRecognition,
    promptKey: YakuQuizCopyKey.promptRiichiDefinition,
    explanationKey: YakuQuizCopyKey.explanationRiichiDefinition,
    correctAnswer: YakuQuizAnswer.yakuId('riichi'),
    options: [
      YakuQuizAnswer.yakuId('riichi'),
      YakuQuizAnswer.yakuId('menzen_tsumo'),
      YakuQuizAnswer.yakuId('ippatsu'),
      YakuQuizAnswer.yakuId('double_riichi'),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.definition.tanyao.v1',
    kind: YakuQuizQuestionKind.definitionRecognition,
    promptKey: YakuQuizCopyKey.promptTanyaoDefinition,
    explanationKey: YakuQuizCopyKey.explanationTanyaoDefinition,
    correctAnswer: YakuQuizAnswer.yakuId('tanyao'),
    options: [
      YakuQuizAnswer.yakuId('tanyao'),
      YakuQuizAnswer.yakuId('honroutou'),
      YakuQuizAnswer.yakuId('chanta'),
      YakuQuizAnswer.yakuId('junchan'),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.definition.pinfu.v1',
    kind: YakuQuizQuestionKind.definitionRecognition,
    promptKey: YakuQuizCopyKey.promptPinfuDefinition,
    explanationKey: YakuQuizCopyKey.explanationPinfuDefinition,
    correctAnswer: YakuQuizAnswer.yakuId('pinfu'),
    options: [
      YakuQuizAnswer.yakuId('pinfu'),
      YakuQuizAnswer.yakuId('iipeiko'),
      YakuQuizAnswer.yakuId('chitoitsu'),
      YakuQuizAnswer.yakuId('toitoi'),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.definition.yakuhai.v1',
    kind: YakuQuizQuestionKind.definitionRecognition,
    promptKey: YakuQuizCopyKey.promptYakuhaiDefinition,
    explanationKey: YakuQuizCopyKey.explanationYakuhaiDefinition,
    correctAnswer: YakuQuizAnswer.yakuId('yakuhai'),
    options: [
      YakuQuizAnswer.yakuId('yakuhai'),
      YakuQuizAnswer.yakuId('toitoi'),
      YakuQuizAnswer.yakuId('shousangen'),
      YakuQuizAnswer.yakuId('honitsu'),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.definition.iipeiko.v1',
    kind: YakuQuizQuestionKind.definitionRecognition,
    promptKey: YakuQuizCopyKey.promptIipeikouDefinition,
    explanationKey: YakuQuizCopyKey.explanationIipeikouDefinition,
    correctAnswer: YakuQuizAnswer.yakuId('iipeiko'),
    options: [
      YakuQuizAnswer.yakuId('iipeiko'),
      YakuQuizAnswer.yakuId('ryanpeikou'),
      YakuQuizAnswer.yakuId('sanshoku'),
      YakuQuizAnswer.yakuId('ikkitsukan'),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.definition.chitoitsu.v1',
    kind: YakuQuizQuestionKind.definitionRecognition,
    promptKey: YakuQuizCopyKey.promptChitoitsuDefinition,
    explanationKey: YakuQuizCopyKey.explanationChitoitsuDefinition,
    correctAnswer: YakuQuizAnswer.yakuId('chitoitsu'),
    options: [
      YakuQuizAnswer.yakuId('chitoitsu'),
      YakuQuizAnswer.yakuId('toitoi'),
      YakuQuizAnswer.yakuId('san_ankou'),
      YakuQuizAnswer.yakuId('iipeiko'),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.definition.toitoi.v1',
    kind: YakuQuizQuestionKind.definitionRecognition,
    promptKey: YakuQuizCopyKey.promptToitoiDefinition,
    explanationKey: YakuQuizCopyKey.explanationToitoiDefinition,
    correctAnswer: YakuQuizAnswer.yakuId('toitoi'),
    options: [
      YakuQuizAnswer.yakuId('toitoi'),
      YakuQuizAnswer.yakuId('chitoitsu'),
      YakuQuizAnswer.yakuId('san_ankou'),
      YakuQuizAnswer.yakuId('honroutou'),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.definition.sanshoku.v1',
    kind: YakuQuizQuestionKind.definitionRecognition,
    promptKey: YakuQuizCopyKey.promptSanshokuDefinition,
    explanationKey: YakuQuizCopyKey.explanationSanshokuDefinition,
    correctAnswer: YakuQuizAnswer.yakuId('sanshoku'),
    options: [
      YakuQuizAnswer.yakuId('sanshoku'),
      YakuQuizAnswer.yakuId('sanshoku_doukou'),
      YakuQuizAnswer.yakuId('ikkitsukan'),
      YakuQuizAnswer.yakuId('iipeiko'),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.definition.ikkitsukan.v1',
    kind: YakuQuizQuestionKind.definitionRecognition,
    promptKey: YakuQuizCopyKey.promptIkkitsukanDefinition,
    explanationKey: YakuQuizCopyKey.explanationIkkitsukanDefinition,
    correctAnswer: YakuQuizAnswer.yakuId('ikkitsukan'),
    options: [
      YakuQuizAnswer.yakuId('ikkitsukan'),
      YakuQuizAnswer.yakuId('sanshoku'),
      YakuQuizAnswer.yakuId('junchan'),
      YakuQuizAnswer.yakuId('chinitsu'),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.definition.honitsu.v1',
    kind: YakuQuizQuestionKind.definitionRecognition,
    promptKey: YakuQuizCopyKey.promptHonitsuDefinition,
    explanationKey: YakuQuizCopyKey.explanationHonitsuDefinition,
    correctAnswer: YakuQuizAnswer.yakuId('honitsu'),
    options: [
      YakuQuizAnswer.yakuId('honitsu'),
      YakuQuizAnswer.yakuId('chinitsu'),
      YakuQuizAnswer.yakuId('chanta'),
      YakuQuizAnswer.yakuId('honroutou'),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.definition.chinitsu.v1',
    kind: YakuQuizQuestionKind.definitionRecognition,
    promptKey: YakuQuizCopyKey.promptChinitsuDefinition,
    explanationKey: YakuQuizCopyKey.explanationChinitsuDefinition,
    correctAnswer: YakuQuizAnswer.yakuId('chinitsu'),
    options: [
      YakuQuizAnswer.yakuId('chinitsu'),
      YakuQuizAnswer.yakuId('honitsu'),
      YakuQuizAnswer.yakuId('tsuuiisou'),
      YakuQuizAnswer.yakuId('junchan'),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.han.honitsu.open.v1',
    kind: YakuQuizQuestionKind.closedOpenHan,
    promptKey: YakuQuizCopyKey.promptHonitsuOpenHan,
    explanationKey: YakuQuizCopyKey.explanationHonitsuOpenHan,
    correctAnswer: YakuQuizAnswer.han(2),
    options: [
      YakuQuizAnswer.han(1),
      YakuQuizAnswer.han(2),
      YakuQuizAnswer.han(3),
      YakuQuizAnswer.han(4),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.han.chinitsu.open.v1',
    kind: YakuQuizQuestionKind.closedOpenHan,
    promptKey: YakuQuizCopyKey.promptChinitsuOpenHan,
    explanationKey: YakuQuizCopyKey.explanationChinitsuOpenHan,
    correctAnswer: YakuQuizAnswer.han(5),
    options: [
      YakuQuizAnswer.han(3),
      YakuQuizAnswer.han(4),
      YakuQuizAnswer.han(5),
      YakuQuizAnswer.han(6),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.han.sanshoku.open.v1',
    kind: YakuQuizQuestionKind.closedOpenHan,
    promptKey: YakuQuizCopyKey.promptSanshokuOpenHan,
    explanationKey: YakuQuizCopyKey.explanationSanshokuOpenHan,
    correctAnswer: YakuQuizAnswer.han(1),
    options: [
      YakuQuizAnswer.han(1),
      YakuQuizAnswer.han(2),
      YakuQuizAnswer.han(3),
      YakuQuizAnswer.han(4),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.han.junchan.closed.v1',
    kind: YakuQuizQuestionKind.closedOpenHan,
    promptKey: YakuQuizCopyKey.promptJunchanClosedHan,
    explanationKey: YakuQuizCopyKey.explanationJunchanClosedHan,
    correctAnswer: YakuQuizAnswer.han(3),
    options: [
      YakuQuizAnswer.han(1),
      YakuQuizAnswer.han(2),
      YakuQuizAnswer.han(3),
      YakuQuizAnswer.han(4),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.rule.dora_is_yaku.v1',
    kind: YakuQuizQuestionKind.ruleJudgement,
    promptKey: YakuQuizCopyKey.promptDoraIsYaku,
    explanationKey: YakuQuizCopyKey.explanationDoraIsYaku,
    correctAnswer: YakuQuizAnswer.boolean(false),
    options: [
      YakuQuizAnswer.boolean(true),
      YakuQuizAnswer.boolean(false),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.rule.pinfu_requires_closed.v1',
    kind: YakuQuizQuestionKind.ruleJudgement,
    promptKey: YakuQuizCopyKey.promptPinfuClosedOnly,
    explanationKey: YakuQuizCopyKey.explanationPinfuClosedOnly,
    correctAnswer: YakuQuizAnswer.boolean(false),
    options: [
      YakuQuizAnswer.boolean(true),
      YakuQuizAnswer.boolean(false),
    ],
  ),
  YakuQuizQuestion(
    id: 'yaku.rule.tanyao_excludes_honors.v1',
    kind: YakuQuizQuestionKind.ruleJudgement,
    promptKey: YakuQuizCopyKey.promptTanyaoAllowsHonors,
    explanationKey: YakuQuizCopyKey.explanationTanyaoAllowsHonors,
    correctAnswer: YakuQuizAnswer.boolean(false),
    options: [
      YakuQuizAnswer.boolean(true),
      YakuQuizAnswer.boolean(false),
    ],
  ),
];

class StaticYakuQuizRepository implements YakuQuizRepository {
  const StaticYakuQuizRepository();

  @override
  List<YakuQuizQuestion> get questions => staticYakuQuizQuestions;

  @override
  YakuQuizQuestion? findById(String id) {
    for (final question in staticYakuQuizQuestions) {
      if (question.id == id) return question;
    }
    return null;
  }
}
