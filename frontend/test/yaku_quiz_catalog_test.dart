import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/yaku_quiz/data/static_yaku_quiz_repository.dart';
import 'package:tilezhan/features/yaku_quiz/domain/yaku_quiz_question.dart';

void main() {
  group('static yaku quiz catalog', () {
    test('contains the required 18 questions by category', () {
      expect(staticYakuQuizQuestions, hasLength(18));
      expect(
        staticYakuQuizQuestions
            .where((q) => q.kind == YakuQuizQuestionKind.definitionRecognition)
            .length,
        11,
      );
      expect(
        staticYakuQuizQuestions
            .where((q) => q.kind == YakuQuizQuestionKind.closedOpenHan)
            .length,
        4,
      );
      expect(
        staticYakuQuizQuestions
            .where((q) => q.kind == YakuQuizQuestionKind.ruleJudgement)
            .length,
        3,
      );
    });

    test('uses the stable IDs expected by the copy catalog', () {
      expect(
        staticYakuQuizQuestions.map((q) => q.id).toSet(),
        {
          'yaku.definition.riichi.v1',
          'yaku.definition.tanyao.v1',
          'yaku.definition.pinfu.v1',
          'yaku.definition.yakuhai.v1',
          'yaku.definition.iipeiko.v1',
          'yaku.definition.chitoitsu.v1',
          'yaku.definition.toitoi.v1',
          'yaku.definition.sanshoku.v1',
          'yaku.definition.ikkitsukan.v1',
          'yaku.definition.honitsu.v1',
          'yaku.definition.chinitsu.v1',
          'yaku.han.honitsu.open.v1',
          'yaku.han.chinitsu.open.v1',
          'yaku.han.sanshoku.open.v1',
          'yaku.han.junchan.closed.v1',
          'yaku.rule.dora_is_yaku.v1',
          'yaku.rule.pinfu_requires_closed.v1',
          'yaku.rule.tanyao_excludes_honors.v1',
        },
      );
    });

    test('passes structural validation', () {
      expect(validateYakuQuizCatalog(staticYakuQuizQuestions), isEmpty);

      for (final question in staticYakuQuizQuestions) {
        expect(question.options.toSet(), hasLength(question.options.length));
        expect(question.options, contains(question.correctAnswer));
      }
    });

    test('uses structured answer types for every category', () {
      for (final question in staticYakuQuizQuestions) {
        final expectedKind = switch (question.kind) {
          YakuQuizQuestionKind.definitionRecognition =>
            YakuQuizAnswerKind.yakuId,
          YakuQuizQuestionKind.closedOpenHan => YakuQuizAnswerKind.han,
          YakuQuizQuestionKind.ruleJudgement => YakuQuizAnswerKind.boolean,
        };
        expect(question.correctAnswer.kind, expectedKind);
        expect(
          question.options.every((answer) => answer.kind == expectedKind),
          isTrue,
        );
      }
    });

    test('han and rule answers match the required riichi rules', () {
      final byId = {
        for (final question in staticYakuQuizQuestions)
          question.id: question.correctAnswer,
      };

      expect(byId['yaku.han.honitsu.open.v1']?.han, 2);
      expect(byId['yaku.han.chinitsu.open.v1']?.han, 5);
      expect(byId['yaku.han.sanshoku.open.v1']?.han, 1);
      expect(byId['yaku.han.junchan.closed.v1']?.han, 3);
      expect(byId['yaku.rule.dora_is_yaku.v1']?.booleanValue, isFalse);
      expect(
        byId['yaku.rule.pinfu_requires_closed.v1']?.booleanValue,
        isFalse,
      );
      expect(
        byId['yaku.rule.tanyao_excludes_honors.v1']?.booleanValue,
        isFalse,
      );
    });
  });
}
