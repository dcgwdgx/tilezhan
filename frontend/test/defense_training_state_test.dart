import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/defense_trainer/domain/defense_training_state.dart';
import 'package:tilezhan/features/defense_trainer/domain/defense_trainer.dart';

void main() {
  group('DefenseTrainingState.standard', () {
    test('samples exactly two questions from each topic', () {
      final state = DefenseTrainingState.standard(seed: 42);

      expect(state.phase, DefenseTrainingPhase.intro);
      expect(state.questions, hasLength(10));
      for (final topic in DefenseTopic.values) {
        expect(
          state.questions.where((question) => question.topic == topic),
          hasLength(2),
        );
      }
    });

    test('reproduces question and option order from the same seed', () {
      final first = DefenseTrainingState.standard(seed: 1977);
      final second = DefenseTrainingState.standard(seed: 1977);

      expect(
        first.questions.map((question) => question.id),
        second.questions.map((question) => question.id),
      );
      for (var index = 0; index < first.questions.length; index++) {
        expect(
          first.questions[index].choices.map((choice) => choice.id),
          second.questions[index].choices.map((choice) => choice.id),
        );
      }
      expect(() => first.questions.clear(), throwsUnsupportedError);
    });

    test('requires enough questions for every topic', () {
      expect(
        () => DefenseTrainingState.standard(
          seed: 1,
          catalog: const <DefenseQuestion>[],
        ),
        throwsStateError,
      );
    });

    test('can cap a plan session to the remaining question count', () {
      final state = DefenseTrainingState.standard(
        seed: 42,
        questionLimit: 3,
      );

      expect(state.questions, hasLength(3));
      expect(
        () => DefenseTrainingState.standard(seed: 42, questionLimit: 0),
        throwsArgumentError,
      );
      expect(
        () => DefenseTrainingState.standard(seed: 42, questionLimit: 11),
        throwsArgumentError,
      );
    });
  });

  group('DefenseTrainingState transitions', () {
    test('uses one phase and records a submission only once', () {
      var state = DefenseTrainingState.standard(seed: 7);
      state = state.begin();
      expect(state.phase, DefenseTrainingPhase.answering);

      final question = state.currentQuestion!;
      state = state.submit(question.bestChoiceId);
      expect(state.phase, DefenseTrainingPhase.revealed);
      expect(state.answeredCount, 1);
      expect(state.correctCount, 1);

      final duplicate = state.submit(question.choices.last.id);
      expect(identical(duplicate, state), isTrue);
      expect(duplicate.answeredCount, 1);
    });

    test('completes ten questions and summarizes each topic', () {
      var state = DefenseTrainingState.standard(seed: 91).begin();
      for (var index = 0; index < 10; index++) {
        final question = state.currentQuestion!;
        final choice = index.isEven
            ? question.bestChoiceId
            : question.choices
                .firstWhere((choice) => choice.id != question.bestChoiceId)
                .id;
        state = state.submit(choice);
        expect(state.phase, DefenseTrainingPhase.revealed);
        state = state.next();
      }

      expect(state.phase, DefenseTrainingPhase.completed);
      expect(state.currentQuestion, isNull);
      expect(state.answeredCount, 10);
      expect(state.correctCount, 5);
      expect(state.topicSummaries.keys.toSet(), DefenseTopic.values.toSet());
      expect(
        state.topicSummaries.values
            .map((summary) => summary.attempts)
            .reduce((left, right) => left + right),
        10,
      );
      expect(() => state.answers.clear(), throwsUnsupportedError);
      expect(() => state.topicSummaries.clear(), throwsUnsupportedError);
    });
  });

  group('DefenseTrainingState.focused', () {
    test('builds a reproducible two-question session for one topic', () {
      final first = DefenseTrainingState.focused(
        topic: DefenseTopic.suji,
        seed: 88,
      );
      final second = DefenseTrainingState.focused(
        topic: DefenseTopic.suji,
        seed: 88,
      );

      expect(first.phase, DefenseTrainingPhase.intro);
      expect(first.questions, hasLength(2));
      expect(
        first.questions
            .every((question) => question.topic == DefenseTopic.suji),
        isTrue,
      );
      expect(
        first.questions.map((question) => question.id),
        second.questions.map((question) => question.id),
      );
    });

    test('requires two catalog questions for the requested topic', () {
      expect(
        () => DefenseTrainingState.focused(
          topic: DefenseTopic.kabe,
          seed: 1,
          catalog: const <DefenseQuestion>[],
        ),
        throwsStateError,
      );
    });

    test('can resume a partly completed weak-skill task with one question', () {
      final state = DefenseTrainingState.focused(
        topic: DefenseTopic.kabe,
        seed: 1,
        questionLimit: 1,
      );

      expect(state.questions, hasLength(1));
      expect(state.questions.single.topic, DefenseTopic.kabe);
      expect(
        () => DefenseTrainingState.focused(
          topic: DefenseTopic.kabe,
          seed: 1,
          questionLimit: 3,
        ),
        throwsArgumentError,
      );
    });
  });

  group('DefenseTrainingState.review', () {
    test('opens the requested question directly and contains exactly one', () {
      final state = DefenseTrainingState.review(
        reviewQuestionId: 'defense.kabe.002.v1',
        seed: 5,
      );

      expect(state.isReview, isTrue);
      expect(state.phase, DefenseTrainingPhase.answering);
      expect(state.questions, hasLength(1));
      expect(state.currentQuestion!.id, 'defense.kabe.002.v1');
    });

    test('rejects an unknown precision-review ID', () {
      expect(
        () => DefenseTrainingState.review(
          reviewQuestionId: 'defense.missing',
          seed: 5,
        ),
        throwsArgumentError,
      );
    });
  });
}
