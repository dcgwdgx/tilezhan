import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/yaku_quiz/data/static_yaku_quiz_repository.dart';
import 'package:tilezhan/features/yaku_quiz/domain/yaku_quiz_provider.dart';
import 'package:tilezhan/features/yaku_quiz/domain/yaku_quiz_question.dart';
import 'package:tilezhan/features/yaku_quiz/domain/yaku_quiz_repository.dart';
import 'package:tilezhan/features/yaku_quiz/domain/yaku_quiz_state.dart';

class _FakeRepository implements YakuQuizRepository {
  @override
  final List<YakuQuizQuestion> questions;

  _FakeRepository(this.questions);

  @override
  YakuQuizQuestion? findById(String id) {
    for (final question in questions) {
      if (question.id == id) return question;
    }
    return null;
  }
}

class _ZeroRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}

Map<YakuQuizQuestionKind, int> _kindCounts(
  Iterable<YakuQuizQuestion> questions,
) {
  return {
    for (final kind in YakuQuizQuestionKind.values)
      kind: questions.where((question) => question.kind == kind).length,
  };
}

void main() {
  group('YakuQuizNotifier', () {
    test('default quiz is stratified as 6 definitions, 2 han, 2 rules', () {
      const repository = StaticYakuQuizRepository();
      final notifier = YakuQuizNotifier(repository);
      addTearDown(notifier.dispose);

      notifier.start(seed: 20260824);

      expect(notifier.state.totalCount, 10);
      expect(_kindCounts(notifier.state.questions), {
        YakuQuizQuestionKind.definitionRecognition: 6,
        YakuQuizQuestionKind.closedOpenHan: 2,
        YakuQuizQuestionKind.ruleJudgement: 2,
      });
    });

    test('same fixed seed produces the same question order', () {
      const repository = StaticYakuQuizRepository();
      final first = YakuQuizNotifier(repository);
      final second = YakuQuizNotifier(repository);
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      first.start(questionCount: 8, seed: 20260824);
      second.start(questionCount: 8, seed: 20260824);

      expect(first.state.totalCount, 8);
      expect(
        first.state.questions.map((q) => q.id),
        orderedEquals(second.state.questions.map((q) => q.id)),
      );
      for (var index = 0; index < first.state.questions.length; index++) {
        expect(
          first.state.questions[index].options,
          orderedEquals(second.state.questions[index].options),
        );
      }
    });

    test('known seed shuffles options without losing correct answers', () {
      const repository = StaticYakuQuizRepository();
      final notifier = YakuQuizNotifier(repository);
      addTearDown(notifier.dispose);

      notifier.start(questionCount: 18, seed: 20260824);

      expect(
        notifier.state.questions.every(
          (question) => question.options.contains(question.correctAnswer),
        ),
        isTrue,
      );
      expect(
        notifier.state.questions.any(
          (question) => question.options.first != question.correctAnswer,
        ),
        isTrue,
      );
    });

    test('reviewQuestionId starts an exact one-question session', () {
      const repository = StaticYakuQuizRepository();
      final notifier = YakuQuizNotifier(
        repository,
        randomFactory: (_) => _ZeroRandom(),
      );
      addTearDown(notifier.dispose);
      const targetId = 'yaku.rule.dora_is_yaku.v1';

      notifier.start(
        questionCount: 18,
        seed: 99,
        reviewQuestionId: targetId,
      );

      expect(notifier.state.phase, YakuQuizPhase.answering);
      expect(notifier.state.totalCount, 1);
      expect(notifier.state.currentQuestion?.id, targetId);
      expect(
        notifier.state.currentQuestion?.options,
        isNot(orderedEquals(repository.findById(targetId)!.options)),
      );
    });

    test('submit records statistics and is idempotent while revealed', () {
      const repository = StaticYakuQuizRepository();
      final notifier = YakuQuizNotifier(repository);
      addTearDown(notifier.dispose);
      notifier.start(questionCount: 2, seed: 7);
      final question = notifier.state.currentQuestion!;

      final first = notifier.submit(question.correctAnswer);
      final snapshot = notifier.state;
      final duplicate = notifier.submit(question.options.last);

      expect(first.wasRecorded, isTrue);
      expect(first.isCorrect, isTrue);
      expect(snapshot.phase, YakuQuizPhase.revealed);
      expect(snapshot.answeredCount, 1);
      expect(snapshot.correctCount, 1);
      expect(duplicate.wasRecorded, isFalse);
      expect(duplicate.isCorrect, isTrue);
      expect(identical(notifier.state, snapshot), isTrue);
    });

    test('next ignores double taps and only advances from revealed', () {
      const repository = StaticYakuQuizRepository();
      final notifier = YakuQuizNotifier(repository);
      addTearDown(notifier.dispose);
      notifier.start(questionCount: 2, seed: 3);

      expect(notifier.next(), isFalse);
      notifier.submit(notifier.state.currentQuestion!.correctAnswer);
      expect(notifier.next(), isTrue);
      expect(notifier.state.currentIndex, 1);
      expect(notifier.state.phase, YakuQuizPhase.answering);

      expect(notifier.next(), isFalse);
      expect(notifier.state.currentIndex, 1);
      expect(notifier.state.answeredCount, 1);
    });

    test('last next enters completed with final statistics', () {
      const repository = StaticYakuQuizRepository();
      final notifier = YakuQuizNotifier(repository);
      addTearDown(notifier.dispose);
      notifier.start(
        reviewQuestionId: 'yaku.rule.pinfu_requires_closed.v1',
      );
      final question = notifier.state.currentQuestion!;
      final wrong = question.options.firstWhere(
        (answer) => answer != question.correctAnswer,
      );

      notifier.submit(wrong);
      expect(notifier.next(), isTrue);

      expect(notifier.state.phase, YakuQuizPhase.completed);
      expect(notifier.state.currentQuestion, isNull);
      expect(notifier.state.answeredCount, 1);
      expect(notifier.state.correctCount, 0);
      expect(notifier.state.wrongCount, 1);
      expect(notifier.state.accuracy, 0);
      expect(notifier.next(), isFalse);
    });

    test('questionCount larger than catalog safely uses the full catalog', () {
      const repository = StaticYakuQuizRepository();
      final notifier = YakuQuizNotifier(repository);
      addTearDown(notifier.dispose);

      notifier.start(questionCount: 100, seed: 1);

      expect(notifier.state.totalCount, staticYakuQuizQuestions.length);
      expect(
        notifier.state.questions.map((question) => question.id).toSet(),
        hasLength(staticYakuQuizQuestions.length),
      );
      expect(_kindCounts(notifier.state.questions), {
        YakuQuizQuestionKind.definitionRecognition: 11,
        YakuQuizQuestionKind.closedOpenHan: 4,
        YakuQuizQuestionKind.ruleJudgement: 3,
      });
    });

    test('small quizzes use proportional categories without duplicates', () {
      const repository = StaticYakuQuizRepository();
      final oneQuestion = YakuQuizNotifier(repository);
      final twoQuestions = YakuQuizNotifier(repository);
      final threeQuestions = YakuQuizNotifier(repository);
      addTearDown(oneQuestion.dispose);
      addTearDown(twoQuestions.dispose);
      addTearDown(threeQuestions.dispose);

      oneQuestion.start(questionCount: 1, seed: 1);
      twoQuestions.start(questionCount: 2, seed: 1);
      threeQuestions.start(questionCount: 3, seed: 1);

      expect(_kindCounts(oneQuestion.state.questions), {
        YakuQuizQuestionKind.definitionRecognition: 1,
        YakuQuizQuestionKind.closedOpenHan: 0,
        YakuQuizQuestionKind.ruleJudgement: 0,
      });
      expect(_kindCounts(twoQuestions.state.questions), {
        YakuQuizQuestionKind.definitionRecognition: 1,
        YakuQuizQuestionKind.closedOpenHan: 1,
        YakuQuizQuestionKind.ruleJudgement: 0,
      });
      expect(_kindCounts(threeQuestions.state.questions), {
        YakuQuizQuestionKind.definitionRecognition: 1,
        YakuQuizQuestionKind.closedOpenHan: 1,
        YakuQuizQuestionKind.ruleJudgement: 1,
      });
      for (final notifier in [oneQuestion, twoQuestions, threeQuestions]) {
        expect(
          notifier.state.questions.map((question) => question.id).toSet(),
          hasLength(notifier.state.totalCount),
        );
      }
    });
  });

  test('provider stratifies an injected repository and uses Random factory',
      () {
    final questions = [
      ...staticYakuQuizQuestions
          .where(
            (question) =>
                question.kind == YakuQuizQuestionKind.definitionRecognition,
          )
          .take(4),
      ...staticYakuQuizQuestions
          .where(
            (question) => question.kind == YakuQuizQuestionKind.closedOpenHan,
          )
          .take(2),
      ...staticYakuQuizQuestions
          .where(
            (question) => question.kind == YakuQuizQuestionKind.ruleJudgement,
          )
          .take(1),
    ];
    var receivedSeed = -1;
    final container = ProviderContainer(overrides: [
      yakuQuizRepositoryProvider.overrideWithValue(_FakeRepository(questions)),
      yakuQuizRandomFactoryProvider.overrideWithValue((seed) {
        receivedSeed = seed;
        return Random(seed);
      }),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(yakuQuizProvider, (_, __) {});
    addTearDown(subscription.close);

    container.read(yakuQuizProvider.notifier).start(questionCount: 4, seed: 42);

    final state = container.read(yakuQuizProvider);
    expect(receivedSeed, 42);
    expect(state.totalCount, 4);
    expect(_kindCounts(state.questions), {
      YakuQuizQuestionKind.definitionRecognition: 2,
      YakuQuizQuestionKind.closedOpenHan: 1,
      YakuQuizQuestionKind.ruleJudgement: 1,
    });
    expect(
      state.questions.every(
        (question) => questions.any((source) => source.id == question.id),
      ),
      isTrue,
    );
  });
}
